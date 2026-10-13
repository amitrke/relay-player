import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/platform/device_kind.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/features/library/library_screen.dart';
import 'package:relay_player/features/library/library_sort.dart';
import 'package:relay_player/features/library/library_tab.dart';
import 'package:relay_player/features/metadata/tmdb_controller.dart';

/// In memory: the real ones write the settings box.
class _Sort extends LibrarySortController {
  _Sort(this._initial);

  final LibrarySort _initial;

  @override
  LibrarySort build() => _initial;

  @override
  Future<void> set(LibrarySort sort) async => state = sort;
}

class _Unwatched extends UnwatchedOnlyController {
  @override
  bool build() => false;

  @override
  Future<void> set(bool value) async => state = value;
}

class _Key extends TmdbKeyController {
  _Key(this._key);

  final String? _key;

  @override
  Future<String?> build() async => _key;
}

/// The sort sheet on a television. A 1080p TV is 960 x 540 dp (architecture.md
/// section 11), and a bottom sheet is capped at about half of that unless it is
/// told otherwise: with a fourth option added the sheet overflowed by 83 px on
/// the Google TV emulator, which in a release build clips the Unwatched row
/// without a word.
void main() {
  setUp(() => DeviceKind.debugSetTelevision(true));
  tearDown(() => DeviceKind.debugSetTelevision(false));

  Future<ProviderContainer> open(
    WidgetTester tester, {
    String? key,
    LibraryTab tab = LibraryTab.movies,
    LibrarySort sort = LibrarySort.title,
  }) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final c = ProviderContainer(
      overrides: [
        librarySortProvider.overrideWith(() => _Sort(sort)),
        libraryUnwatchedOnlyProvider.overrideWith(_Unwatched.new),
        tmdbKeyProvider.overrideWith(() => _Key(key)),
      ],
    );
    addTearDown(c.dispose);
    await c.read(tmdbKeyProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          builder: (context, child) => RelayTheme(
            tokens: RelayPalettes.midnight,
            palette: RelayPalette.midnight,
            child: child!,
          ),
          home: Scaffold(
            body: Center(child: LibrarySortButton(tab: tab)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(LibrarySortButton));
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets('fits a 540 dp TV with every option and the Unwatched row', (
    tester,
  ) async {
    await open(tester, key: 'key');

    // The overflow is a framework error, not a failed finder, so it has to be
    // asked for.
    expect(tester.takeException(), isNull);

    // Inside the sheet: "Title" is also the label on the button that opened it.
    Finder inSheet(String label) => find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text(label),
    );
    for (final label in ['Title', 'Recently added', 'Year', 'Release date']) {
      expect(inSheet(label), findsOneWidget, reason: label);
    }
    final unwatched = find.textContaining('Unwatched only');
    expect(unwatched, findsOneWidget);
    // On screen, not just in the tree.
    expect(tester.getRect(unwatched).bottom, lessThanOrEqualTo(540));
  });

  testWidgets('Release date is offered only once a TMDB key is saved', (
    tester,
  ) async {
    await open(tester, key: null);
    expect(tester.takeException(), isNull);
    expect(find.text('Release date'), findsNothing);
    // Control: the other options are there, so the sheet did open.
    expect(find.text('Year'), findsOneWidget);
  });

  testWidgets('choosing Release date sorts by it', (tester) async {
    final c = await open(tester, key: 'key');
    await tester.tap(find.text('Release date'));
    await tester.pumpAndSettle();
    expect(c.read(librarySortProvider), LibrarySort.releaseDate);
  });

  testWidgets('Series has no Unwatched row and still fits', (tester) async {
    await open(tester, key: 'key', tab: LibraryTab.series);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Unwatched only'), findsNothing);
    expect(find.text('Release date'), findsOneWidget);
  });
}
