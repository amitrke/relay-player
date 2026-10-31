import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/downloads/download_record.dart';
import '../../data/local/favorites_store.dart';
import '../../domain/models/media_server.dart';
import '../../i18n/strings.g.dart';
import '../accounts/media_servers.dart';
import '../downloads/downloads_controller.dart';
import '../favorites_history/favorites_controller.dart';
import '../favorites_history/history_controller.dart';
import '../favorites_history/watch_actions.dart';
import '../favorites_history/watch_state.dart';
import 'library_hero.dart' show HeroInfo;
import 'poster_grid.dart' show LibraryEmptyState;

/// A film's own page (§12 screen 5), between its poster and the player.
///
/// Until 2026-10-30 a film poster went straight to the player, while a show
/// opened a page: one press of OK on the wrong poster started a two-hour film,
/// and nothing said where it would start. Plex's apps open a page first, and
/// so does this now, from the library rows, the grids, search and the AI
/// picks. **Continue watching still plays at once**: that row exists to pick
/// up where you were, and a page in the way would only add a press. Its
/// long-press sheet has *Details* for the page.
///
/// The page names the point it will resume from, so a resume that goes wrong
/// shows before playing rather than after (MANUAL_TESTING.md §4). Watched,
/// download and favourite, which were only in the long-press sheet, sit here
/// as buttons beside Play.

/// The film as the server has it now, not as the library fetch last saw it:
/// fetched each time the page opens, so a watch elsewhere since is reflected.
final _filmProvider = FutureProvider.autoDispose
    .family<MediaItem?, (String, String)>((ref, arg) {
      for (final server in ref.watch(connectedServersProvider)) {
        if (server.id == arg.$1) return server.service.item(arg.$2);
      }
      throw StateError('No connected server with id "${arg.$1}".');
    });

class FilmDetailScreen extends ConsumerWidget {
  const FilmDetailScreen({
    super.key,
    required this.serverId,
    required this.ratingKey,
  });

  final String serverId;
  final String ratingKey;

  /// Where a film from a server opens. The player is `/play/...`.
  static String routeOf(String serverId, String ratingKey) =>
      '/film/$serverId/$ratingKey';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final film = ref.watch(_filmProvider((serverId, ratingKey)));
    final tv = RelayLayout.of(context) == RelayFormFactor.tv;

    return Scaffold(
      backgroundColor: t.bg,
      // Over the art on a phone or tablet, where there is no remote Back.
      extendBodyBehindAppBar: true,
      appBar: tv
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              foregroundColor: t.ink,
            ),
      body: film.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: t.accent)),
        error: (e, _) => LibraryEmptyState(
          icon: Icons.cloud_off_outlined,
          message: tr.film.gone,
          onRetry: () => ref.invalidate(_filmProvider((serverId, ratingKey))),
        ),
        data: (item) => item == null
            ? LibraryEmptyState(
                icon: Icons.movie_outlined,
                message: tr.film.gone,
              )
            : _FilmPage(serverId: serverId, item: item),
      ),
    );
  }
}

class _FilmPage extends ConsumerWidget {
  const _FilmPage({required this.serverId, required this.item});

  final String serverId;
  final MediaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final tv = f == RelayFormFactor.tv;
    final phone = f == RelayFormFactor.phone;
    final service = mediaServerFor(ref, serverId);
    final catalog = service.toCatalogItem(item);
    final hero = HeroInfo.ofItem(catalog);

    // The same rule as the poster's tick and bar, so the page and the poster
    // it came from can never disagree about whether this was watched.
    final key = historyKeyOf(catalog)!;
    final watch = WatchState.forItem(
      catalog,
      local: ref.watch(
        historyProvider.select(
          (all) => all.where((h) => h.key == key).firstOrNull,
        ),
      ),
      override: ref.watch(watchOverridesProvider.select((m) => m[key])),
    );
    final total = item.duration;
    final resumeAt = watch.inProgress && total != null
        ? Duration(
            milliseconds: (total.inMilliseconds * watch.progress!).round(),
          )
        : null;

    final size = MediaQuery.sizeOf(context);
    final art = item.artPath == null
        ? null
        : service.posterUrlForPath(item.artPath!, width: 1280, height: 720);
    // A phone or tablet shows the art as a band across the top; a TV puts it
    // behind the whole page, as the library does.
    final band = tv
        ? size.height
        : (size.width * 9 / 16).clamp(0.0, size.height * 0.5);

    final buttons = _Buttons(
      serverId: serverId,
      item: item,
      watched: watch.watched,
      resumeAt: resumeAt,
    );

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: TextStyle(
            color: t.ink,
            fontSize: tv ? 34 : (phone ? 24 : 30),
            height: 1.15,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (hero.meta.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            hero.meta.join('  ·  '),
            style: TextStyle(color: t.inkDim, fontSize: tv ? 15 : 13),
          ),
        ],
        if (resumeAt != null && total != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: 240,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: watch.progress,
                minHeight: 3,
                backgroundColor: t.line,
                valueColor: AlwaysStoppedAnimation(t.accent),
              ),
            ),
          ),
        ],
        SizedBox(height: tv ? 22 : 18),
        buttons,
        if ((item.summary ?? '').trim().isNotEmpty) ...[
          SizedBox(height: tv ? 22 : 20),
          ConstrainedBox(
            // A measure that reads: about 70 characters a line.
            constraints: BoxConstraints(maxWidth: tv ? size.width * 0.55 : 640),
            child: Text(
              item.summary!.trim(),
              maxLines: tv ? 5 : null,
              overflow: tv ? TextOverflow.ellipsis : null,
              style: TextStyle(
                color: t.ink.withValues(alpha: 0.85),
                fontSize: tv ? 15 : 14,
                height: 1.5,
              ),
            ),
          ),
        ],
        if (item.cast.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            item.cast.join(', '),
            style: TextStyle(color: t.inkDim, fontSize: tv ? 14 : 13),
          ),
        ],
      ],
    );

    // Expanded to the whole body: a Scaffold hands its body loose constraints,
    // so the Stack otherwise took the size of the text column and clipped the
    // art to it (a hard edge at the text's width and height, seen on the TV
    // emulator).
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          right: 0,
          width: tv ? size.width * 0.75 : size.width,
          height: band,
          child: _Backdrop(art: art, poster: catalog.posterUrl, tv: tv),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: tv
                ? RelayLayout.pagePadding(f).copyWith(top: 64, bottom: 32)
                : RelayLayout.pagePadding(f).copyWith(
                    // Text starts over the lower part of the band, where the
                    // fade has made the art dark enough to read on.
                    top: band * 0.55,
                    bottom: 32,
                  ),
            child: text,
          ),
        ),
      ],
    );
  }
}

/// Play or Resume, Play from start, Watched, Download and Favourite, in that
/// order. The first takes focus, so on a TV OK starts the film from where it
/// says, and the rest are one Right away.
class _Buttons extends ConsumerWidget {
  const _Buttons({
    required this.serverId,
    required this.item,
    required this.watched,
    required this.resumeAt,
  });

  final String serverId;
  final MediaItem item;
  final bool watched;
  final Duration? resumeAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final download = ref.watch(
      downloadsProvider.select(
        (all) => all
            .where((d) => d.serverId == serverId && d.ratingKey == item.id)
            .firstOrNull,
      ),
    );
    final favourite = FavoriteItem(
      kind: FavoriteKind.movie,
      sourceId: serverId,
      itemId: item.id,
    );
    final starred = ref.watch(favoritesProvider).contains(favourite.key);
    final resume = resumeAt;
    final play = '/play/$serverId/${item.id}';

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _PillButton(
          primary: true,
          autofocus: true,
          icon: Icons.play_arrow_rounded,
          label: resume == null
              ? tr.film.play
              : tr.film.resume(time: resumeLabel(resume)),
          onTap: () => context.push(play),
        ),
        if (resume != null)
          _PillButton(
            icon: Icons.replay,
            label: tr.film.fromStart,
            onTap: () => context.push('$play?start=0'),
          ),
        _PillButton(
          icon: watched ? Icons.check_circle : Icons.check_circle_outline,
          label: watched
              ? tr.watchActions.markUnwatched(scope: '')
              : tr.watchActions.markWatched(scope: ''),
          onTap: () => _markWatched(context, ref, !watched),
        ),
        _PillButton(
          icon: download == null || download.state == DownloadState.failed
              ? Icons.download_outlined
              : Icons.delete_outline,
          label: download == null || download.state == DownloadState.failed
              ? tr.watchActions.download
              : (download.isComplete
                    ? tr.watchActions.deleteDownload
                    : tr.watchActions.cancelDownload),
          onTap: () => _toggleDownload(context, ref, download),
        ),
        _PillButton(
          icon: starred ? Icons.star : Icons.star_border,
          label: starred
              ? tr.watchActions.removeFavourite
              : tr.watchActions.addFavourite,
          onTap: () => ref.read(favoritesProvider.notifier).toggle(favourite),
        ),
      ],
    );
  }

  Future<void> _markWatched(
    BuildContext context,
    WidgetRef ref,
    bool watched,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await ref
          .read(watchOverridesProvider.notifier)
          .mark(serverId: serverId, ratingKey: item.id, watched: watched);
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(content: Text(tr.watchActions.plexRefused)),
      );
    }
  }

  Future<void> _toggleDownload(
    BuildContext context,
    WidgetRef ref,
    DownloadRecord? existing,
  ) async {
    final downloads = ref.read(downloadsProvider.notifier);
    if (existing == null || existing.state == DownloadState.failed) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      await downloads.enqueue(
        serverId: serverId,
        ratingKey: item.id,
        title: item.title,
        isEpisode: false,
      );
      messenger?.showSnackBar(
        SnackBar(content: Text(tr.watchActions.downloading)),
      );
    } else {
      await downloads.remove(serverId, item.id);
    }
  }
}

/// A rounded action, filled for the main one. Built on [RelayTappable] so a
/// remote reaches every one with the same ring as a poster (§11).
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.autofocus = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final tv = RelayLayout.of(context) == RelayFormFactor.tv;
    final fg = primary ? t.accentInk : t.ink;
    return RelayTappable(
      borderRadius: 24,
      autofocus: autofocus,
      onTap: onTap,
      child: Container(
        height: tv ? 46 : 44,
        padding: EdgeInsets.symmetric(horizontal: primary ? 20 : 16),
        decoration: BoxDecoration(
          color: primary ? t.accent : t.ink.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(width: 8),
            // Shrinks rather than overflows: a Wrap gives a pill at most the
            // row's width, and a long label in a longer language or at a
            // large text size can exceed a phone's (caught by the phone-size
            // test).
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: tv ? 16 : 14,
                  fontWeight: primary ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The film's art, faded into the page; its poster, blurred, when it has no
/// art. The same treatment as the TV library's backdrop (library_hero.dart).
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.art, required this.poster, required this.tv});

  final String? art;
  final String? poster;
  final bool tv;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final src = art ?? poster;
    if (src == null) return const SizedBox.shrink();
    Widget image = Image.network(
      src,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
    if (art == null) {
      image = ClipRect(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 24,
            sigmaY: 24,
            tileMode: TileMode.decal,
          ),
          child: Opacity(opacity: 0.6, child: image),
        ),
      );
    }
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          if (tv)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    t.bg,
                    t.bg.withValues(alpha: 0.75),
                    t.bg.withValues(alpha: 0.1),
                  ],
                  stops: const [0, 0.35, 0.8],
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  t.bg.withValues(alpha: tv ? 0.2 : 0.35),
                  t.bg.withValues(alpha: 0),
                  t.bg,
                ],
                stops: const [0, 0.3, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "6:16" or "1:02:16": the player's clock shows "06:16" beside a running
/// total, but in a sentence the leading zero reads like a time of day.
String resumeLabel(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}
