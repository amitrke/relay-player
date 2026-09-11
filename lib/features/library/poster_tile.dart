import 'package:dart_plex/dart_plex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../data/plex/plex_service.dart';
import '../accounts/plex_session.dart';

/// One library item: poster, title, year.
class PosterTile extends ConsumerWidget {
  const PosterTile({super.key, required this.item});

  final SourcedItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final metadata = item.metadata;
    final poster =
        plexServiceFor(ref, item.serverId).posterUrl(metadata);
    final isShow = metadata.type == PlexMetadataType.show;

    return GestureDetector(
      // A show has no file of its own — it resolves to seasons and episodes,
      // so it opens a detail screen. A movie resolves straight to a file.
      // Both routes carry the server: a ratingKey means nothing without it.
      onTap: () => context.push(
        isShow
            ? '/show/${item.serverId}/${metadata.ratingKey}'
            : '/play/${item.serverId}/${metadata.ratingKey}',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                color: t.surface,
                child: poster == null
                    ? Icon(Icons.movie_outlined, color: t.inkDim)
                    : Image.network(
                        poster,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Icon(Icons.movie_outlined, color: t.inkDim),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            metadata.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.ink,
              fontSize: 12.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (metadata.year != null)
            Text(
              '${metadata.year}',
              style: TextStyle(color: t.inkDim, fontSize: 11),
            ),
        ],
      ),
    );
  }
}
