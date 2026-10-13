import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ai/ai_provider.dart';
import '../../data/transfer/transfer_bundle.dart';
import '../advanced_sources/hidden_words_controller.dart';
import '../advanced_sources/xtream_controller.dart';
import '../ai/ai_controller.dart';
import '../library/library_cache_provider.dart';
import '../local_network/smb_controller.dart';
import '../metadata/tmdb_controller.dart';
import '../player/playback_prefs.dart';
import '../settings/settings_controller.dart';

/// What [TransferService.collect] found, and anything it left out on purpose.
class CollectedSettings {
  const CollectedSettings(this.bundle, this.notes);

  final TransferBundle bundle;

  /// Things this device has that will not be sent, and why. Shown on the Send
  /// screen, so a missing row is explained rather than mysterious.
  final List<String> notes;
}

/// What [TransferService.apply] did.
class ApplyResult {
  const ApplyResult(this.notes);

  /// Things the person should know now that the bundle is in, such as an IPTV
  /// account that stays hidden until Advanced sources is switched on here.
  final List<String> notes;
}

/// Thrown when part of a bundle could not be stored. What was stored before the
/// failure stays: each item is its own write, and there is no transaction
/// across secure storage and the settings box to roll back with.
class TransferApplyException implements Exception {
  const TransferApplyException(this.message);

  final String message;

  @override
  String toString() => message;
}

final transferServiceProvider = Provider<TransferService>(
  (ref) => TransferService(ref),
);

/// Reads this device's settings into a [TransferBundle] and writes one that
/// arrived (§17).
///
/// Goes through the same stores and controllers the rest of the app uses, so a
/// transferred account is stored exactly as one typed in would be (the password
/// in secure storage, the record in the settings box, §3) and the screens see
/// it without a restart.
class TransferService {
  TransferService(this._ref);

  final Ref _ref;

  Future<CollectedSettings> collect() async {
    final notes = <String>[];
    final settings = _ref.read(appSettingsStoreProvider);

    final preferences = <String, Object>{};
    for (final key in TransferPreferences.bools) {
      if (settings.has(key)) {
        preferences[key] = settings.getBool(key, fallback: false);
      }
    }
    for (final key in TransferPreferences.strings) {
      final value = settings.getString(key);
      if (value != null) preferences[key] = value;
    }
    for (final key in TransferPreferences.stringMaps) {
      final value = settings.getStringMap(key);
      if (value.isNotEmpty) preferences[key] = value;
    }

    // The stores, not the providers: the provider reports no accounts while
    // Advanced sources is off (§8.2), and a person who switched it off to tidy
    // up still expects their accounts to move.
    final xtreamStore = _ref.read(xtreamAccountStoreProvider);
    final xtream = [
      for (final account in xtreamStore.accounts())
        TransferredXtream(account, await xtreamStore.password(account.id)),
    ];

    final smbStore = _ref.read(smbShareStoreProvider);
    final smb = [
      for (final share in smbStore.shares())
        TransferredSmb(share, await smbStore.password(share.id)),
    ];

    final tmdbKey = await _ref.read(tmdbKeyProvider.future);

    TransferredAi? ai;
    final setup = await _ref.read(aiSetupProvider.future);
    if (setup != null) {
      // A provider on this very machine means nothing on another one: Ollama at
      // localhost would point the TV at itself.
      if (_isThisDevice(setup.config.host)) {
        notes.add(
          'Your AI provider runs on this device, so it is not sent. Set it up '
          'again there with this device\'s address on your network.',
        );
      } else {
        ai = TransferredAi(setup.config.toJson(), setup.apiKey);
      }
    }

    return CollectedSettings(
      TransferBundle(
        createdAt: DateTime.now(),
        preferences: preferences,
        xtream: xtream,
        smb: smb,
        tmdbKey: tmdbKey,
        ai: ai,
      ),
      notes,
    );
  }

  static bool _isThisDevice(String host) {
    final h = host.toLowerCase();
    return h == 'localhost' || h == '::1' || h.startsWith('127.');
  }

  Future<ApplyResult> apply(TransferBundle bundle) async {
    final notes = <String>[];
    final failed = <String>[];

    Future<void> step(TransferItem item, Future<void> Function() body) async {
      try {
        await body();
      } catch (_) {
        failed.add(item.label);
      }
    }

    if (bundle.preferences.isNotEmpty) {
      await step(TransferItem.preferences, () => _applyPreferences(bundle));
    }

    if (bundle.xtream.isNotEmpty) {
      await step(TransferItem.xtream, () async {
        final store = _ref.read(xtreamAccountStoreProvider);
        for (final x in bundle.xtream) {
          await store.save(x.account, password: x.password);
          // Anything kept for the account it replaces was made with other
          // choices and another login.
          await forgetSourceCache(_ref, 'xtream|${x.account.id}|');
        }
        _ref.invalidate(xtreamAccountsProvider);
      });
      if (!_ref.read(advancedSourcesEnabledProvider)) {
        // §8.2's acknowledgement is the person's, at this device, so the
        // switch is not copied with the accounts.
        notes.add(
          'The IPTV accounts are saved but hidden. Turn on Advanced sources '
          'in Settings to use them.',
        );
      }
    }

    if (bundle.smb.isNotEmpty) {
      await step(TransferItem.smb, () async {
        final store = _ref.read(smbShareStoreProvider);
        for (final s in bundle.smb) {
          await store.save(s.share, password: s.password);
        }
        _ref.invalidate(smbSharesProvider);
      });
    }

    final tmdb = bundle.tmdbKey;
    if (tmdb != null) {
      await step(
        TransferItem.tmdb,
        () => _ref.read(tmdbKeyProvider.notifier).restore(tmdb),
      );
    }

    final ai = bundle.ai;
    if (ai != null) {
      await step(TransferItem.ai, () async {
        final config = AiProviderConfig.fromJson(ai.config);
        if (config == null) throw const FormatException('Unknown provider.');
        await _ref.read(aiSetupProvider.notifier).restore(config, ai.key);
      });
      if (failed.isEmpty) {
        notes.add(
          'AI features will ask before they send anything to the provider.',
        );
      }
    }

    if (failed.isNotEmpty) {
      throw TransferApplyException(
        'Could not save: ${failed.join(', ')}. The rest was saved.',
      );
    }
    return ApplyResult(notes);
  }

  Future<void> _applyPreferences(TransferBundle bundle) async {
    final store = _ref.read(appSettingsStoreProvider);
    // The allowlist again, on the way in. [TransferBundle.decode] already ran
    // it, but a bundle can be built in code, and this is the last place that
    // can refuse to write a key the receiver never agreed to move.
    for (final e in TransferPreferences.filter(bundle.preferences).entries) {
      switch (e.value) {
        case final bool v:
          await store.setBool(e.key, v);
        case final String v:
          await store.setString(e.key, v);
        case final Map<String, String> v:
          // Merged, not replaced: the placement map holds an entry per Plex
          // library, and a TV linked to a server the phone has never seen would
          // otherwise lose those choices. The sender's entry wins on a match,
          // like every other same-id item (§17.3).
          await store.setStringMap(e.key, {...store.getStringMap(e.key), ...v});
      }
    }
    _ref.invalidate(playbackPrefsProvider);
    _ref.invalidate(libraryMappingProvider);
    _ref.invalidate(hiddenWordsProvider);
  }
}
