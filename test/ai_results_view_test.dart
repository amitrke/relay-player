import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/data/ai/ai_provider.dart';
import 'package:relay_player/data/ai/text_client.dart';
import 'package:relay_player/data/local/history_store.dart';
import 'package:relay_player/domain/models/catalog_item.dart';
import 'package:relay_player/features/ai/ai_controller.dart';
import 'package:relay_player/features/favorites_history/favorites_controller.dart';
import 'package:relay_player/features/favorites_history/history_controller.dart';
import 'package:relay_player/features/search/ai_results_view.dart';

CatalogItem _film(String title) => CatalogItem(
  source: CatalogSource.plex,
  sourceId: 'server',
  kind: CatalogKind.movie,
  id: title,
  title: title,
);

class _NoFavourites extends FavoritesController {
  @override
  Set<String> build() => const {};
}

class _NoHistory extends HistoryController {
  @override
  List<HistoryItem> build() => const [];
}

class _Setup extends AiSetupController {
  @override
  Future<AiSetup?> build() async => const AiSetup(
    AiProviderConfig(
      preset: AiPreset.openRouter,
      baseUrl: 'https://openrouter.ai/api/v1',
      model: 'm',
    ),
    null,
  );
}

/// The search as the view sees it, pushed by hand.
void main() {
  late StreamController<AiSearchProgress> search;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    search = StreamController<AiSearchProgress>();
    addTearDown(search.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiSetupProvider.overrideWith(_Setup.new),
          aiSearchProvider.overrideWith((ref, query) => search.stream),
          favoritesProvider.overrideWith(_NoFavourites.new),
          historyProvider.overrideWith(_NoHistory.new),
        ],
        child: MaterialApp(
          builder: (context, child) => RelayTheme(
            tokens: RelayPalettes.midnight,
            palette: RelayPalette.midnight,
            child: child!,
          ),
          home: const Scaffold(body: AiResultsView(query: 'James bond movies')),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> push(WidgetTester tester, AiSearchProgress p) async {
    search.add(p);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('asks first, before anything has come back', (tester) async {
    await pump(tester);
    expect(find.text('Asking OpenRouter...'), findsOneWidget);
  });

  testWidgets('says how far it has got while nothing has been found', (
    tester,
  ) async {
    await pump(tester);
    await push(
      tester,
      const AiSearchProgress(
        total: 3194,
        covered: 3194,
        searched: 1200,
        parts: 6,
      ),
    );
    expect(
      find.text('Searching your library... 1,200 of 3,194 titles'),
      findsOneWidget,
    );
    // And it is not claiming a result or an empty answer yet.
    expect(find.textContaining('did not find'), findsNothing);
  });

  testWidgets('shows picks as they arrive, and says it is still going', (
    tester,
  ) async {
    await pump(tester);
    await push(
      tester,
      AiSearchProgress(
        items: [_film('Die Another Day')],
        total: 3194,
        covered: 3194,
        searched: 1200,
        parts: 6,
      ),
    );
    expect(find.text('Die Another Day'), findsOneWidget);
    expect(
      find.text('Picked by OpenRouter for "James bond movies"'),
      findsOneWidget,
    );
    expect(find.text('Still searching: 1,200 of 3,194 titles'), findsOneWidget);

    // More arrive: what was there stays, and the count moves.
    await push(
      tester,
      AiSearchProgress(
        items: [_film('Die Another Day'), _film('Skyfall')],
        total: 3194,
        covered: 3194,
        searched: 2400,
        parts: 6,
      ),
    );
    expect(find.text('Die Another Day'), findsOneWidget);
    expect(find.text('Skyfall'), findsOneWidget);
    expect(find.text('Still searching: 2,400 of 3,194 titles'), findsOneWidget);
  });

  testWidgets('when finished the progress line goes away', (tester) async {
    await pump(tester);
    await push(
      tester,
      AiSearchProgress(
        items: [_film('Skyfall')],
        total: 600,
        covered: 600,
        searched: 600,
        parts: 1,
        done: true,
      ),
    );
    expect(find.text('Skyfall'), findsOneWidget);
    expect(find.textContaining('Still searching'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // Nothing failed, so nothing to search again.
    expect(find.text('Search again'), findsNothing);
  });

  testWidgets('a cut library says how much of it was searched', (tester) async {
    await pump(tester);
    await push(
      tester,
      AiSearchProgress(
        items: [_film('Skyfall')],
        total: 6000,
        covered: 4800,
        searched: 4800,
        parts: 8,
        done: true,
      ),
    );
    expect(
      find.text('Searched the first 4,800 of 6,000 titles'),
      findsOneWidget,
    );
  });

  testWidgets('nothing found says how much was searched', (tester) async {
    await pump(tester);
    await push(
      tester,
      const AiSearchProgress(
        total: 1500,
        covered: 1500,
        searched: 1500,
        parts: 3,
        done: true,
      ),
    );
    expect(
      find.textContaining('did not find anything in 1,500 titles'),
      findsOneWidget,
    );
  });

  testWidgets('nothing found in a cut library says it was only part', (
    tester,
  ) async {
    await pump(tester);
    await push(
      tester,
      const AiSearchProgress(
        total: 6000,
        covered: 4800,
        searched: 4800,
        parts: 8,
        done: true,
      ),
    );
    expect(
      find.textContaining('in the first 4,800 of 6,000 titles'),
      findsOneWidget,
    );
  });

  testWidgets('parts that failed are said, with a way to try again', (
    tester,
  ) async {
    await pump(tester);
    await push(
      tester,
      const AiSearchProgress(
        total: 1500,
        covered: 1500,
        searched: 1500,
        parts: 3,
        partsFailed: 2,
        done: true,
      ),
    );
    expect(
      find.textContaining('2 of 3 parts could not be searched'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets(
    'a short answer with failed parts is not passed off as complete',
    (tester) async {
      await pump(tester);
      await push(
        tester,
        AiSearchProgress(
          items: [_film('Skyfall')],
          total: 1500,
          covered: 1500,
          searched: 1500,
          parts: 3,
          partsFailed: 1,
          done: true,
        ),
      );
      expect(find.text('Skyfall'), findsOneWidget);
      expect(
        find.textContaining('1 of 3 parts could not be searched'),
        findsOneWidget,
      );
    },
  );

  testWidgets('an empty library has nothing to search', (tester) async {
    await pump(tester);
    await push(tester, const AiSearchProgress(done: true));
    expect(find.textContaining('nothing in your library'), findsOneWidget);
  });

  testWidgets('a failure is shown with a way to retry', (tester) async {
    await pump(tester);
    search.addError(const AiException('The provider is limiting requests.'));
    await tester.pump();
    await tester.pump();
    expect(find.text('The provider is limiting requests.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
