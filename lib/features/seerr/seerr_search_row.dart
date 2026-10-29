import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/seerr/seerr_client.dart';
import '../../i18n/strings.g.dart';
import 'seerr_controller.dart';

/// Under a search: what the person's request server can find that their
/// library does not have yet (§20). Nothing at all without a Seerr server,
/// or while it has nothing to add.
class SeerrSearchRow extends ConsumerWidget {
  const SeerrSearchRow({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(seerrProvider);
    if (client == null) return const SizedBox.shrink();
    final result = ref.watch(seerrSearchProvider(query));
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    // A lapsed sign-in says so here rather than leaving the row quietly
    // empty, which would read as "the server has nothing".
    if (result.error case final SeerrException e) {
      return Padding(
        padding: RelayLayout.pagePadding(f).copyWith(top: 10, bottom: 4),
        child: Text(e.message, style: TextStyle(color: t.inkDim, fontSize: 13)),
      );
    }
    final titles = result.value ?? const <SeerrTitle>[];
    if (titles.isEmpty) return const SizedBox.shrink();
    final tv = f == RelayFormFactor.tv;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: RelayLayout.pagePadding(f).copyWith(top: 10, bottom: 8),
          child: Text(
            tr.seerr.rowTitle(title: client.info.title),
            style: TextStyle(
              color: t.ink,
              fontSize: RelayLayout.bodySize(f) + 1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: tv ? 250 : 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: RelayLayout.pagePadding(f).copyWith(top: 0, bottom: 0),
            itemCount: titles.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _Tile(title: titles[i], tv: tv),
          ),
        ),
      ],
    );
  }
}

class _Tile extends ConsumerWidget {
  const _Tile({required this.title, required this.tv});

  final SeerrTitle title;
  final bool tv;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final width = tv ? 130.0 : 108.0;
    final poster = title.posterUrl();
    final note = switch (title.availability) {
      SeerrAvailability.pending ||
      SeerrAvailability.processing => tr.seerr.requested,
      SeerrAvailability.partial => tr.seerr.partial,
      _ => null,
    };
    return SizedBox(
      width: width,
      child: RelayTappable(
        borderRadius: 10,
        onTap: title.availability.canRequest
            ? () => requestTitle(context, ref, title)
            : () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: width,
                height: width * 1.5,
                child: poster == null
                    ? Container(
                        color: t.surface,
                        child: Icon(Icons.movie_outlined, color: t.inkDim),
                      )
                    : Image.network(
                        poster,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(color: t.surface),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: t.ink, fontSize: tv ? 15 : 12.5),
            ),
            Text(
              note ?? (title.year == null ? '' : '${title.year}'),
              style: TextStyle(
                color: note == null ? t.inkDim : t.accent,
                fontSize: tv ? 13 : 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks before sending: a request is someone else's work on their server,
/// so one press on a remote must not make it.
Future<void> requestTitle(
  BuildContext context,
  WidgetRef ref,
  SeerrTitle title,
) async {
  final client = ref.read(seerrProvider);
  if (client == null) return;
  final t = RelayTheme.of(context);
  final yes = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        tr.seerr.askTitle(title: title.title),
        style: TextStyle(
          color: t.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        title.isShow
            ? tr.seerr.askShow(server: client.info.title)
            : tr.seerr.askMovie(server: client.info.title),
        style: TextStyle(color: t.inkDim, fontSize: 14, height: 1.55),
      ),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: t.inkDim),
          child: Text(tr.common.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: t.accent,
            foregroundColor: t.accentInk,
          ),
          child: Text(tr.seerr.request),
        ),
      ],
    ),
  );
  if (yes != true || !context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await client.request(title);
    messenger?.showSnackBar(
      SnackBar(content: Text(tr.seerr.sent(title: title.title))),
    );
    ref.invalidate(seerrSearchProvider);
    ref.invalidate(seerrRequestsProvider);
  } on SeerrException catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(e.message)));
  }
}
