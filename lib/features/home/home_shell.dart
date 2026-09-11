import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';

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
/// A rail on desktop and a bottom bar on phone/tablet, matching the two Home
/// artboards. Each tab keeps its own navigation stack, so opening a title from
/// Search and coming back does not reset the Library's scroll position.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _go(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final wide =
        f == RelayFormFactor.desktop || f == RelayFormFactor.tv;

    if (wide) {
      return Scaffold(
        backgroundColor: t.bg,
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: t.surface,
              indicatorColor: t.accent.withValues(alpha: 0.18),
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _go,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final tab in ShellTab.values)
                  NavigationRailDestination(
                    icon: Icon(tab.icon, color: t.inkDim),
                    selectedIcon: Icon(tab.selectedIcon, color: t.accent),
                    label: Text(tab.label, style: TextStyle(color: t.ink)),
                  ),
              ],
            ),
            VerticalDivider(width: 1, color: t.line),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: t.bg,
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: t.surface,
        indicatorColor: t.accent.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        selectedIndex: navigationShell.currentIndex,
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
