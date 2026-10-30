import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../i18n/strings.g.dart';

/// The top-level destinations from the Home artboard's bottom bar, plus
/// Downloads (§18), which is a destination of its own and not a corner of
/// Settings because it is the one screen that has to be reachable with no
/// network: a person opening the app on a plane goes straight there.
enum ShellTab {
  library(Icons.video_library_outlined, Icons.video_library),
  search(Icons.search_outlined, Icons.search),
  downloads(Icons.download_outlined, Icons.download),
  settings(Icons.settings_outlined, Icons.settings);

  const ShellTab(this.icon, this.selectedIcon);

  String get label => switch (this) {
    library => tr.shell.library,
    search => tr.shell.search,
    downloads => tr.shell.downloads,
    settings => tr.shell.settings,
  };
  final IconData icon;
  final IconData selectedIcon;
}

/// Persistent chrome around the top-level tabs.
///
/// A rail on desktop and TV, a bottom bar on phone/tablet, matching the two
/// Home artboards. Each tab keeps its own navigation stack, so opening a title
/// from Search and coming back does not reset the Library's scroll position.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  /// The rail and the content are put in scopes of their own so
  /// [RelayFocusBoundary] can hand focus deliberately from one to the other,
  /// and so each remembers where the viewer was when they left it. Without
  /// that, the rail is unreachable by remote: traversal stops at the edge of
  /// the route's scope, and the rail is outside it (§11).
  final FocusScopeNode _railScope = FocusScopeNode(debugLabel: 'shell rail');
  final FocusScopeNode _contentScope = FocusScopeNode(
    debugLabel: 'shell content',
  );

  /// Whether the remote is on the rail. Drives the TV rail's expansion.
  bool _railFocused = false;

  @override
  void initState() {
    super.initState();
    _railScope.addListener(_onRailFocus);
  }

  void _onRailFocus() {
    if (_railScope.hasFocus != _railFocused) {
      setState(() => _railFocused = _railScope.hasFocus);
    }
  }

  @override
  void dispose() {
    _railScope.removeListener(_onRailFocus);
    _railScope.dispose();
    _contentScope.dispose();
    super.dispose();
  }

  void _go(int index) => widget.navigationShell.goBranch(
    index,
    initialLocation: index == widget.navigationShell.currentIndex,
  );

  /// Back with nothing left to go back to would close the app. Ask first.
  ///
  /// Reported on a TV: a few Backs too many out of a title or a folder and the
  /// app was gone, with a cold start to get back to where you were. The shell is
  /// the bottom of the stack, so this is only reached once every pushed page and
  /// every branch-local page has already been popped. *Stay* takes focus, and a
  /// further Back dismisses the dialog, so leaving takes a deliberate choice
  /// rather than one press too many. Android only: it is the one platform here
  /// where Back exits the app.
  Future<void> _confirmExit() async {
    final t = RelayTheme.of(context);
    final exit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          tr.shell.exitTitle,
          style: TextStyle(
            color: t.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: t.inkDim),
            child: Text(tr.shell.exit),
          ),
          FilledButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            style: FilledButton.styleFrom(
              backgroundColor: t.accent,
              foregroundColor: t.accentInk,
            ),
            child: Text(tr.shell.stay),
          ),
        ],
      ),
    );
    if (exit == true) await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: defaultTargetPlatform != TargetPlatform.android,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: _shell(context),
    );
  }

  Widget _shell(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final wide = f == RelayFormFactor.desktop || f == RelayFormFactor.tv;

    if (f == RelayFormFactor.tv) {
      // The rail shrinks to an icon strip while the viewer is in the content
      // and opens over it, rather than beside it, when the remote reaches it.
      // Beside it would resize the grid on every visit to the rail. The
      // content is given the strip's width permanently, so nothing reflows.
      //
      // Since 2026-10-30 it opens the way Plex's TV app does (architecture.md
      // §12.4): a bare strip of icons at rest, with no panel or divider of its
      // own, and on arrival a wide drawer of icon-and-label rows over content
      // that dims behind it. It used to grow from 64 to 104 dp with labels
      // stacked under the icons, which never read as a menu opening.
      return Scaffold(
        backgroundColor: t.bg,
        body: RelayFocusBoundary(
          leading: _railScope,
          main: _contentScope,
          child: Stack(
            children: [
              Positioned.fill(
                left: _TvRail.collapsedWidth,
                child: FocusScope(
                  node: _contentScope,
                  child: widget.navigationShell,
                ),
              ),
              // Says the content is not where the remote is while the drawer
              // is open. Never takes a press: the remote is on the drawer.
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _railFocused ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: ColoredBox(color: t.stage.withValues(alpha: 0.6)),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: FocusScope(
                  node: _railScope,
                  child: _TvRail(
                    selected: widget.navigationShell.currentIndex,
                    onSelect: _go,
                    expanded: _railFocused,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (wide) {
      return Scaffold(
        backgroundColor: t.bg,
        body: RelayFocusBoundary(
          leading: _railScope,
          main: _contentScope,
          child: Row(
            children: [
              FocusScope(
                node: _railScope,
                child: _Rail(
                  selected: widget.navigationShell.currentIndex,
                  onSelect: _go,
                ),
              ),
              VerticalDivider(width: 1, color: t.line),
              Expanded(
                child: FocusScope(
                  node: _contentScope,
                  child: widget.navigationShell,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: t.bg,
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: t.surface,
        indicatorColor: t.accent.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: _go,
        destinations: [
          for (final tab in ShellTab.values)
            NavigationDestination(
              icon: Icon(tab.icon, color: t.inkDim),
              selectedIcon: Icon(tab.selectedIcon, color: t.accent),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

/// The rail, drawn from [RelayTappable] rather than Material's `NavigationRail`.
///
/// Not a style preference. `NavigationRail` destinations do take focus, but
/// they paint no focus treatment that survives a 10-foot viewing distance: the
/// indicator marks the *selected* destination, and the Material focus overlay
/// is a faint tint. Measured on a Google TV emulator, arriving in the rail by
/// remote produced no visible change at all — the viewer moves between Library,
/// Search and Settings with nothing on screen telling them where they are, and
/// a theme-level `focusColor` did not fix it. Building the three destinations
/// out of the same widget as everything else means focus looks the same here as
/// it does on a poster (§11).
class _Rail extends StatelessWidget {
  // Desktop only since 2026-10-30; a TV has _TvRail.
  const _Rail({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);

    return Container(
      width: 88,
      color: t.surface,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ClipRect(
        child: Column(
          children: [
            for (final (index, tab) in ShellTab.values.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: RelayTappable(
                  borderRadius: 14,
                  onTap: () => onSelect(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        // The pill marks the selected destination, which is a
                        // different question from where focus is.
                        Container(
                          width: 56,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: index == selected
                                ? t.accent.withValues(alpha: 0.18)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            index == selected ? tab.selectedIcon : tab.icon,
                            color: index == selected ? t.accent : t.inkDim,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            color: index == selected ? t.ink : t.inkDim,
                            fontSize: 12,
                            fontWeight: index == selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The TV rail: an icon strip at rest, a drawer when the remote is on it.
///
/// After Plex's TV app, compared on the same screen (architecture.md §12.4).
/// At rest it has no panel of its own, so the library's backdrop runs behind
/// it. Open, it is a panel of rows, each an icon and its label side by side,
/// over content the shell dims. The rows keep one height either way, so
/// opening it never moves anything vertically under the remote.
class _TvRail extends StatelessWidget {
  const _TvRail({
    required this.selected,
    required this.onSelect,
    required this.expanded,
  });

  static const double collapsedWidth = 64;
  static const double openWidth = 232;

  final int selected;
  final ValueChanged<int> onSelect;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: expanded ? openWidth : collapsedWidth,
      decoration: BoxDecoration(
        color: expanded ? t.surface : t.surface.withValues(alpha: 0),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(18)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ClipRect(
        child: Column(
          children: [
            for (final (index, tab) in ShellTab.values.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: RelayTappable(
                  borderRadius: 24,
                  onTap: () => onSelect(index),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      // Marks where you are, which is a different question
                      // from where focus is: the ring answers that.
                      color: index == selected && expanded
                          ? t.ink.withValues(alpha: 0.12)
                          : t.ink.withValues(alpha: 0),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    // Laid out at full width and clipped while the drawer
                    // animates, so the label slides in rather than reflowing.
                    child: OverflowBox(
                      alignment: Alignment.centerLeft,
                      minWidth: openWidth - 16,
                      maxWidth: openWidth - 16,
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(
                            index == selected ? tab.selectedIcon : tab.icon,
                            color: index == selected ? t.accent : t.inkDim,
                            size: 24,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: AnimatedOpacity(
                              opacity: expanded ? 1 : 0,
                              duration: const Duration(milliseconds: 140),
                              child: Text(
                                tab.label,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.fade,
                                style: TextStyle(
                                  color: index == selected ? t.ink : t.inkDim,
                                  fontSize: 17,
                                  fontWeight: index == selected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
