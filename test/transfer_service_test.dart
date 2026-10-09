import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:relay_player/data/ai/ai_provider.dart';
import 'package:relay_player/data/filesystem/smb_source.dart';
import 'package:relay_player/data/local/app_settings_store.dart';
import 'package:relay_player/data/local/library_cache.dart';
import 'package:relay_player/data/transfer/transfer_bundle.dart';
import 'package:relay_player/data/xtream/xtream_account_store.dart';
import 'package:relay_player/features/advanced_sources/hidden_words_controller.dart';
import 'package:relay_player/features/advanced_sources/xtream_controller.dart';
import 'package:relay_player/features/ai/ai_controller.dart';
import 'package:relay_player/features/library/library_cache_provider.dart';
import 'package:relay_player/features/local_network/smb_controller.dart';
import 'package:relay_player/features/metadata/tmdb_controller.dart';
import 'package:relay_player/features/player/playback_prefs.dart';
import 'package:relay_player/features/settings/settings_controller.dart';
import 'package:relay_player/features/transfer/transfer_service.dart';

/// Moves settings from one "device" to another through the real stores and
/// controllers, so a storage key that is renamed in one place fails here instead
/// of quietly dropping out of transfers.
///
/// A device is a settings box plus a secure-storage mock. Secure storage is a
/// process-wide singleton, so "switching device" resets it.
///
/// Placeholder hosts and credentials only, per the no-provider rule in
/// CLAUDE.md.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  var boxes = 0;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('relay_transfer_test');
    Hive.init(dir.path);
    FlutterSecureStorage.setMockInitialValues({});
    addTearDown(() async {
      await Hive.close();
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
  });

  /// A fresh device: empty settings box, empty secure storage.
  Future<({ProviderContainer c, AppSettingsStore store})> device() async {
    FlutterSecureStorage.setMockInitialValues({});
    final store = AppSettingsStore.withBox(
      await Hive.openBox<dynamic>('device_${boxes++}'),
    );
    final c = ProviderContainer(
      overrides: [
        appSettingsStoreProvider.overrideWithValue(store),
        libraryCacheProvider.overrideWith((ref) async => MemoryLibraryCache()),
      ],
    );
    addTearDown(c.dispose);
    return (c: c, store: store);
  }

  const account = XtreamAccount(
    id: 'a1',
    name: 'Line one',
    host: 'http://panel-host.example.invalid:8080',
    username: 'user',
    liveCategoryIds: ['10', '11'],
    liveCategoryNames: {'10': 'News', '11': 'Sport'},
    liveChannelPicks: {
      '10': ['500', '501'],
    },
  );

  const share = SmbShare(
    id: 's1',
    name: 'NAS',
    host: '<lan-ip>',
    username: 'me',
  );

  const openAi = AiProviderConfig(
    preset: AiPreset.openAi,
    baseUrl: 'https://api.openai.com/v1',
    model: 'gpt-4o-mini',
  );

  /// Everything a person might have set up on a phone.
  Future<({ProviderContainer c, AppSettingsStore store})> fullyConfigured() async {
    final d = await device();
    final c = d.c;
    await c.read(hiddenWordsProvider.notifier).add('Germany');
    await c
        .read(playbackPrefsProvider.notifier)
        .update(
          const PlaybackPrefs(
            skipSeconds: 30,
            audioLanguage: 'en',
            subtitlesOn: true,
            subtitleLanguage: 'es',
            subtitleSize: SubtitleSize.large,
          ),
        );
    await d.store.setStringMap('plex.libraryMapping', {'srv|1': 'movies'});
    await c
        .read(xtreamAccountStoreProvider)
        .save(account, password: 'xtream-pass');
    await c.read(smbShareStoreProvider).save(share, password: 'smb-pass');
    await c.read(tmdbKeyProvider.notifier).restore('tmdb-key');
    await c.read(aiSetupProvider.future);
    await c.read(aiSetupProvider.notifier).restore(openAi, 'sk-test');
    // The things that must NOT travel.
    await d.store.setBool('advancedSourcesEnabled', true);
    await d.store.setBool('onboardingSeen', true);
    await d.store.setStringMap('ai.consent', {
      'naturalSearch|api.openai.com': '2026-10-01T00:00:00.000',
    });
    return d;
  }

  /// What [from] would put on the wire, read back the way a receiver does.
  ///
  /// Call this **before** [device] makes the receiving side: secure storage is
  /// one process-wide mock, so starting the second device wipes the first one's
  /// passwords. Real devices are separate, which is why collecting first is the
  /// faithful order and not just a workaround.
  Future<TransferBundle> wire(ProviderContainer from) async {
    final collected = await from.read(transferServiceProvider).collect();
    return TransferBundle.decode(collected.bundle.encode());
  }

  test('a fully set up device arrives intact on an empty one', () async {
    final phone = await fullyConfigured();
    final bundle = await wire(phone.c);
    expect(bundle.items, TransferItem.values.toSet());

    final tv = await device();
    final result = await tv.c.read(transferServiceProvider).apply(bundle);

    expect(tv.c.read(hiddenWordsProvider), ['Germany']);

    final prefs = tv.c.read(playbackPrefsProvider);
    expect(prefs.skipSeconds, 30);
    expect(prefs.audioLanguage, 'en');
    expect(prefs.subtitlesOn, isTrue);
    expect(prefs.subtitleLanguage, 'es');
    expect(prefs.subtitleSize, SubtitleSize.large);

    expect(tv.store.getStringMap('plex.libraryMapping'), {'srv|1': 'movies'});

    final xtream = tv.c.read(xtreamAccountStoreProvider);
    final got = xtream.accounts().single;
    expect(got.host, account.host);
    expect(got.liveCategoryIds, ['10', '11']);
    expect(got.liveCategoryNames, {'10': 'News', '11': 'Sport'});
    expect(got.liveChannelPicks, {
      '10': ['500', '501'],
    });
    expect(await xtream.password('a1'), 'xtream-pass');

    final smb = tv.c.read(smbShareStoreProvider);
    expect(smb.shares().single.host, '<lan-ip>');
    expect(await smb.password('s1'), 'smb-pass');

    expect(await tv.c.read(tmdbKeyProvider.future), 'tmdb-key');

    final ai = (await tv.c.read(aiSetupProvider.future))!;
    expect(ai.config.model, 'gpt-4o-mini');
    expect(ai.apiKey, 'sk-test');

    expect(result.notes, isNotEmpty);
  });

  test('what each device must decide for itself does not travel', () async {
    final phone = await fullyConfigured();
    final bundle = await wire(phone.c);
    final tv = await device();
    final result = await tv.c.read(transferServiceProvider).apply(bundle);

    // §8.2: the acknowledgement happens at the device that will use it.
    expect(tv.store.getBool('advancedSourcesEnabled', fallback: false), isFalse);
    expect(tv.c.read(advancedSourcesEnabledProvider), isFalse);
    expect(tv.store.getBool('onboardingSeen', fallback: false), isFalse);
    // §9.3: consent is per device, feature and provider.
    expect(tv.store.getStringMap('ai.consent'), isEmpty);

    // Saved, but the gate keeps them out of sight, and the person is told why.
    expect(tv.c.read(xtreamAccountStoreProvider).accounts(), hasLength(1));
    expect(tv.c.read(xtreamAccountsProvider), isEmpty);
    expect(
      result.notes.any((n) => n.contains('Advanced sources')),
      isTrue,
      reason: result.notes.join(' | '),
    );
    expect(result.notes.any((n) => n.contains('AI features will ask')), isTrue);
  });

  test('no note about Advanced sources once it is already on', () async {
    final phone = await fullyConfigured();
    final bundle = await wire(phone.c);
    final tv = await device();
    await tv.store.setBool('advancedSourcesEnabled', true);
    final result = await tv.c.read(transferServiceProvider).apply(bundle);
    expect(result.notes.any((n) => n.contains('Advanced sources')), isFalse);
  });

  test('a move replaces a match and keeps everything else', () async {
    final phone = await fullyConfigured();
    final bundle = await wire(phone.c);
    final tv = await device();

    // The TV already has a stale copy of the same line, and a different one.
    final store = tv.c.read(xtreamAccountStoreProvider);
    await store.save(
      const XtreamAccount(
        id: 'a1',
        name: 'Old name',
        host: 'http://old-host.example.invalid',
        username: 'old',
      ),
      password: 'old-pass',
    );
    await store.save(
      const XtreamAccount(
        id: 'other',
        name: 'Other',
        host: 'http://other-host.example.invalid',
        username: 'o',
      ),
      password: 'other-pass',
    );
    await tv.c.read(tmdbKeyProvider.notifier).restore('old-tmdb');

    await tv.c.read(transferServiceProvider).apply(bundle);

    final accounts = {for (final a in store.accounts()) a.id: a};
    expect(accounts.keys, unorderedEquals(['a1', 'other']));
    expect(accounts['a1']!.host, account.host);
    expect(await store.password('a1'), 'xtream-pass');
    expect(accounts['other']!.host, 'http://other-host.example.invalid');
    expect(await store.password('other'), 'other-pass');
    expect(await tv.c.read(tmdbKeyProvider.future), 'tmdb-key');
  });

  test('the Plex placement map is merged, so the receiver keeps its own servers',
      () async {
    final phone = await fullyConfigured();
    final bundle = await wire(phone.c);
    final tv = await device();
    await tv.store.setStringMap('plex.libraryMapping', {
      'srv|1': 'hidden',
      'tv-only|9': 'series',
    });

    await tv.c.read(transferServiceProvider).apply(bundle);

    expect(tv.store.getStringMap('plex.libraryMapping'), {
      'srv|1': 'movies', // the sender's choice wins on a match
      'tv-only|9': 'series', // and a server only the TV knows is untouched
    });
  });

  test('only what was ticked is written', () async {
    final phone = await fullyConfigured();
    final bundle = await wire(phone.c);
    final tv = await device();
    await tv.c
        .read(transferServiceProvider)
        .apply(bundle.only({TransferItem.tmdb}));

    expect(await tv.c.read(tmdbKeyProvider.future), 'tmdb-key');
    expect(tv.c.read(xtreamAccountStoreProvider).accounts(), isEmpty);
    expect(tv.c.read(smbShareStoreProvider).shares(), isEmpty);
    expect(await tv.c.read(aiSetupProvider.future), isNull);
    expect(tv.c.read(hiddenWordsProvider), isEmpty);
    expect(tv.c.read(playbackPrefsProvider).skipSeconds, 10);
  });

  test('an empty device has nothing to send', () async {
    final blank = await device();
    final collected = await blank.c.read(transferServiceProvider).collect();
    expect(collected.bundle.items, isEmpty);
  });

  test('a default nobody chose is not sent as if they had', () async {
    final blank = await device();
    final bundle = (await blank.c.read(transferServiceProvider).collect()).bundle;
    expect(bundle.preferences, isEmpty);
  });

  test('accounts still move while Advanced sources is switched off', () async {
    final phone = await fullyConfigured();
    await phone.store.setBool('advancedSourcesEnabled', false);
    // The control: with it off the provider really does report nothing, so
    // collecting through it would have lost the account.
    expect(phone.c.read(xtreamAccountsProvider), isEmpty);

    final collected = await phone.c.read(transferServiceProvider).collect();
    expect(collected.bundle.xtream, hasLength(1));
    expect(collected.bundle.xtream.single.password, 'xtream-pass');
  });

  test('an AI provider on the sending machine itself is left behind, with a reason',
      () async {
    final phone = await device();
    await phone.c.read(aiSetupProvider.future);
    await phone.c
        .read(aiSetupProvider.notifier)
        .restore(
          const AiProviderConfig(
            preset: AiPreset.ollama,
            baseUrl: 'http://localhost:11434/v1',
            model: 'llama3.1',
          ),
          null,
        );

    final collected = await phone.c.read(transferServiceProvider).collect();
    expect(collected.bundle.ai, isNull);
    expect(collected.notes.single, contains('runs on this device'));
  });

  test('a bundle built in code still cannot write a key off the allowlist',
      () async {
    final tv = await device();
    await tv.c
        .read(transferServiceProvider)
        .apply(
          TransferBundle(
            createdAt: DateTime.now(),
            preferences: const {
              'advancedSourcesEnabled': true,
              'ai.key': 'leak',
              'playback.skipSeconds': '5',
            },
          ),
        );
    expect(tv.store.has('advancedSourcesEnabled'), isFalse);
    expect(tv.store.has('ai.key'), isFalse);
    expect(tv.store.getString('playback.skipSeconds'), '5');
  });

  test('replacing an account drops what was kept for the old one', () async {
    final tv = await device();
    final cache = MemoryLibraryCache();
    final c = ProviderContainer(
      overrides: [
        appSettingsStoreProvider.overrideWithValue(tv.store),
        libraryCacheProvider.overrideWith((ref) async => cache),
      ],
    );
    addTearDown(c.dispose);
    await cache.write(
      'xtream|a1|movies',
      CachedSource(items: const [], signature: 's', at: DateTime.now()),
    );
    await cache.write(
      'xtream|keep|movies',
      CachedSource(items: const [], signature: 's', at: DateTime.now()),
    );

    await c
        .read(transferServiceProvider)
        .apply(
          TransferBundle(
            createdAt: DateTime.now(),
            xtream: const [TransferredXtream(account, 'p')],
          ),
        );

    expect(cache.map.keys, ['xtream|keep|movies']);
  });
}
