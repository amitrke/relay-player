import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/plex/paging.dart';

/// A server holding [total] numbered records, that counts how it is asked.
class _Server {
  _Server(this.total, {this.delayFor});

  final int total;

  /// Lets a test make particular pages slow, so they finish out of order.
  final Duration Function(int start)? delayFor;

  final calls = <(int, int)>[];
  var inFlight = 0;
  var peak = 0;
  int? failAtStart;

  Future<({int total, List<int> items})> page(int start, int size) async {
    calls.add((start, size));
    inFlight++;
    if (inFlight > peak) peak = inFlight;
    try {
      final delay = delayFor?.call(start);
      if (delay != null) await Future<void>.delayed(delay);
      if (failAtStart == start) throw StateError('page at $start failed');
      final end = (start + size).clamp(0, total);
      return (total: total, items: [for (var i = start; i < end; i++) i]);
    } finally {
      inFlight--;
    }
  }
}

void main() {
  test('a short list is one request', () async {
    final server = _Server(40);
    final all = await readAllPages(server.page, pageSize: 300);
    expect(all, [for (var i = 0; i < 40; i++) i]);
    expect(server.calls, [(0, 300)]);
  });

  test(
    'every record comes back, in the order the server sorted them',
    () async {
      final server = _Server(1000);
      final all = await readAllPages(server.page, pageSize: 300);
      expect(all, hasLength(1000));
      expect(all, [for (var i = 0; i < 1000; i++) i]);
    },
  );

  test('pages that finish out of order are still joined in order', () async {
    // Earlier pages are slower, so later ones arrive first.
    final server = _Server(
      900,
      delayFor: (start) => Duration(milliseconds: 90 - start ~/ 10),
    );
    final all = await readAllPages(server.page, pageSize: 100);
    expect(all, [for (var i = 0; i < 900; i++) i]);
  });

  test('an exact multiple of the page size asks for no extra page', () async {
    final server = _Server(600);
    final all = await readAllPages(server.page, pageSize: 300);
    expect(all, hasLength(600));
    expect(server.calls.map((c) => c.$1).toList()..sort(), [0, 300]);
  });

  test('the last page asks for only what is left', () async {
    final server = _Server(650);
    await readAllPages(server.page, pageSize: 300);
    final byStart = {for (final c in server.calls) c.$1: c.$2};
    expect(byStart, {0: 300, 300: 300, 600: 50});
  });

  test('stops at the cap and does not fetch past it', () async {
    final server = _Server(50000);
    final all = await readAllPages(server.page, pageSize: 300, maxItems: 700);
    expect(all, hasLength(700));
    expect(all.last, 699);
    // 0-299, 300-599, and 600-699: three requests, not 167.
    expect(server.calls, hasLength(3));
    expect(server.calls.every((c) => c.$1 + c.$2 <= 700), isTrue);
  });

  test('never has more requests in flight than it was allowed', () async {
    final server = _Server(
      3000,
      delayFor: (_) => const Duration(milliseconds: 15),
    );
    await readAllPages(server.page, pageSize: 100, concurrency: 3);
    expect(server.peak, lessThanOrEqualTo(3));
    // And it did use the concurrency, or the test above proves nothing.
    expect(server.peak, greaterThan(1));
  });

  test('an empty library is an empty list', () async {
    final server = _Server(0);
    expect(await readAllPages(server.page), isEmpty);
    expect(server.calls, hasLength(1));
  });

  test(
    'a page that fails fails the whole read, not a list with a hole',
    () async {
      final server = _Server(1000)..failAtStart = 600;
      await expectLater(
        readAllPages(server.page, pageSize: 300),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'a server that claims more than it sends stops at what it sent',
    () async {
      // total says 1000 but the first page is empty: nothing to loop on.
      final all = await readAllPages<int>(
        (start, size) async => (total: 1000, items: <int>[]),
      );
      expect(all, isEmpty);
    },
  );
}
