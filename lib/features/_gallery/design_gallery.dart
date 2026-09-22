import 'package:flutter/material.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_tokens.dart';
import '../../core/theme/theme_controller.dart';
import '../accounts/add_source_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../settings/settings_screen.dart';

/// A debug-only viewer for the implemented screens.
///
/// The design canvas shows every screen at a fixed artboard size; this is the
/// Flutter equivalent, so an implementation can be checked against its artboard
/// side by side, at the same dimensions, in all four palettes. It is not part
/// of the product — `main.dart` gates it on `kDebugMode` alongside the Phase 0
/// spike.
class DesignGallery extends StatefulWidget {
  const DesignGallery({super.key, required this.controller});

  final ThemeController controller;

  @override
  State<DesignGallery> createState() => _DesignGalleryState();
}

/// An artboard from the design canvas, with its exact pixel size.
@immutable
class _Artboard {
  const _Artboard(this.label, this.width, this.height, this.builder);

  final String label;
  final double width;
  final double height;
  final WidgetBuilder builder;
}

class _DesignGalleryState extends State<DesignGallery> {
  int _screenIndex = 0;
  int _boardIndex = 0;

  /// Screens implemented so far. Each entry mirrors one `.dc.html` file.
  late final List<(String, List<_Artboard>)> _screens = [
    (
      '01 · Onboarding',
      [
        _Artboard('Phone', 390, 844, _onboarding),
        _Artboard('Tablet', 834, 1112, _onboarding),
        _Artboard('Desktop', 1440, 900, _onboarding),
        _Artboard('TV (10-foot)', 1920, 1080, _onboarding),
      ],
    ),
    (
      '02 · Add source',
      [
        // Both toggle states, because §8.2's requirement is about what is
        // *absent* when Advanced sources is off — that is only checkable by
        // looking at the two side by side.
        _Artboard('Phone · advanced off', 390, 844,
            (c) => _addSource(c, advanced: false)),
        _Artboard('Phone · advanced on', 390, 844,
            (c) => _addSource(c, advanced: true)),
        _Artboard('Desktop · Plex pairing', 1440, 900,
            (c) => _addSource(c, advanced: false)),
      ],
    ),
    (
      '09 · Settings',
      [
        _Artboard('Phone', 390, 844, _settings),
        _Artboard('Desktop · AI features', 1440, 900, _settings),
      ],
    ),
  ];

  /// Live settings state, so the toggles in the gallery actually work — the
  /// Advanced sources acknowledgement dialog in particular is worth being able
  /// to exercise rather than just look at.
  ///
  /// Opens on AI features, which the real app no longer does: its pane is
  /// demo data, so it lives here and nowhere else until Phase 3.5 builds it.
  SettingsState _settingsState =
      const SettingsState(section: SettingsSection.aiFeatures);

  Widget _settings(BuildContext context) => SettingsScreen(
        theme: widget.controller,
        state: _settingsState,
        onStateChanged: (s) => setState(() => _settingsState = s),
        showUnbuiltSections: true,
      );

  Widget _onboarding(BuildContext context) => OnboardingScreen(
        onAddSource: () => _toast(context, 'Add source → screen 02'),
        onSkip: () => _toast(context, 'Skipped'),
      );

  Widget _addSource(BuildContext context, {required bool advanced}) =>
      AddSourceScreen(
        advancedEnabled: advanced,
        onBack: () => _toast(context, 'Back'),
        onPickSource: (kind) => _toast(context, 'Picked ${kind.title}'),
        onOpenSettings: () => _toast(context, 'Settings → Advanced sources'),
      );

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final (screenLabel, boards) = _screens[_screenIndex];
    final board = boards[_boardIndex.clamp(0, boards.length - 1)];

    return Scaffold(
      backgroundColor: t.stage,
      appBar: AppBar(
        backgroundColor: t.surface,
        foregroundColor: t.ink,
        title: Text('$screenLabel · ${board.label}',
            style: const TextStyle(fontSize: 15)),
        actions: [
          _PaletteMenu(controller: widget.controller),
          const SizedBox(width: 8),
          _AccentMenu(controller: widget.controller),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          _Toolbar(
            screens: [for (final s in _screens) s.$1],
            screenIndex: _screenIndex,
            boards: [for (final b in boards) b.label],
            boardIndex: _boardIndex.clamp(0, boards.length - 1),
            onScreen: (i) => setState(() {
              _screenIndex = i;
              _boardIndex = 0;
            }),
            onBoard: (i) => setState(() => _boardIndex = i),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _ArtboardFrame(board: board),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders one artboard at its exact size, with its own MediaQuery so the
/// responsive breakpoints in [RelayLayout] see the artboard's width rather than
/// the host window's.
class _ArtboardFrame extends StatelessWidget {
  const _ArtboardFrame({required this.board});

  final _Artboard board;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final isTv = board.width >= 1800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            '${board.width.toInt()}×${board.height.toInt()}'
            '${isTv ? " · D-pad" : ""}',
            style: TextStyle(
                color: t.inkDim, fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: t.line),
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: board.width,
            height: board.height,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: Size(board.width, board.height),
                padding: EdgeInsets.zero,
                viewInsets: EdgeInsets.zero,
                navigationMode:
                    isTv ? NavigationMode.directional : NavigationMode.traditional,
              ),
              child: Builder(builder: board.builder),
            ),
          ),
        ),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.screens,
    required this.screenIndex,
    required this.boards,
    required this.boardIndex,
    required this.onScreen,
    required this.onBoard,
  });

  final List<String> screens;
  final int screenIndex;
  final List<String> boards;
  final int boardIndex;
  final ValueChanged<int> onScreen;
  final ValueChanged<int> onBoard;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var i = 0; i < screens.length; i++)
            _Chip(
              label: screens[i],
              selected: i == screenIndex,
              onTap: () => onScreen(i),
            ),
          if (boards.length > 1) ...[
            Container(width: 1, height: 22, color: t.line),
            for (var i = 0; i < boards.length; i++)
              _Chip(
                label: boards[i],
                selected: i == boardIndex,
                onTap: () => onBoard(i),
              ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? t.accent : Colors.transparent,
          border: Border.all(color: selected ? t.accent : t.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? t.accentInk : t.inkDim,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _PaletteMenu extends StatelessWidget {
  const _PaletteMenu({required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return PopupMenuButton<RelayPalette>(
      tooltip: 'Theme',
      initialValue: controller.palette,
      onSelected: (p) => controller.palette = p,
      color: t.surface,
      itemBuilder: (context) => [
        for (final p in RelayPalette.values)
          PopupMenuItem(
            value: p,
            child: Text(p.label, style: TextStyle(color: t.ink)),
          ),
      ],
      child: Row(
        children: [
          Icon(Icons.palette_outlined, size: 18, color: t.inkDim),
          const SizedBox(width: 6),
          Text(controller.palette.label,
              style: TextStyle(color: t.inkDim, fontSize: 13)),
        ],
      ),
    );
  }
}

class _AccentMenu extends StatelessWidget {
  const _AccentMenu({required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return PopupMenuButton<Color>(
      tooltip: 'Accent',
      onSelected: (c) => controller.accent = c,
      color: t.surface,
      itemBuilder: (context) => [
        for (final c in RelayAccents.swatches)
          PopupMenuItem(
            value: c,
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                      color: c, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 10),
                Text(
                  '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
                  style: TextStyle(
                      color: t.ink, fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: controller.accent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: t.line),
        ),
      ),
    );
  }
}
