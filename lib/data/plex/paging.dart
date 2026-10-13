import 'dart:math';

/// Reads everything a paged endpoint holds, in order.
///
/// [page] fetches `size` records starting at `start` and says how many exist in
/// all. The first page is fetched alone, because it is what says how many more
/// there are; the rest are then fetched [concurrency] at a time, which is what
/// keeps a library of thousands from costing thousands of round trips in a row.
///
/// Stops at [maxItems] rather than trusting the server's total: a library that
/// claims more than that is either enormous or lying, and either way the answer
/// is a bounded list, not an out-of-memory.
///
/// If any page fails, the whole read fails. A list with a hole in the middle is
/// worse than no list, because nothing shows that something is missing: the
/// caller is expected to keep what it had.
Future<List<T>> readAllPages<T>(
  Future<({int total, List<T> items})> Function(int start, int size) page, {
  int pageSize = 300,
  int maxItems = 20000,
  int concurrency = 3,
}) async {
  final first = await page(0, pageSize);
  final wanted = min(first.total, maxItems);
  if (first.items.length >= wanted || first.items.isEmpty) {
    return first.items.take(wanted).toList();
  }

  // Each later page lands in its own slot, so they can finish in any order and
  // still be joined in the order the server sorted them.
  final starts = [
    for (var s = first.items.length; s < wanted; s += pageSize) s,
  ];
  final pages = List<List<T>?>.filled(starts.length, null);

  var next = 0;
  Future<void> worker() async {
    while (next < starts.length) {
      final i = next++;
      final size = min(pageSize, wanted - starts[i]);
      pages[i] = (await page(starts[i], size)).items;
    }
  }

  await Future.wait([for (var w = 0; w < concurrency; w++) worker()]);

  return [...first.items, for (final p in pages) ...?p].take(wanted).toList();
}
