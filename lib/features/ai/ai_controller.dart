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

/// Library titles a model picked for [query] (section 9.2).
///
/// Re-checks consent itself, so no caller can reach the provider around the
/// dialog; the screen asks first and this is the backstop.
final aiSearchProvider = FutureProvider.family<List<CatalogItem>, String>((
  ref,
  query,
) async {
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

  final library = <CatalogItem>[];
  for (final tab in [LibraryTab.movies, LibraryTab.series]) {
    try {
      library.addAll(await ref.watch(libraryItemsProvider(tab).future));
    } catch (_) {}
  }
  final index = buildLibraryIndex(library);
  if (index.items.isEmpty) return const [];

  final answer = await client.complete(
    system: naturalSearchSystemPrompt,
    user: naturalSearchUserMessage(query, index),
    maxTokens: aiPickMaxTokens,
  );
  return resolvePicks(answer, index);
});
