import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/xtream/xtream_account_store.dart';
import 'package:relay_player/data/xtream/xtream_client.dart';
import 'package:relay_player/features/accounts/add_source_screen.dart';
import 'package:relay_player/features/advanced_sources/add_xtream_screen.dart';
import 'package:relay_player/features/advanced_sources/xtream_controller.dart';
import 'package:relay_player/features/favorites_history/favorites_controller.dart';
import 'package:relay_player/features/live_tv/live_tv_tab.dart';
import 'package:relay_player/core/theme/theme_controller.dart';
import 'package:relay_player/features/accounts/plex_session.dart';
import 'package:relay_player/features/player/playback_prefs.dart';
import 'package:relay_player/features/settings/settings_screen.dart';

import 'dpad_audit.dart';

class _Accounts extends XtreamAccountsController {
  _Accounts(this._accounts);
  final List<XtreamAccount> _accounts;
  @override
  List<XtreamAccount> build() => _accounts;
}

class _SignedOut extends PlexSessionController {
  @override
  PlexState build() => const PlexState(stage: PlexStage.signedOut);
}

class _Prefs extends PlaybackPrefsController {
  @override
  PlaybackPrefs build() => const PlaybackPrefs();
}

class _NoFavourites extends FavoritesController {
  @override
  Set<String> build() => const {};
}

/// The D-pad rules in [DpadAudit], run on each screen at TV size.
///
/// Placeholder names throughout (CLAUDE.md §1).
void main() {
  const account = XtreamAccount(
    id: 'a',
    name: 'Line',
    host: 'http://panel-host.example.invalid',
    username: 'user',
    liveCategoryIds: ['10', '20'],
    liveCategoryNames: {'10': 'News', '20': 'Sport'},
  );

  final screens = <String, (Widget Function(), List)>{
    'Add a playlist or panel': (() => const AddXtreamScreen(), const []),
    'Add source': (
      () => AddSourceScreen(
            advancedEnabled: true,
            onBack: () {},
            onPickSource: (_) {},
          ),
      const [],
    ),
    'Settings, Advanced sources with a line': (
      () => SettingsScreen(
            theme: ThemeController(),
            state: const SettingsState(
              advancedSourcesEnabled: true,
              section: SettingsSection.advancedSources,
            ),
            onStateChanged: (_) {},
          ),
      [
        plexSessionProvider.overrideWith(_SignedOut.new),
        playbackPrefsProvider.overrideWith(_Prefs.new),
        xtreamAccountsProvider.overrideWith(() => _Accounts(const [account])),
      ],
    ),
    'Live TV': (
      () => const LiveTvTab(),
      [
        xtreamAccountsProvider.overrideWith(() => _Accounts(const [account])),
        xtreamChannelsProvider.overrideWith((ref, _) async => const [
              XtreamChannel(streamId: '1', name: 'One', categoryId: '10'),
              XtreamChannel(streamId: '2', name: 'Two', categoryId: '20'),
            ]),
        favoritesProvider.overrideWith(_NoFavourites.new),
      ],
    ),
  };

  for (final MapEntry(key: name, value: (build, overrides))
      in screens.entries) {
    group(name, () {
      testWidgets('something is focused after the first press',
          (tester) async {
        await DpadAudit.pumpTv(tester, build(), overrides: overrides);
        await DpadAudit(tester).expectFirstPressFocuses();
      });

      testWidgets('every control is reachable by arrow keys', (tester) async {
        await DpadAudit.pumpTv(tester, build(), overrides: overrides);
        await DpadAudit(tester).expectAllReachable();
      });

      testWidgets('focus is visible on every control', (tester) async {
        await DpadAudit.pumpTv(tester, build(), overrides: overrides);
        await DpadAudit(tester).expectFocusVisible();
      });

      testWidgets('Up or Down leaves every text field', (tester) async {
        await DpadAudit.pumpTv(tester, build(), overrides: overrides);
        await DpadAudit(tester).expectFieldsEscapable();
      });
    });
  }
}
