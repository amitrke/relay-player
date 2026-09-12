import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';

/// The three top-level destinations from the Home artboard's bottom bar.
enum ShellTab {
  library('Library', Icons.video_library_outlined, Icons.video_library),
  search('Search', Icons.search_outlined, Icons.search),
  settings('Settings', Icons.settings_outlined, Icons.settings);

  const ShellTab(this.label, this.icon, this.selectedIcon);

  final String label;
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
  final FocusScopeNode _contentScope =
      FocusScopeNode(debugLabel: 'shell content');

  @override
  void dispose() {
    _railScope.dispose();
    _contentScope.dispose();
    super.dispose();
  }

  void _go(int index) => widget.navigationShell.goBranch(
        index,
        initialLocation: index == widget.navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final wide = f == RelayFormFactor.desktop || f == RelayFormFactor.tv;

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
  const _Rail({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final tv = f == RelayFormFactor.tv;

    return Container(
      width: tv ? 104 : 88,
      color: t.surface,
      padding: const EdgeInsets.symmetric(vertical: 16),
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
                          size: tv ? 26 : 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
                        style: TextStyle(
                          color: index == selected ? t.ink : t.inkDim,
                          fontSize: tv ? 14 : 12,
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
    );
  }
}
