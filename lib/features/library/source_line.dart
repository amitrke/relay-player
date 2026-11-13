import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../domain/models/catalog_item.dart';
import '../../i18n/strings.g.dart';
import '../accounts/media_servers.dart';
import 'poster_tile.dart' show SourceBadge;

/// Where a title page's copy comes from, and the other copies of it.
///
/// Reported 2026-11-12: with several Plex servers, nothing on a poster or on
/// its page said which server a title was on, and when two servers had it
/// the library kept one copy (library_dedupe.dart) and the other vanished.
/// "On DS220plus" names this copy; each "Also on …" opens another, in this
/// page's place, so Back still returns to wherever the person came from.
///
/// A server is named as the person's own app names it, which is fine to
/// render (CLAUDE.md §1). A panel is only ever "IPTV", as on the poster
/// badge, so a provider's label never reaches a screenshot.
class SourceLine extends ConsumerWidget {
  const SourceLine({super.key, required this.here, this.alsoOn = const []});

  /// This page's copy.
  final CatalogCopy here;

  /// The others, from the `also` parameter the page was opened with.
  final List<CatalogCopy> alsoOn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final tv = RelayLayout.of(context) == RelayFormFactor.tv;
    final servers = ref.watch(connectedServersProvider);
    String nameOf(CatalogCopy c) => switch (c.source) {
      CatalogSource.server =>
        servers.where((s) => s.id == c.sourceId).firstOrNull?.name ??
            SourceBadge.labelFor(c.source),
      CatalogSource.xtream => SourceBadge.labelFor(c.source),
    };
    final size = tv ? 15.0 : 13.0;

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          tr.library.sourceOn(name: nameOf(here)),
          style: TextStyle(
            color: t.ink,
            fontSize: size,
            fontWeight: FontWeight.w600,
          ),
        ),
        for (final other in alsoOn)
          RelayTappable(
            borderRadius: 6,
            onTap: () => context.pushReplacement(
              CatalogCopy.withCopies(other.route, [
                here,
                for (final c in alsoOn)
                  if (!c.sameAs(other)) c,
              ]),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Text(
                tr.library.alsoOn(name: nameOf(other)),
                style: TextStyle(
                  color: t.accent,
                  fontSize: size,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: t.accent,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
