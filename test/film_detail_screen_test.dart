import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relay_player/core/platform/device_kind.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/data/downloads/download_record.dart';
import 'package:relay_player/data/local/history_store.dart';
import 'package:relay_player/data/plex/plex_service.dart';
import 'package:relay_player/domain/models/catalog_item.dart';
import 'package:relay_player/domain/models/media_server.dart';
import 'package:relay_player/features/accounts/media_servers.dart';
import 'package:relay_player/features/downloads/downloads_controller.dart';
import 'package:relay_player/features/favorites_history/favorites_controller.dart';
import 'package:relay_player/features/favorites_history/history_controller.dart';
import 'package:relay_player/features/library/film_detail_screen.dart';

/// A film's page (§12 screen 5, 2026-10-30): what a poster opens instead of
/// the player, which names where it will start and offers to start over.

class _Server extends PlexService {
  _Server(this.film) : super(clientId: 'test', serverId: 'srv');

  final MediaItem film;

  @override
  Future<MediaItem?> item(String id) async => id == film.id ? film : null;
}

class _NoDownloads extends DownloadsController {
  @override
  List<DownloadRecord> build() => const [];
}

class _NoFavourites extends FavoritesController {
  @override
  Set<String> build() => const {};
}

class _NoHistory extends HistoryController {
  @override
  List<HistoryItem> build() => const [];
}

MediaItem _film({Duration? offset}) => MediaItem(
  id: 'f1',
  type: MediaItemType.movie,
  title: 'A Film',
  year: 2009,
  summary: 'The plot.',
  duration: const Duration(minutes: 100),
  viewOffset: offset,
  viewCount: 0,
);

void main() {
  late List<String> pushed;

  Future<void> pump(WidgetTester tester, MediaItem film) async {
    pushed = [];
    final router = GoRouter(
      initialLocation: '/film/srv/f1',
      routes: [
        GoRoute(
          path: '/film/:serverId/:ratingKey',
          builder: (_, s) => FilmDetailScreen(
            serverId: s.pathParameters['serverId']!,
            ratingKey: s.pathParameters['ratingKey']!,
          ),
        ),
        GoRoute(
          path: '/play/:serverId/:ratingKey',
          builder: (_, s) {
            pushed.add(s.uri.toString());
            return const Text('player');
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectedServersProvider.overrideWithValue([
            ConnectedServer(service: _Server(film)),
          ]),
          downloadsProvider.overrideWith(_NoDownloads.new),
          favoritesProvider.overrideWith(_NoFavourites.new),
          historyProvider.overrideWith(_NoHistory.new),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => RelayTheme(
            tokens: RelayPalettes.midnight,
            palette: RelayPalette.midnight,
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('a server film opens its page; a show and a panel film do not', () {
    CatalogItem item(CatalogSource source, CatalogKind kind) => CatalogItem(
      source: source,
      sourceId: 's',
      kind: kind,
      id: 'x',
      title: 't',
    );
    expect(item(CatalogSource.server, CatalogKind.movie).route, '/film/s/x');
    expect(item(CatalogSource.server, CatalogKind.show).route, '/show/s/x');
    expect(item(CatalogSource.xtream, CatalogKind.movie).route, '/vod/s/x');
  });

  testWidgets('not started: Play, with nothing to start over from', (
    tester,
  ) async {
    await pump(tester, _film());
    expect(find.text('A Film'), findsOneWidget);
    expect(find.text('The plot.'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Play from start'), findsNothing);
  });

  testWidgets('part-way: Resume names the time, and has focus on a TV', (
    tester,
  ) async {
    DeviceKind.debugSetTelevision(true);
    addTearDown(() => DeviceKind.debugSetTelevision(false));
    await tester.binding.setSurfaceSize(const Size(960, 540));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pump(tester, _film(offset: const Duration(minutes: 32, seconds: 10)));
    expect(find.text('Resume from 32:10'), findsOneWidget);

    // OK on a remote, without moving first, resumes: focus starts there.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(pushed, ['/play/srv/f1']);
  });

  testWidgets('Play from start asks the player to ignore the position', (
    tester,
  ) async {
    await pump(tester, _film(offset: const Duration(minutes: 32)));
    await tester.tap(find.text('Play from start'));
    await tester.pumpAndSettle();
    expect(pushed, ['/play/srv/f1?start=0']);
  });

  test('the resume time reads as a duration, not a clock', () {
    expect(resumeLabel(const Duration(minutes: 6, seconds: 16)), '6:16');
    expect(
      resumeLabel(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
  });

  testWidgets('fits a phone, with every action reachable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pump(tester, _film(offset: const Duration(minutes: 32)));
    // Rendering at all is the overflow check: an overflow fails the test.
    for (final label in [
      'Resume from 32:00',
      'Play from start',
      'Mark as watched',
      'Download to this device',
      'Add to favourites',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('a film the server no longer has says so', (tester) async {
    await pump(tester, _film().copyWithId('gone'));
    expect(find.textContaining('no longer on the server'), findsOneWidget);
  });
}

extension on MediaItem {
  MediaItem copyWithId(String id) =>
      MediaItem(id: id, type: type, title: title, duration: duration);
}
