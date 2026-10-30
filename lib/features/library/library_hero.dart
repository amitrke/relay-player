import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../domain/models/catalog_item.dart';
import '../../i18n/strings.g.dart';
import '../accounts/media_servers.dart';
import 'library_screen.dart' show libraryItemsProvider;
import 'library_tab.dart';

/// The TV library's detail area and backdrop (architecture.md §12.4).
///
/// Put beside Plex's own TV app on the same server (2026-10-30), the clearest
/// difference was not poster size but where the words go. Plex draws no text
/// under its posters; whatever has focus is described once, large, at the top
/// of the screen over its own artwork. We drew a title and a year under every
/// poster, which on a 540 dp TV made a single row of shelves taller than half
/// the screen, and said nothing more about the one title being looked at.
///
/// Phone, tablet and desktop keep captions under posters: with a finger or a
/// mouse there is no single focused title to describe.

/// What the TV hero shows about the title with focus.
@immutable
class HeroInfo {
  const HeroInfo({
    required this.title,
    this.meta = const [],
    this.summary,
    this.serverId,
    this.artPath,
    this.posterUrl,
  });

  /// From a poster in a library row.
  factory HeroInfo.ofItem(CatalogItem item) => HeroInfo(
    title: item.title,
    meta: [
      if (item.year != null) '${item.year}',
      if (item.duration case final d? when d > Duration.zero) runtimeOf(d),
      if (item.kind == CatalogKind.show && (item.unwatchedEpisodes ?? 0) > 0)
        tr.library.tile.unwatchedEpisodes(n: item.unwatchedEpisodes!),
      if (item.rating case final r?) '★ ${r.toStringAsFixed(1)}',
      ...item.genres.take(3),
    ],
    summary: item.summary,
    serverId: item.source == CatalogSource.server ? item.sourceId : null,
    artPath: item.artPath,
    posterUrl: item.posterUrl,
  );

  /// For a Continue watching entry: the whole library title when it is one
  /// (a film), so the hero has its plot and art, keeping the entry's own
  /// "97 min left" in front. An episode is not a library title and gets the
  /// short form with the poster blurred behind it.
  static HeroInfo forResume(
    WidgetRef ref, {
    required String title,
    required String detail,
    required String sourceId,
    required String itemId,
    required bool fromServer,
    String? posterUrl,
  }) {
    final short = HeroInfo(
      title: title,
      meta: [if (detail.isNotEmpty) detail],
      posterUrl: posterUrl,
    );
    if (!fromServer) return short;
    for (final tab in const [LibraryTab.movies, LibraryTab.series]) {
      final items = ref.read(libraryItemsProvider(tab)).value;
      if (items == null) continue;
      for (final i in items) {
        if (i.source == CatalogSource.server &&
            i.sourceId == sourceId &&
            i.id == itemId) {
          final full = HeroInfo.ofItem(i);
          return HeroInfo(
            title: full.title,
            meta: [if (detail.isNotEmpty) detail, ...full.meta],
            summary: full.summary,
            serverId: full.serverId,
            artPath: full.artPath,
            posterUrl: full.posterUrl ?? posterUrl,
          );
        }
      }
    }
    return short;
  }

  final String title;

  /// Short facts, joined with dots: year, runtime, rating, genres.
  final List<String> meta;
  final String? summary;

  /// The server [artPath] is signed against; null for a panel title.
  final String? serverId;
  final String? artPath;

  /// Already signed or absolute. The backdrop falls back to it, blurred, when
  /// there is no [artPath], so a title without landscape art still colours the
  /// screen rather than leaving it bare.
  final String? posterUrl;

  static String runtimeOf(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return tr.units.minutes(m: m);
    return m == 0 ? tr.units.hours(h: h) : tr.units.hoursMinutes(h: h, m: m);
  }

  @override
  bool operator ==(Object other) =>
      other is HeroInfo &&
      other.title == title &&
      other.serverId == serverId &&
      other.artPath == artPath &&
      other.posterUrl == posterUrl &&
      other.summary == summary &&
      _sameList(other.meta, meta);

  @override
  int get hashCode =>
      Object.hash(title, serverId, artPath, posterUrl, summary, meta.length);

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// The title the remote is on, for the hero and the backdrop. Null until
/// something takes focus; the hero then stays empty rather than guessing.
final focusedTitleProvider = NotifierProvider<FocusedTitle, HeroInfo?>(
  FocusedTitle.new,
);

class FocusedTitle extends Notifier<HeroInfo?> {
  @override
  HeroInfo? build() => null;

  void show(HeroInfo info) {
    if (state != info) state = info;
  }
}

/// Height of the TV hero's text block, in dp. With the tab row above it this
/// leaves the shelves a little more than one and a half rows of the 540 dp
/// screen, which is what Plex shows too.
const double tvHeroHeight = 150;

/// Title, facts and plot of the focused title, large, at the top of the TV
/// library. Fixed height, so moving between titles never moves the rows.
class LibraryHero extends ConsumerWidget {
  const LibraryHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final info = ref.watch(focusedTitleProvider);
    final width = MediaQuery.sizeOf(context).width;

    return SizedBox(
      height: tvHeroHeight,
      child: Padding(
        padding: RelayLayout.pagePadding(RelayFormFactor.tv)
            .copyWith(top: 4, bottom: 0),
        child: info == null
            ? const SizedBox.shrink()
            : ConstrainedBox(
                // About half the screen: the right side belongs to the art.
                constraints: BoxConstraints(maxWidth: width * 0.52),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t.ink,
                        fontSize: 30,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (info.meta.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        info.meta.join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: t.inkDim, fontSize: 14),
                      ),
                    ],
                    if (info.summary case final s?
                        when s.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        s.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: t.ink.withValues(alpha: 0.85),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

/// The focused title's landscape art, behind the top of the TV library,
/// fading into the page on the left (under the text) and at the bottom (under
/// the rows) so both stay readable on any artwork and in every palette.
class LibraryBackdrop extends ConsumerWidget {
  const LibraryBackdrop({super.key});

  /// Signed at a landscape size from the live connection; never stored (§3).
  static String? artUrl(WidgetRef ref, HeroInfo info) {
    final path = info.artPath;
    final server = info.serverId;
    if (path == null || server == null) return null;
    try {
      return mediaServerFor(
        ref,
        server,
      ).posterUrlForPath(path, width: 1280, height: 720);
    } on StateError {
      return null; // No longer connected.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final info = ref.watch(focusedTitleProvider);
    final art = info == null ? null : artUrl(ref, info);
    final poster = info?.posterUrl;
    final url = art ?? poster;
    final size = MediaQuery.sizeOf(context);

    Widget image(String src, {required bool blur}) {
      final img = Image.network(
        src,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        // A missing image is no image: the page colour shows through.
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
        // Fade in rather than pop, so moving along a row reads as one surface
        // changing rather than a flicker per poster.
        frameBuilder: (_, child, frame, sync) => sync
            ? child
            : AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                child: child,
              ),
      );
      // Clipped: a blur paints a halo past its own bounds, which showed as a
      // hard lighter edge beyond the fade on the left (seen on the emulator).
      return blur
          ? ClipRect(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 24,
                  sigmaY: 24,
                  tileMode: TileMode.decal,
                ),
                child: Opacity(opacity: 0.6, child: img),
              ),
            )
          : img;
    }

    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: url == null
            ? const SizedBox.expand(key: ValueKey('none'))
            : Stack(
                key: ValueKey(url),
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    width: size.width * 0.72,
                    height: size.height * 0.62,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        image(url, blur: art == null),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                t.bg,
                                t.bg.withValues(alpha: 0.7),
                                t.bg.withValues(alpha: 0.05),
                              ],
                              stops: const [0, 0.3, 0.75],
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              // Dark at the top too, under the sort control
                              // and count, which sit on the art's top edge.
                              colors: [
                                t.bg.withValues(alpha: 0.75),
                                t.bg.withValues(alpha: 0),
                                t.bg.withValues(alpha: 0),
                                t.bg,
                              ],
                              stops: const [0, 0.18, 0.4, 0.95],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
