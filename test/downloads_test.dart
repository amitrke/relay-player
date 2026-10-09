import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:relay_player/data/downloads/download_engine.dart';
import 'package:relay_player/data/downloads/download_record.dart';
import 'package:relay_player/data/local/app_settings_store.dart';
import 'package:relay_player/data/plex/plex_service.dart';
import 'package:relay_player/features/downloads/downloads_controller.dart';
import 'package:relay_player/features/settings/settings_controller.dart';

/// A file server that behaves the way the downloader has to cope with.
///
/// Placeholder tokens and names only, per the no-provider rule in CLAUDE.md.
class _FileServer {
  _FileServer(this.bytes);

  final Uint8List bytes;

  /// Answer 200 with the whole file even when a Range is asked for.
  bool ignoreRange = false;

  /// Send this many bytes and then drop the connection.
  int? truncateAfter;

  /// Refuse with this status.
  int? refuseWith;

  /// Delay between 32 KB chunks, so a test can act mid-download.
  Duration pace = Duration.zero;

  final requests = <String?>[];
  late final HttpServer _server;

  Uri get url => Uri.parse('http://127.0.0.1:${_server.port}/file.mkv');

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handle);
  }

  Future<void> stop() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    final range = request.headers.value(HttpHeaders.rangeHeader);
    requests.add(range);
    final response = request.response;

    if (refuseWith != null) {
      response.statusCode = refuseWith!;
      await response.close();
      return;
    }

    var start = 0;
    if (!ignoreRange && range != null) {
      start = int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)!.group(1)!);
      if (start >= bytes.length) {
        response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes */${bytes.length}',
        );
        await response.close();
        return;
      }
      response.statusCode = HttpStatus.partialContent;
      response.headers.set(
        HttpHeaders.contentRangeHeader,
        'bytes $start-${bytes.length - 1}/${bytes.length}',
      );
    }

    final body = bytes.sublist(start);
    response.contentLength = body.length;
    final limit = truncateAfter;
    var sent = 0;
    try {
      for (var i = 0; i < body.length; i += 32 * 1024) {
        if (limit != null && sent >= limit) {
          // Promised more than was sent: closing now makes the server drop the
          // connection part-way, which is what a client sees when Wi-Fi goes.
          await response.close();
          return;
        }
        final end = min(i + 32 * 1024, body.length);
        response.add(body.sublist(i, end));
        sent = end;
        await response.flush();
        if (pace > Duration.zero) await Future<void>.delayed(pace);
      }
      await response.close();
    } catch (_) {
      // The client went away; that is what several tests do on purpose.
    }
  }
}

Uint8List _bytes(int n) =>
    Uint8List.fromList(List<int>.generate(n, (i) => (i * 31 + 7) & 0xFF));

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('relay_downloads_test');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
  });

  group('engine', () {
    const engine = DownloadEngine(connectTimeout: Duration(seconds: 3));

    Future<int> fetch(_FileServer s, File f, {bool Function()? cancelled}) =>
        engine.fetch(
          s.url,
          f,
          cancelled: cancelled ?? () => false,
          onProgress: (_, _) {},
        );

    test('writes the whole file', () async {
      final server = _FileServer(_bytes(200 * 1024));
      await server.start();
      addTearDown(server.stop);

      final file = File('${dir.path}/a.part');
      expect(await fetch(server, file), 200 * 1024);
      expect(file.readAsBytesSync(), server.bytes);
    });

    test('continues a partial file from where it stopped', () async {
      final server = _FileServer(_bytes(200 * 1024));
      await server.start();
      addTearDown(server.stop);

      final file = File('${dir.path}/a.part')
        ..writeAsBytesSync(server.bytes.sublist(0, 70000));
      expect(await fetch(server, file), 200 * 1024);

      expect(server.requests.single, 'bytes=70000-');
      expect(file.readAsBytesSync(), server.bytes);
    });

    test('starts over, not appends, when the server ignores the range', () async {
      final server = _FileServer(_bytes(100 * 1024))..ignoreRange = true;
      await server.start();
      addTearDown(server.stop);

      final file = File('${dir.path}/a.part')
        ..writeAsBytesSync(server.bytes.sublist(0, 30000));
      await fetch(server, file);

      // The control: it did ask for a range, so this is the ignoring case and
      // not a request that never carried one.
      expect(server.requests.single, 'bytes=30000-');
      expect(file.lengthSync(), 100 * 1024);
      expect(file.readAsBytesSync(), server.bytes);
    });

    test('treats "range not satisfiable" at the exact length as done', () async {
      final server = _FileServer(_bytes(50 * 1024));
      await server.start();
      addTearDown(server.stop);

      final file = File('${dir.path}/a.part')..writeAsBytesSync(server.bytes);
      expect(await fetch(server, file), 50 * 1024);
      expect(file.readAsBytesSync(), server.bytes);
    });

    test('a partial file longer than the server\'s copy is refused and removed',
        () async {
      final server = _FileServer(_bytes(10 * 1024));
      await server.start();
      addTearDown(server.stop);

      final file = File('${dir.path}/a.part')
        ..writeAsBytesSync(Uint8List(20 * 1024));
      await expectLater(
        fetch(server, file),
        throwsA(
          isA<DownloadException>().having(
            (e) => e.message,
            'message',
            contains('changed on the server'),
          ),
        ),
      );
      expect(file.existsSync(), isFalse);
    });

    test('a body that ends early is a dropped connection, not a finished file',
        () async {
      final server = _FileServer(_bytes(300 * 1024))..truncateAfter = 64 * 1024;
      await server.start();
      addTearDown(server.stop);

      final file = File('${dir.path}/a.part');
      await expectLater(fetch(server, file), throwsA(isA<DownloadException>()));
      // What arrived is kept, to resume from.
      expect(file.lengthSync(), greaterThan(0));
      expect(file.lengthSync(), lessThan(300 * 1024));
    });

    test('says so when the server will not allow it', () async {
      final server = _FileServer(_bytes(10))..refuseWith = 403;
      await server.start();
      addTearDown(server.stop);

      await expectLater(
        fetch(server, File('${dir.path}/a.part')),
        throwsA(
          isA<DownloadException>().having(
            (e) => e.message,
            'message',
            contains('would not let this device'),
          ),
        ),
      );
    });

    test('stops on request and keeps what it has', () async {
      final server = _FileServer(_bytes(2 * 1024 * 1024))
        ..pace = const Duration(milliseconds: 5);
      await server.start();
      addTearDown(server.stop);

      final file = File('${dir.path}/a.part');
      var stop = false;
      final run = engine.fetch(
        server.url,
        file,
        cancelled: () => stop,
        onProgress: (received, _) {
          if (received > 200 * 1024) stop = true;
        },
      );
      await expectLater(run, throwsA(isA<DownloadCancelled>()));
      expect(file.lengthSync(), greaterThan(0));
      expect(file.lengthSync(), lessThan(2 * 1024 * 1024));
    });

    test('says where it could not reach', () async {
      final server = _FileServer(_bytes(10));
      await server.start();
      final url = server.url;
      await server.stop();

      await expectLater(
        engine.fetch(
          url,
          File('${dir.path}/a.part'),
          cancelled: () => false,
          onProgress: (_, _) {},
        ),
        throwsA(isA<DownloadException>()),
      );
    });
  });

  group('controller', () {
    late AppSettingsStore store;
    var boxes = 0;

    setUp(() async {
      Hive.init(dir.path);
      store = AppSettingsStore.withBox(
        await Hive.openBox<dynamic>('d${boxes++}'),
      );
      addTearDown(Hive.close);
    });

    /// [servers] maps a rating key to the server that serves it.
    ProviderContainer container(Map<String, _FileServer> servers) {
      final c = ProviderContainer(
        overrides: [
          appSettingsStoreProvider.overrideWithValue(store),
          downloadsDirectoryProvider.overrideWith((ref) async {
            final d = Directory('${dir.path}/downloads')..createSync();
            return d;
          }),
          downloadSourceResolverProvider.overrideWithValue((
            serverId,
            ratingKey,
          ) async {
            final s = servers[ratingKey]!;
            return PlexDownloadSource(
              // A token in the URL, as the real one has. It must never reach
              // the stored record.
              url: '${s.url}?X-Plex-Token=secret-token',
              title: 'Film $ratingKey',
              duration: const Duration(minutes: 90),
              extension: 'mkv',
              isEpisode: false,
              sizeBytes: s.bytes.length,
              posterPath: '/library/metadata/$ratingKey/thumb/1',
            );
          }),
        ],
      );
      addTearDown(c.dispose);
      // Keeps the notifier alive, as a screen watching it would.
      c.listen(downloadsProvider, (_, _) {});
      return c;
    }

    Future<void> until(bool Function() test, {int seconds = 10}) async {
      final end = DateTime.now().add(Duration(seconds: seconds));
      while (!test()) {
        if (DateTime.now().isAfter(end)) fail('timed out waiting');
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    DownloadRecord rec(ProviderContainer c, String key) => c
        .read(downloadsProvider)
        .firstWhere((r) => r.ratingKey == key);

    test('downloads a file and makes it playable', () async {
      final server = _FileServer(_bytes(150 * 1024));
      await server.start();
      addTearDown(server.stop);
      final c = container({'1': server});

      await c
          .read(downloadsProvider.notifier)
          .enqueue(serverId: 'srv', ratingKey: '1', title: 'Film');
      await until(() => rec(c, '1').isComplete);

      final r = rec(c, '1');
      expect(r.title, 'Film 1'); // the server's title replaces the placeholder
      expect(r.totalBytes, 150 * 1024);
      expect(r.fraction, 1.0);
      final file = (await c.read(downloadsProvider.notifier).fileFor(
        'srv',
        '1',
      ))!;
      expect(file.readAsBytesSync(), server.bytes);
      expect(file.path, endsWith('.mkv'));
      expect(File('${file.path}.part').existsSync(), isFalse);
    });

    test('never stores the token', () async {
      final server = _FileServer(_bytes(40 * 1024));
      await server.start();
      addTearDown(server.stop);
      final c = container({'1': server});

      await c
          .read(downloadsProvider.notifier)
          .enqueue(serverId: 'srv', ratingKey: '1', title: 'Film');
      await until(() => rec(c, '1').isComplete);

      final stored = store.getString('downloads.items')!;
      expect(stored, isNot(contains('secret-token')));
      expect(stored, isNot(contains('X-Plex-Token')));
      expect(stored, isNot(contains('http')));
    });

    test('runs one at a time, in order', () async {
      final slow = _FileServer(_bytes(1024 * 1024))
        ..pace = const Duration(milliseconds: 15);
      final quick = _FileServer(_bytes(20 * 1024));
      await slow.start();
      await quick.start();
      addTearDown(slow.stop);
      addTearDown(quick.stop);
      final c = container({'1': slow, '2': quick});
      final n = c.read(downloadsProvider.notifier);

      await n.enqueue(serverId: 'srv', ratingKey: '1', title: 'A');
      await n.enqueue(serverId: 'srv', ratingKey: '2', title: 'B');
      await until(() => rec(c, '1').state == DownloadState.downloading);

      // The second waits its turn, and has not touched the network.
      expect(rec(c, '2').state, DownloadState.queued);
      expect(quick.requests, isEmpty);

      await until(() => rec(c, '2').isComplete);
      expect(rec(c, '1').isComplete, isTrue);
    });

    test('pauses, then resumes into a byte-identical file', () async {
      final server = _FileServer(_bytes(1024 * 1024))
        ..pace = const Duration(milliseconds: 10);
      await server.start();
      addTearDown(server.stop);
      final c = container({'1': server});
      final n = c.read(downloadsProvider.notifier);

      await n.enqueue(serverId: 'srv', ratingKey: '1', title: 'Film');
      await until(() => rec(c, '1').receivedBytes > 100 * 1024);
      await n.pause('srv', '1');
      await until(() => rec(c, '1').state == DownloadState.paused);

      final partial = rec(c, '1').receivedBytes;
      expect(partial, greaterThan(0));
      expect(partial, lessThan(1024 * 1024));

      server.pace = Duration.zero;
      await n.resume('srv', '1');
      await until(() => rec(c, '1').isComplete);

      // It asked for the rest, not the whole file again.
      expect(server.requests.last, startsWith('bytes='));
      final file = (await n.fileFor('srv', '1'))!;
      expect(file.readAsBytesSync(), server.bytes);
    });

    test('removing a running download stops it and deletes the file', () async {
      final server = _FileServer(_bytes(2 * 1024 * 1024))
        ..pace = const Duration(milliseconds: 10);
      await server.start();
      addTearDown(server.stop);
      final c = container({'1': server});
      final n = c.read(downloadsProvider.notifier);

      await n.enqueue(serverId: 'srv', ratingKey: '1', title: 'Film');
      await until(() => rec(c, '1').receivedBytes > 100 * 1024);
      await n.remove('srv', '1');
      await until(() => c.read(downloadsProvider).isEmpty);

      expect(Directory('${dir.path}/downloads').listSync(), isEmpty);
      expect(DownloadStore(store).load(), isEmpty);
    });

    test('removing a finished download deletes the file', () async {
      final server = _FileServer(_bytes(30 * 1024));
      await server.start();
      addTearDown(server.stop);
      final c = container({'1': server});
      final n = c.read(downloadsProvider.notifier);

      await n.enqueue(serverId: 'srv', ratingKey: '1', title: 'Film');
      await until(() => rec(c, '1').isComplete);
      await n.remove('srv', '1');

      expect(c.read(downloadsProvider), isEmpty);
      expect(Directory('${dir.path}/downloads').listSync(), isEmpty);
      expect(await n.fileFor('srv', '1'), isNull);
    });

    test('a refusal fails with a reason, and a retry can succeed', () async {
      final server = _FileServer(_bytes(30 * 1024))..refuseWith = 403;
      await server.start();
      addTearDown(server.stop);
      final c = container({'1': server});
      final n = c.read(downloadsProvider.notifier);

      await n.enqueue(serverId: 'srv', ratingKey: '1', title: 'Film');
      await until(() => rec(c, '1').state == DownloadState.failed);
      expect(rec(c, '1').error, contains('would not let this device'));

      server.refuseWith = null;
      await n.enqueue(serverId: 'srv', ratingKey: '1', title: 'Film');
      await until(() => rec(c, '1').isComplete);
      expect(rec(c, '1').error, isNull);
    });

    test('a file of the wrong size is thrown away, not kept as complete', () async {
      final server = _FileServer(_bytes(40 * 1024));
      await server.start();
      addTearDown(server.stop);

      final c = ProviderContainer(
        overrides: [
          appSettingsStoreProvider.overrideWithValue(store),
          downloadsDirectoryProvider.overrideWith((ref) async {
            return Directory('${dir.path}/downloads')..createSync();
          }),
          downloadSourceResolverProvider.overrideWithValue(
            (_, _) async => PlexDownloadSource(
              url: server.url.toString(),
              title: 'Film',
              duration: Duration.zero,
              extension: 'mkv',
              isEpisode: false,
              // Plex "said" a different size from what was served.
              sizeBytes: 99999,
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      c.listen(downloadsProvider, (_, _) {});

      await c
          .read(downloadsProvider.notifier)
          .enqueue(serverId: 'srv', ratingKey: '1', title: 'Film');
      await until(
        () => c.read(downloadsProvider).single.state == DownloadState.failed,
      );

      expect(c.read(downloadsProvider).single.error, contains('did not match'));
      expect(Directory('${dir.path}/downloads').listSync(), isEmpty);
      expect(
        await c.read(downloadsProvider.notifier).fileFor('srv', '1'),
        isNull,
      );
    });

    test('what was running when the app closed comes back paused', () async {
      await store.setString(
        'downloads.items',
        '[{"serverId":"srv","ratingKey":"1","title":"A","state":"downloading",'
        '"receivedBytes":5,"addedAt":"2026-10-09T00:00:00Z"},'
        '{"serverId":"srv","ratingKey":"2","title":"B","state":"queued",'
        '"addedAt":"2026-10-09T00:00:00Z"},'
        '{"serverId":"srv","ratingKey":"3","title":"C","state":"complete",'
        '"addedAt":"2026-10-09T00:00:00Z"}]',
      );
      final c = container({});
      final states = {
        for (final r in c.read(downloadsProvider)) r.ratingKey: r.state,
      };
      expect(states, {
        '1': DownloadState.paused,
        '2': DownloadState.paused,
        '3': DownloadState.complete,
      });
    });

    test('a damaged store reads as nothing downloaded', () async {
      await store.setString('downloads.items', 'not json');
      expect(container({}).read(downloadsProvider), isEmpty);
    });

    test('bytes used counts partial files too', () async {
      await store.setString(
        'downloads.items',
        '[{"serverId":"s","ratingKey":"1","title":"A","state":"complete",'
        '"totalBytes":1000,"receivedBytes":1000,"addedAt":"2026-10-09T00:00:00Z"},'
        '{"serverId":"s","ratingKey":"2","title":"B","state":"paused",'
        '"totalBytes":5000,"receivedBytes":300,"addedAt":"2026-10-09T00:00:00Z"}]',
      );
      expect(container({}).read(downloadsProvider.notifier).bytesUsed, 1300);
    });
  });
}
