import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/tmdb/tmdb_client.dart';
import '../../domain/models/media_server.dart';
import '../../i18n/strings.g.dart';
import '../accounts/media_servers.dart';
import '../metadata/tmdb_controller.dart';

/// Ratings and trailers on a film's or show's page (§12 screen 5), shared by
/// both pages.
///
/// Decided 2026-11-01: scores are the server's own, each named by its source,
/// and nothing is fetched to fill a gap, because no IMDb API exists and
/// OMDb's data is licensed for non-commercial use only. Trailers are the
/// server's own files first, played in the app's player; then a link the
/// server's metadata found; then, only with the person's TMDB key saved, a
/// YouTube trailer TMDB lists. Links open in the YouTube app or a browser,
/// never inside the player (MediaTrailer).

/// "IMDb 7.8", "Rotten Tomatoes 91%", "RT audience 87%", "TMDB 8.0", or a
/// plain "★ 7.8" when the server did not say whose score it is. Product
/// names are not translated (§12.3).
List<String> ratingLabels(List<SourcedRating> ratings) => [
  for (final r in ratings)
    switch (r.source) {
      RatingSource.imdb => 'IMDb ${r.value.toStringAsFixed(1)}',
      RatingSource.rottenTomatoes when r.critic =>
        'Rotten Tomatoes ${(r.value * 10).round()}%',
      RatingSource.rottenTomatoes => tr.film.rtAudience(
        pct: '${(r.value * 10).round()}',
      ),
      RatingSource.tmdb => 'TMDB ${r.value.toStringAsFixed(1)}',
      RatingSource.unknown => '★ ${r.value.toStringAsFixed(1)}',
    },
];

/// What a page asks for: which title, and what TMDB would need to find a
/// trailer the server lacks. A record, so equal requests share one lookup.
typedef TrailerRequest = ({
  String serverId,
  String itemId,
  String? tmdbId,
  bool tv,
});

/// The trailers for a title, best first; empty when there are none.
///
/// Asked once when the page opens, so the Trailer button is only drawn when
/// it will do something. TMDB is asked only when the server had nothing, a
/// key is saved, and the server knows the title's TMDB id: only that id
/// leaves the device, no title (the same consent as Settings, Metadata).
/// Any failure is "no trailer": the button is optional and must never put
/// an error on the page.
final trailersProvider = FutureProvider.autoDispose
    .family<List<MediaTrailer>, TrailerRequest>((ref, req) async {
      MediaServer? server;
      for (final s in ref.watch(connectedServersProvider)) {
        if (s.id == req.serverId) server = s.service;
      }
      final own = server == null
          ? const <MediaTrailer>[]
          : await server.trailers(req.itemId);
      if (own.isNotEmpty) return own;

      final tmdbId = int.tryParse(req.tmdbId ?? '');
      if (tmdbId == null) return const [];
      try {
        final key = await ref.watch(tmdbKeyProvider.future);
        if (key == null) return const [];
        final url = await TmdbClient(key: key).trailerUrl(tmdbId, tv: req.tv);
        return url == null ? const [] : [MediaTrailer.elsewhere(url)];
      } catch (_) {
        return const [];
      }
    });

/// Plays [trailer]: a file on the server in the app's player, a link in the
/// app the device opens it with (the YouTube app on a TV or phone, the
/// browser on Windows).
Future<void> openTrailer(
  BuildContext context,
  String serverId,
  MediaTrailer trailer,
) async {
  final id = trailer.itemId;
  if (id != null) {
    await context.push(
      '/play/${Uri.encodeComponent(serverId)}/${Uri.encodeComponent(id)}'
      '?trailer=1',
    );
    return;
  }
  final messenger = ScaffoldMessenger.maybeOf(context);
  var opened = false;
  try {
    opened = await launchUrl(
      Uri.parse(trailer.url!),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {}
  if (!opened) {
    messenger?.showSnackBar(SnackBar(content: Text(tr.film.trailerNoApp)));
  }
}
