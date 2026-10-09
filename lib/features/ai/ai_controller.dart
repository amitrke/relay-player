import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/theme/relay_theme.dart';
import '../../data/ai/ai_provider.dart';
import '../../data/ai/natural_search.dart';
import '../../data/ai/text_client.dart';
import '../../domain/models/catalog_item.dart';
import '../library/library_screen.dart' show libraryItemsProvider;
import '../library/library_tab.dart';
import '../settings/settings_controller.dart';

const _kProvider = 'ai.provider';
const _kConsent = 'ai.consent';
const _kKey = 'ai.key';

/// A configured provider with its key joined back in.
class AiSetup {
  const AiSetup(this.config, this.apiKey);

  final AiProviderConfig config;

  /// Null for a local provider that needs none.
  final String? apiKey;
}

/// The one configured AI provider, or null.
///
/// One at a time for now: section 9 describes several, but nothing yet chooses
/// between them, and a list with one active member is more UI than the first
/// feature earns. The config is non-secret and lives in the settings box; the
/// key goes only to secure storage (section 3, which forbids secrets in the
/// unencrypted box). No provider means no AI UI anywhere (section 9.1).
final aiSetupProvider = AsyncNotifierProvider<AiSetupController, AiSetup?>(
  AiSetupController.new,
);

class AiSetupController extends AsyncNotifier<AiSetup?> {
  static const _storage = FlutterSecureStorage();

  @override
  Future<AiSetup?> build() async {
    final config = AiProviderConfig.fromJson(
      ref.read(appSettingsStoreProvider).getStringMap(_kProvider),
    );
    if (config == null) return null;
    final key = await _storage.read(key: _kKey);
    return AiSetup(config, key == null || key.isEmpty ? null : key);
  }

  /// Tries the provider with a one-word request, and only saves it if that
  /// works, so a typo is reported here and not later as a search that fails.
  /// Throws [AiException] with a message fit to show.
  Future<void> save(AiProviderConfig config, String? key) async {
    final trimmedKey = key?.trim();
    if (config.baseUrl.isEmpty || config.model.isEmpty) {
      throw const AiException('Fill in the address and the model.');
    }
    if (!config.isLocal && (trimmedKey == null || trimmedKey.isEmpty)) {
      throw const AiException('This provider needs an API key.');
    }

    await OpenAiCompatibleClient(
      baseUrl: config.baseUrl,
      model: config.model,
      apiKey: trimmedKey,
      extraBody: config.requestExtras,
    ).complete(
      system: 'Reply with the single word OK.',
      user: 'ping',
      maxTokens: 8,
    );

    await ref
        .read(appSettingsStoreProvider)
        .setStringMap(_kProvider, config.toJson());
    if (trimmedKey != null && trimmedKey.isNotEmpty) {
      await _storage.write(key: _kKey, value: trimmedKey);
    } else {
      await _storage.delete(key: _kKey);
    }
    state = AsyncData(AiSetup(config, trimmedKey));
  }

  /// Stores a provider that arrived from another device (§17) without trying
  /// it again: it was tried when it was saved there, and a TV that is offline
  /// for a moment should still take it.
  ///
  /// Consent is deliberately not part of this. §9.3's moment belongs to the
  /// person at this device, so the first feature to use the provider asks.
  Future<void> restore(AiProviderConfig config, String? key) async {
    final trimmedKey = key?.trim();
    await ref
        .read(appSettingsStoreProvider)
        .setStringMap(_kProvider, config.toJson());
    if (trimmedKey != null && trimmedKey.isNotEmpty) {
      await _storage.write(key: _kKey, value: trimmedKey);
    } else {
      await _storage.delete(key: _kKey);
    }
    state = AsyncData(
      AiSetup(
        config,
        trimmedKey == null || trimmedKey.isEmpty ? null : trimmedKey,
      ),
    );
  }

  /// Forgets the provider, its key and every consent given for it.
  Future<void> remove() async {
    await ref.read(appSettingsStoreProvider).setStringMap(_kProvider, const {});
    await _storage.delete(key: _kKey);
    await ref.read(aiConsentProvider.notifier).clear();
    // The picks were made by this provider and mean nothing without it.
    await ref.read(appSettingsStoreProvider).setString('ai.recs', '');
    state = const AsyncData(null);
  }
}

final aiClientProvider = Provider<TextGenerationClient?>((ref) {
  final setup = ref.watch(aiSetupProvider).value;
  if (setup == null) return null;
  return OpenAiCompatibleClient(
    baseUrl: setup.config.baseUrl,
    model: setup.config.model,
    apiKey: setup.apiKey,
    extraBody: setup.config.requestExtras,
  );
});

/// Which feature has been allowed to send which kind of data to which provider
/// (section 9.3, `AiConsentRecord`): one grant per feature and provider, so
/// allowing one feature never allows another, and changing provider asks again.
/// Local providers are exempt, since nothing reaches a third party.
final aiConsentProvider =
    NotifierProvider<AiConsentController, Map<String, String>>(
      AiConsentController.new,
    );

class AiConsentController extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() =>
      ref.read(appSettingsStoreProvider).getStringMap(_kConsent);

  static String keyFor(AiFeature feature, AiProviderConfig config) =>
      '${feature.name}|${config.host}';

  /// When it was granted, or null.
  DateTime? grantedAt(AiFeature feature, AiProviderConfig config) =>
      DateTime.tryParse(state[keyFor(feature, config)] ?? '');

  bool allows(AiFeature feature, AiProviderConfig config) =>
      config.isLocal || grantedAt(feature, config) != null;

  Future<void> grant(AiFeature feature, AiProviderConfig config) => _write({
    ...state,
    keyFor(feature, config): DateTime.now().toIso8601String(),
  });

  /// Stops the feature sending, and keeps the key.
  Future<void> revoke(AiFeature feature, AiProviderConfig config) =>
      _write({...state}..remove(keyFor(feature, config)));

  Future<void> clear() => _write(const {});

  Future<void> _write(Map<String, String> next) async {
    state = next;
    await ref.read(appSettingsStoreProvider).setStringMap(_kConsent, next);
  }
}

/// Asks for consent the first time [feature] is about to send data to this
/// provider. True when it may go ahead.
///
/// Names the provider and the data (section 9.3 forbids "AI service"), and is
/// per feature, so it appears once for each. A local provider never sees it.
Future<bool> ensureAiConsent(
  BuildContext context,
  WidgetRef ref,
  AiFeature feature,
) async {
  final config = ref.read(aiSetupProvider).value?.config;
  if (config == null) return false;
  final consent = ref.read(aiConsentProvider.notifier);
  if (consent.allows(feature, config)) return true;

  final t = RelayTheme.of(context);
  final allow = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        'Send data to ${config.displayName}?',
        style: TextStyle(
          color: t.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        '${feature.label} will send this to ${config.displayName}: '
        '${feature.dataSent}'
        '${feature.timing == null ? '' : '\n\n${feature.timing}'}'
        '\n\nIt goes straight from this device to them, '
        'never through us. You can switch this off again in Settings, AI '
        'features.',
        style: TextStyle(color: t.inkDim, fontSize: 14, height: 1.55),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: t.inkDim),
          child: const Text('Not now'),
        ),
        FilledButton(
          autofocus: true,
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: t.accent,
            foregroundColor: t.accentInk,
          ),
          child: const Text('Allow'),
        ),
      ],
    ),
  );
  if (allow != true) return false;
  await consent.grant(feature, config);
  return true;
}

/// How far a search has got, and what it has found so far.
class AiSearchProgress {
  const AiSearchProgress({
    this.items = const [],
    this.total = 0,
    this.covered = 0,
    this.searched = 0,
    this.parts = 0,
    this.partsFailed = 0,
    this.done = false,
  });

  /// Picks so far, in the order they arrived. An item never moves once shown,
  /// so a later answer adds to the end and does not shuffle what is on screen.
  final List<CatalogItem> items;

  /// Distinct titles in the library, and how many of them went into a request.
  /// They differ only for a library past [naturalSearchMaxChunks] requests.
  final int total;
  final int covered;

  /// Titles whose request has been answered, or has failed.
  final int searched;

  final int parts;

  /// Requests that failed (a rate limit, no network), whose titles were not
  /// searched. Everything else in the library was.
  final int partsFailed;
  final bool done;

  bool get truncated => covered < total;

  AiSearchProgress copyWith({
    List<CatalogItem>? items,
    int? searched,
    int? partsFailed,
    bool? done,
  }) => AiSearchProgress(
    items: items ?? this.items,
    total: total,
    covered: covered,
    searched: searched ?? this.searched,
    parts: parts,
    partsFailed: partsFailed ?? this.partsFailed,
    done: done ?? this.done,
  );
}

/// Most picks kept from a whole search, however many parts answer.
const aiSearchMaxResults = 36;

/// One more try for a part that failed, after [aiSearchRetryDelayProvider]. Free
/// tiers answer a burst with a rate limit and a router sometimes sends back
/// nothing, and both usually pass on a second ask, whereas dropping that part
/// meant a slice of the library silently went unsearched (seen on the Google TV
/// emulator, 2026-10-09: 1 of 6 parts failed on the first real run).
const aiSearchRetries = 1;

/// A provider, so a test can run without waiting.
final aiSearchRetryDelayProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 2),
);

/// How many requests of one search are in flight at once. Two: enough that the
/// slowest part is not the only thing waited on, few enough that a free tier's
/// rate limit is not hit by a single search.
const aiSearchConcurrency = 2;

/// Library titles a model picked for [query] (section 9.2), as they are found.
///
/// A library past a few hundred titles does not fit one request that a free or
/// local model can handle, and cutting it at the first few hundred (which this
/// did until 2026-10-09) meant most of it was never searched, silently. So it is
/// sent in parts, [aiSearchConcurrency] at a time, and this emits again as each
/// part is answered: the first picks appear after the first part, and the rest
/// join them. Each pick is checked against its title (see [parseCheckedPicks]);
/// one that is not, is dropped.
///
/// One part failing does not fail the search. Only when every part has does it
/// become an error. Leaving the screen stops it asking for more.
///
/// Re-checks consent itself, so no caller can reach the provider around the
/// dialog; the screen asks first and this is the backstop.
final aiSearchProvider = StreamProvider.autoDispose
    .family<AiSearchProgress, String>(
      // No automatic retry. Riverpod 3 retries a provider that fails, up to ten
      // times with a growing delay, for anything that is an Exception, which an
      // AiException is. For this provider that is ten more rounds of paid
      // requests after a rate limit or a bad key, the whole multi-part search
      // each time, with the spinner up throughout. A failure here is shown, and
      // the person decides whether to try again.
      retry: (_, _) => null,
      (ref, query) {
        final setup = ref.watch(aiSetupProvider).value;
        final client = ref.watch(aiClientProvider);
        if (setup == null || client == null) {
          throw const AiException('No AI provider is set up.');
        }
        if (!ref
            .read(aiConsentProvider.notifier)
            .allows(AiFeature.naturalSearch, setup.config)) {
          throw const AiException(
            'Natural-language search is switched off for this provider.',
          );
        }

        final retryDelay = ref.read(aiSearchRetryDelayProvider);
        final controller = StreamController<AiSearchProgress>();
        var cancelled = false;
        ref.onDispose(() {
          cancelled = true;
          controller.close();
        });

        void emit(AiSearchProgress p) {
          if (!cancelled && !controller.isClosed) controller.add(p);
        }

        Future<void> run() async {
          final library = <CatalogItem>[];
          for (final tab in [LibraryTab.movies, LibraryTab.series]) {
            try {
              library.addAll(await ref.read(libraryItemsProvider(tab).future));
            } catch (_) {}
          }
          if (cancelled) return;

          final cut = buildLibraryChunks(library);
          var progress = AiSearchProgress(
            total: cut.total,
            covered: cut.covered,
            parts: cut.chunks.length,
          );
          if (cut.chunks.isEmpty) {
            emit(progress.copyWith(done: true));
            return;
          }
          emit(progress);

          Object? firstError;
          var next = 0;

          Future<void> worker() async {
            while (!cancelled && next < cut.chunks.length) {
              final chunk = cut.chunks[next++];
              try {
                String answer;
                for (var attempt = 0; ; attempt++) {
                  try {
                    answer = await client.complete(
                      system: naturalSearchCheckedSystemPrompt,
                      user: naturalSearchUserMessage(query, chunk),
                      maxTokens: aiPickMaxTokens,
                    );
                    break;
                  } catch (_) {
                    if (cancelled || attempt >= aiSearchRetries) rethrow;
                    await Future<void>.delayed(retryDelay);
                    if (cancelled) return;
                  }
                }
                if (cancelled) return;
                final found = parseCheckedPicks(answer, chunk);
                progress = progress.copyWith(
                  items: [
                    ...progress.items,
                    ...found,
                  ].take(aiSearchMaxResults).toList(),
                  searched: progress.searched + chunk.items.length,
                );
              } catch (e) {
                if (cancelled) return;
                firstError ??= e;
                progress = progress.copyWith(
                  searched: progress.searched + chunk.items.length,
                  partsFailed: progress.partsFailed + 1,
                );
              }
              emit(progress);
            }
          }

          await Future.wait([
            for (var i = 0; i < aiSearchConcurrency; i++) worker(),
          ]);
          if (cancelled) return;

          if (progress.partsFailed == progress.parts) {
            if (!controller.isClosed) {
              controller.addError(
                firstError is AiException
                    ? firstError as AiException
                    : AiException('${firstError ?? 'The search failed.'}'),
              );
            }
          } else {
            // Kept once finished, so coming back to the same search shows the
            // answer and does not ask the provider again.
            ref.keepAlive();
            emit(progress.copyWith(done: true));
          }
        }

        unawaited(
          run().whenComplete(() {
            if (!controller.isClosed) controller.close();
          }),
        );
        return controller.stream;
      },
    );
