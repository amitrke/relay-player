import 'package:dart_plex/dart_plex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../accounts/plex_session.dart';

/// One library item: poster, title, year.
class PosterTile extends ConsumerWidget {
  const PosterTile({super.key, required this.item});

  final PlexMetadata item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final poster = ref.read(plexServiceProvider).posterUrl(item);
    final isShow = item.type == PlexMetadataType.show;

    return GestureDetector(
      onTap: () {
        // Shows need a season/episode choice before anything is playable; only
        // movies resolve straight to a file.
        if (isShow) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: t.surface,
              content: Text(
                'Episode browsing lands next — movies play today.',
                style: TextStyle(color: t.ink),
              ),
            ),
          );
          return;
        }
        context.push('/play/${item.ratingKey}');
      },
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
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.ink,
              fontSize: 12.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (item.year != null)
            Text(
              '${item.year}',
              style: TextStyle(color: t.inkDim, fontSize: 11),
            ),
        ],
      ),
    );
  }
}
