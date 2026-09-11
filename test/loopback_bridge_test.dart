import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/filesystem/loopback_bridge.dart';

/// A deterministic source: byte *i* has value `i % 251`.
///
/// The prime modulus means any wrong offset produces a visibly wrong byte, so a
/// range served from the wrong place fails loudly rather than looking plausible.
class _FakeSource implements BridgeSource {
  _FakeSource(this.length);

  @override
  final int length;

  @override
  String get name => 'fake.mp4';

  @override
  String get contentType => 'video/mp4';

  int reads = 0;

  @override
  Future<Uint8List> read(int start, int count) async {
    reads++;
    final end = (start + count) > length ? length : start + count;
    return Uint8List.fromList([
      for (var i = start; i < end; i++) i % 251,
    ]);
  }
}

void main() {
  late LoopbackBridge bridge;
  late _FakeSource source;
  late String url;
  late HttpClient client;

  setUp(() async {
    source = _FakeSource(1000000);
    bridge = LoopbackBridge();
    url = await bridge.serve(source);
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await bridge.stop();
  });

  Future<HttpClientResponse> get(String? range, {String method = 'GET'}) async {
    final request = await client.openUrl(method, Uri.parse(url));
    if (range != null) request.headers.set('range', range);
    return request.close();
  }

  test('serves the whole file and advertises range support', () async {
    final response = await get(null);

    expect(response.statusCode, 200);
    expect(response.headers.value('accept-ranges'), 'bytes');
    expect(response.headers.value('content-length'), '${source.length}');

    final bytes = await response.fold<List<int>>([], (a, b) => a..addAll(b));
    expect(bytes.length, source.length);
    expect(bytes[0], 0);
    expect(bytes[300], 300 % 251);
  });

  test('answers an open-ended range with 206 and the right bytes', () async {
    // The form libmpv actually sends first — Phase 0 observed `bytes=0-`.
    final response = await get('bytes=5963-');

    expect(response.statusCode, 206);
    expect(
      response.headers.value('content-range'),
      'bytes 5963-${source.length - 1}/${source.length}',
    );

    final bytes = await response.fold<List<int>>([], (a, b) => a..addAll(b));
    expect(bytes.length, source.length - 5963);
    expect(bytes.first, 5963 % 251);
  });

  test('answers a closed range with exactly that many bytes', () async {
    final response = await get('bytes=100-199');

    expect(response.statusCode, 206);
    expect(response.headers.value('content-length'), '100');
    expect(
      response.headers.value('content-range'),
      'bytes 100-199/${source.length}',
    );

    final bytes = await response.fold<List<int>>([], (a, b) => a..addAll(b));
    expect(bytes.length, 100);
    expect(bytes.first, 100 % 251);
    expect(bytes.last, 199 % 251);
  });

  test('answers a suffix range, which is how a container index is read',
      () async {
    // Phase 0 watched libmpv jump to the last 16 KB to read the MKV/MP4 index
    // before playing. This is the request that a forward-only source fails.
    final response = await get('bytes=-16384');

    expect(response.statusCode, 206);
    final start = source.length - 16384;
    expect(
      response.headers.value('content-range'),
      'bytes $start-${source.length - 1}/${source.length}',
    );

    final bytes = await response.fold<List<int>>([], (a, b) => a..addAll(b));
    expect(bytes.length, 16384);
    expect(bytes.first, start % 251);
  });

  test('rejects a range past the end rather than serving nothing', () async {
    final response = await get('bytes=${source.length + 10}-');

    expect(response.statusCode, HttpStatus.requestedRangeNotSatisfiable);
    expect(response.headers.value('content-range'), 'bytes */${source.length}');
  });

  test('HEAD reports length without reading the source', () async {
    source.reads = 0;
    final response = await get(null, method: 'HEAD');

    expect(response.statusCode, 200);
    expect(response.headers.value('content-length'), '${source.length}');
    expect(response.headers.value('accept-ranges'), 'bytes');
    expect(source.reads, 0);
  });

  test('refuses a wrong path, so another app cannot read the file', () async {
    final wrong = Uri.parse(url).replace(path: '/guessed');
    final response = await (await client.getUrl(wrong)).close();

    expect(response.statusCode, 403);
  });

  test('stop() releases the port', () async {
    await bridge.stop();
    await expectLater(get(null), throwsA(isA<SocketException>()));
  });
}
