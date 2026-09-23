import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/theme/relay_widgets.dart';
import 'package:relay_player/data/local/history_store.dart';
import 'package:relay_player/data/plex/plex_service.dart';
import 'package:relay_player/data/plex/plex_session_store.dart';
import 'package:relay_player/domain/models/catalog_item.dart';
import 'package:relay_player/features/accounts/plex_session.dart';
import 'package:relay_player/features/favorites_history/history_controller.dart';
import 'package:relay_player/features/favorites_history/resume_entries.dart';
import 'package:relay_player/features/favorites_history/watch_actions.dart';
import 'package:relay_player/features/favorites_history/watch_state.dart';
import 'package:relay_player/features/library/library_sort.dart';

/// Mark watched / unwatched, the long press that opens it, and "Unwatched
/// only". Plex itself is faked: whether a real server accepts the scrobble
/// from a shared (not owned) server is a check against a real account.
class _Plex extends PlexService {
  _Plex({this.fail = false}) : super(clientId: 'test');

  final bool fail;
  final calls = <String>[];

  @override
  Future<void> setWatched(String ratingKey, {required bool watched}) async {
    if (fail) throw Exception('offline');
    calls.add('${watched ? 'watched' : 'unwatched'} $ratingKey');
  }
}

class _History extends HistoryController {
  _History(this.initial);

  final List<HistoryItem> initial;
  final removed = <String>[];

  @override
  List<HistoryItem> build() => initial;

  @override
  Future<void> remove(String key) async {
    removed.add(key);
    state = [for (final h in state) if (h.key != key) h];
  }
}

CatalogItem _film(String id, {int? views}) => CatalogItem(
      source: CatalogSource.plex,
      sourceId: 'server',
      kind: CatalogKind.movie,
      id: id,
      title: id,
      viewCount: views,
    );

void main() {
  group('long press on a remote', () {
    Future<(List<String>, FocusNode)> pump(WidgetTester tester,
        {bool withLongPress = true}) async {
      final events = <String>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(MaterialApp(
        home: RelayFocusable(
          focusNode: node,
          onTap: () => events.add('tap'),
          onLongPress: withLongPress ? () => events.add('long') : null,
          builder: (_, _) => const SizedBox(width: 50, height: 50),
        ),
      ));
      node.requestFocus();
      await tester.pump();
      return (events, node);
    }

    testWidgets('a held centre button opens the menu and does not also tap',
        (tester) async {
      final (events, _) = await pump(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      expect(events, ['long']);
    });

    testWidgets('a short press taps, on release', (tester) async {
      final (events, _) = await pump(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      expect(events, isEmpty, reason: 'cannot tell a press from a hold yet');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      expect(events, ['tap']);
    });

    testWidgets('without a long-press action, a press still taps on key down',
        (tester) async {
      final (events, _) = await pump(tester, withLongPress: false);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      expect(events, ['tap']);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      expect(events, ['tap']);
    });
  });

  group('WatchOverrides.mark', () {
    ProviderContainer container(_Plex plex, _History history) {
      final c = ProviderContainer(overrides: [
        connectedServersProvider.overrideWithValue([
          ConnectedServer(
            stored: const StoredPlexServer(
              id: 'server',
              name: 'server',
              baseUrl: 'http://<lan-ip>:32400',
              token: '<redacted>',
            ),
            service: plex,
          ),
        ]),
        historyProvider.overrideWith(() => history),
        plexOnDeckProvider.overrideWith((_) async => const []),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('tells Plex, holds the mark, and clears the local position',
        () async {
      final plex = _Plex();
      final history = _History([
        HistoryItem(
          kind: PlaybackKind.plex,
          sourceId: 'server',
          itemId: '42',
          title: 't',
          position: const Duration(minutes: 30),
          duration: const Duration(minutes: 100),
          lastWatchedAt: DateTime.utc(2026, 9, 1),
        ),
      ]);
      final c = container(plex, history);
      c.read(historyProvider);

      await c
          .read(watchOverridesProvider.notifier)
          .mark(serverId: 'server', ratingKey: '42', watched: true);

      expect(plex.calls, ['watched 42']);
      expect(c.read(watchOverridesProvider), {'plex:server:42': true});
      expect(history.removed, ['plex:server:42'],
          reason: 'a watched title has nothing left to resume');
    });

    test('a refused mark changes nothing on screen', () async {
      final c = container(_Plex(fail: true), _History(const []));
      await expectLater(
        c
            .read(watchOverridesProvider.notifier)
            .mark(serverId: 'server', ratingKey: '42', watched: true),
        throwsException,
      );
      expect(c.read(watchOverridesProvider), isEmpty,
          reason: 'no tick the server does not agree with');
    });
  });

  group('unwatched only', () {
    test('drops watched films, keeps unwatched ones and every show', () {
      final show = CatalogItem(
        source: CatalogSource.plex,
        sourceId: 'server',
        kind: CatalogKind.show,
        id: 'show',
        title: 'show',
        viewCount: 1,
      );
      final kept = unwatchedOnly(
        [_film('seen', views: 1), _film('new'), show],
        history: const {},
        overrides: const {},
      );
      expect(kept.map((i) => i.id), ['new', 'show']);
    });

    test('a mark made this session applies straight away', () {
      final kept = unwatchedOnly(
        [_film('seen', views: 1), _film('new')],
        history: const {},
        overrides: {'plex:server:seen': false, 'plex:server:new': true},
      );
      expect(kept.map((i) => i.id), ['seen']);
    });

    test('an override beats Plex and local history', () {
      expect(
          WatchState.resolve(override: false, plexViewCount: 3).watched, false);
      expect(WatchState.resolve(override: true).watched, true);
    });
  });
}
