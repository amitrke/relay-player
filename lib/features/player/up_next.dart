import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../domain/models/media_server.dart';
import '../../i18n/strings.g.dart';

/// Offering the next episode when one ends (architecture.md §12.5).
///
/// Two halves: which episode is next, worked out from the server's own
/// episode list so Plex, Jellyfin and Emby all answer the same way, and the
/// card that counts down to it. The player screen joins them.

/// How long the card waits before playing on. Plex's own apps count from
/// about this; long enough to reach the remote, short enough that a binge is
/// not interrupted.
const upNextCountdown = Duration(seconds: 10);

/// The episode after [current] in [episodes], or null when there is none.
///
/// The list is put in season and episode order rather than trusted as sent:
/// Plex's `allLeaves` sends specials (season 0) first, and Jellyfin's order
/// depends on its display settings. Crossing into the next season is just the
/// next item in that order, which is what "the next season's first episode
/// counts" asks for.
///
/// **Specials are left out both ways.** A special is not "the next one" after
/// a season finale, and what follows a special is a question with no good
/// answer (Plex places some of them between episodes with
/// `airsBeforeSeason`, which no list here carries). So a special gets no card
/// and is never offered. Episodes with no numbers at all keep the server's
/// order, since there is nothing better to sort on.
MediaItem? episodeAfter(MediaItem current, List<MediaItem> episodes) {
  if (current.parentIndex == 0) return null;
  final numbered =
      current.parentIndex != null &&
      current.index != null &&
      episodes.every((e) => e.parentIndex != null && e.index != null);
  final order = [
    for (final (i, e) in episodes.indexed)
      if (e.id == current.id || e.parentIndex != 0) (i, e),
  ];
  if (numbered) {
    order.sort((a, b) {
      final bySeason = a.$2.parentIndex!.compareTo(b.$2.parentIndex!);
      if (bySeason != 0) return bySeason;
      final byEpisode = a.$2.index!.compareTo(b.$2.index!);
      // The server's own order breaks a tie, so the sort is stable.
      return byEpisode != 0 ? byEpisode : a.$1.compareTo(b.$1);
    });
  }
  final at = order.indexWhere((p) => p.$2.id == current.id);
  if (at == -1 || at + 1 >= order.length) return null;
  return order[at + 1].$2;
}

/// Asks [server] for the episode after [current], or null when there is none
/// or the server cannot say.
///
/// `episodesOf` rather than On Deck or Next Up: those answer "what has this
/// person not watched", which after a rewatch is somewhere else entirely, and
/// they only update once the server has taken in the finished episode, which
/// is a race with this very lookup. "The one after this" is a fact about the
/// show and can be asked for as soon as the episode starts.
Future<MediaItem?> findNextEpisode(
  MediaServer server,
  MediaItem current,
) async {
  if (current.type != MediaItemType.episode) return null;
  final showId = current.showId;
  if (showId == null) return null;
  try {
    return episodeAfter(current, await server.episodesOf(showId));
  } catch (e) {
    // Offline (a saved copy, §18.4) or a server that has gone: no card is
    // the right answer, and nothing about the episode now ending is wrong.
    debugPrint('Player: no next episode, the server could not list them: $e');
    return null;
  }
}

/// "S2 E1 · Title", the way Continue watching labels an episode.
String upNextLabel(MediaItem next) {
  final numbering = [
    if (next.parentIndex != null) 'S${next.parentIndex}',
    if (next.index != null) 'E${next.index}',
  ].join(' ');
  return numbering.isEmpty ? next.title : '$numbering · ${next.title}';
}

/// The card over the last frame: what is next, a countdown, *Play now* and
/// *Cancel*.
///
/// **Cancel takes focus, not Play now** (§20's rule for anything a remote
/// can commit to): the countdown already plays on if nothing is pressed, so
/// the only press worth making easy is the one that stops it, and a viewer
/// reaching for the remote to stop the credits must not land on "play the
/// next one now". Back cancels too; the screen routes the system Back here
/// through its `PopScope`, and this handles Escape and the remote's Back key
/// where they arrive as keys.
class UpNextCard extends StatefulWidget {
  const UpNextCard({
    super.key,
    required this.next,
    required this.onPlay,
    required this.onCancel,
    this.countdown = upNextCountdown,
  });

  final MediaItem next;
  final VoidCallback onPlay;
  final VoidCallback onCancel;
  final Duration countdown;

  @override
  State<UpNextCard> createState() => _UpNextCardState();
}

class _UpNextCardState extends State<UpNextCard> {
  final _cancel = FocusNode(debugLabel: 'up-next-cancel');
  Timer? _tick;
  late int _left = widget.countdown.inSeconds;
  bool _cancelFocused = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) _play();
    });
    // Asked for explicitly, as `_PlaybackError` does: `autofocus` only fires
    // when nothing in the scope has focus, and the player's root node always
    // does.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cancel.requestFocus();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _cancel.dispose();
    super.dispose();
  }

  /// Once only: the timer and a press can arrive in the same frame.
  void _play() {
    if (_done) return;
    _done = true;
    _tick?.cancel();
    widget.onPlay();
  }

  void _stop() {
    if (_done) return;
    _done = true;
    _tick?.cancel();
    widget.onCancel();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack) {
      _stop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final body = RelayLayout.bodySize(f);
    return Focus(
      // Holds the card's focus together and sees Back before the player does.
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: FocusTraversalGroup(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.player.upNext.title,
                style: TextStyle(
                  color: t.inkDim,
                  fontSize: body - 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              if (widget.next.showTitle case final show?)
                Text(
                  show,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.ink,
                    fontSize: body + 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(
                upNextLabel(widget.next),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: t.ink, fontSize: body),
              ),
              const SizedBox(height: 8),
              Text(
                tr.player.upNext.playingIn(seconds: _left.clamp(0, 999)),
                style: TextStyle(color: t.inkDim, fontSize: body - 1),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RelayButton(
                    label: tr.player.upNext.playNow,
                    onPressed: _play,
                  ),
                  const SizedBox(width: 12),
                  // A text button draws nothing when focused (the theme sets
                  // no focus colour, §11), and the focused Cancel is the whole
                  // point of this card on a TV, so it gets the ring.
                  Focus(
                    canRequestFocus: false,
                    skipTraversal: true,
                    onFocusChange: (v) => setState(() => _cancelFocused = v),
                    child: RelayFocusRing(
                      focused: _cancelFocused,
                      child: RelayTextButton(
                        label: tr.common.cancel,
                        onPressed: _stop,
                        focusNode: _cancel,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
