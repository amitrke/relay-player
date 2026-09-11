import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../domain/models/catalog_item.dart';
import '../accounts/plex_session.dart';
import '../library/poster_grid.dart';

final _queryProvider = NotifierProvider<_QueryController, String>(
  _QueryController.new,
);

class _QueryController extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

/// Search every connected server and merge.
///
/// One unreachable server must not blank the results — it should cost you its
/// own matches, not everyone else's.
final _resultsProvider = FutureProvider<List<CatalogItem>>((ref) async {
  final query = ref.watch(_queryProvider);
  if (query.trim().length < 2) return const [];

  final servers = ref.watch(connectedServersProvider);
  final perServer = await Future.wait(
    servers.map((server) async {
      try {
        final found = await server.service.search(query);
        return [
          for (final i in found) server.service.toCatalogItem(i.metadata),
        ];
      } catch (_) {
        return const <CatalogItem>[];
      }
    }).map((f) => f.timeout(
          const Duration(seconds: 10),
          onTimeout: () => const <CatalogItem>[],
        )),
  );
  return perServer.expand((items) => items).toList();
});

/// Search across the connected sources (§12 screen 8).
///
/// The "Ask" affordance from the Home artboard is deliberately absent: §9.2
/// only shows it once an AI text-generation provider is configured, and none
/// can be yet.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Each keystroke is a round trip to the server, so wait for a pause. Without
  /// this, typing "godfather" fires ten searches and the answers can land out
  /// of order.
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(_queryProvider.notifier).update(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final query = ref.watch(_queryProvider);
    final results = ref.watch(_resultsProvider);

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding:
                  RelayLayout.pagePadding(f).copyWith(top: 16, bottom: 8),
              child: TextField(
                controller: _controller,
                onChanged: _onChanged,
                autocorrect: false,
                textInputAction: TextInputAction.search,
                style: TextStyle(color: t.ink),
                decoration: InputDecoration(
                  hintText: 'Search your sources',
                  hintStyle: TextStyle(color: t.inkDim),
                  prefixIcon: Icon(Icons.search, color: t.inkDim, size: 20),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Icons.close, color: t.inkDim, size: 18),
                          onPressed: () {
                            _controller.clear();
                            _debounce?.cancel();
                            ref.read(_queryProvider.notifier).update('');
                          },
                        ),
                  filled: true,
                  fillColor: t.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: t.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: t.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: t.accent),
                  ),
                ),
              ),
            ),
            Expanded(
              child: switch (query.trim().length) {
                0 => const LibraryEmptyState(
                    icon: Icons.search,
                    message: 'Search movies and series across your server.',
                  ),
                1 => const LibraryEmptyState(
                    icon: Icons.search,
                    message: 'Keep typing…',
                  ),
                _ => results.when(
                    loading: () =>
                        Center(child: CircularProgressIndicator(color: t.accent)),
                    error: (e, _) => LibraryEmptyState(
                      icon: Icons.cloud_off_outlined,
                      message: '$e',
                      onRetry: () => ref.invalidate(_resultsProvider),
                    ),
                    data: (list) => list.isEmpty
                        ? LibraryEmptyState(
                            icon: Icons.search_off,
                            message: 'Nothing matching "$query".',
                          )
                        : PosterGrid(items: list),
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}
