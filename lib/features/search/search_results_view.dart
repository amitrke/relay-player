import 'package:flutter/material.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../domain/models/catalog_item.dart';
import '../library/poster_grid.dart';
import 'search_filters.dart';

/// The filter chips and the grid they narrow.
class SearchResultsView extends StatelessWidget {
  const SearchResultsView({
    super.key,
    required this.all,
    required this.filters,
    required this.sourceNames,
    required this.onFilters,
  });

  final List<CatalogItem> all;
  final SearchFilters filters;

  /// Source id to the user's own label for it. Shown in the app only, which is
  /// what every player does; never written into our own artefacts (§1).
  final Map<String, String> sourceNames;
  final ValueChanged<SearchFilters> onFilters;

  @override
  Widget build(BuildContext context) {
    final f = RelayLayout.of(context);
    final options = SearchFilterOptions.of(all);
    final shown = filters.apply(all);

    // A chip stays while its filter is set even if the options behind it have
    // thinned out, so there is always a way to turn it off.
    final chips = [
      if (options.offersKind || filters.kind != null)
        _FilterChip(
          label: 'Type',
          value: switch (filters.kind) {
            null => null,
            CatalogKind.movie => 'Movies',
            CatalogKind.show => 'Series',
          },
          onTap: () async {
            final picked = await _pick<CatalogKind>(
              context,
              title: 'Type',
              current: filters.kind,
              choices: [
                if (options.kinds.contains(CatalogKind.movie))
                  (CatalogKind.movie, 'Movies'),
                if (options.kinds.contains(CatalogKind.show))
                  (CatalogKind.show, 'Series'),
              ],
            );
            if (picked != null) onFilters(filters.with_(kind: picked));
          },
        ),
      if (options.offersSource || filters.sourceId != null)
        _FilterChip(
          label: 'Source',
          value: filters.sourceId == null
              ? null
              : sourceNames[filters.sourceId] ?? 'Unknown source',
          onTap: () async {
            final picked = await _pick<String>(
              context,
              title: 'Source',
              current: filters.sourceId,
              choices: [
                for (final id in options.sourceIds)
                  (id, sourceNames[id] ?? 'Unknown source'),
              ],
            );
            if (picked != null) onFilters(filters.with_(sourceId: picked));
          },
        ),
      if (options.offersYear || filters.decade != null)
        _FilterChip(
          label: 'Year',
          value: filters.decade == null ? null : decadeLabel(filters.decade!),
          onTap: () async {
            final picked = await _pick<int>(
              context,
              title: 'Year',
              current: filters.decade,
              choices: [for (final d in options.decades) (d, decadeLabel(d))],
            );
            if (picked != null) onFilters(filters.with_(decade: picked));
          },
        ),
      if (options.offersLanguage || filters.language != null)
        _FilterChip(
          label: 'Language',
          value: filters.language,
          onTap: () async {
            final picked = await _pick<String>(
              context,
              title: 'Language',
              // Said where it is chosen, not only in the docs: this is a guess
              // from panel category names, and Plex titles are never in it.
              note:
                  'Guessed from IPTV category names. Plex titles have no '
                  'language here.',
              current: filters.language,
              choices: [for (final l in options.languages) (l, l)],
            );
            if (picked != null) onFilters(filters.with_(language: picked));
          },
        ),
      // From here on the data is TMDB's, present only with a key in Settings.
      if (options.offersGenre || filters.genre != null)
        _FilterChip(
          label: 'Genre',
          value: filters.genre,
          onTap: () async {
            final picked = await _pick<String>(
              context,
              title: 'Genre',
              current: filters.genre,
              choices: [for (final g in options.genres) (g, g)],
            );
            if (picked != null) onFilters(filters.with_(genre: picked));
          },
        ),
      if (options.offersRating || filters.minRating != null)
        _FilterChip(
          label: 'Rating',
          value: filters.minRating == null
              ? null
              : '${filters.minRating!.toStringAsFixed(0)}+',
          onTap: () async {
            final picked = await _pick<double>(
              context,
              title: 'Rating',
              note:
                  'TMDB user rating out of 10. Titles TMDB has no rating '
                  'for are left out.',
              current: filters.minRating,
              choices: [
                for (final r in ratingChoices) (r, '${r.toStringAsFixed(0)}+'),
              ],
            );
            if (picked != null) onFilters(filters.with_(minRating: picked));
          },
        ),
      if (options.offersOriginalLanguage || filters.originalLanguage != null)
        _FilterChip(
          label: 'Original language',
          value: filters.originalLanguage,
          onTap: () async {
            final picked = await _pick<String>(
              context,
              title: 'Original language',
              note:
                  'The language the title was made in, from TMDB. A dubbed '
                  'copy keeps its original language here.',
              current: filters.originalLanguage,
              choices: [for (final l in options.originalLanguages) (l, l)],
            );
            if (picked != null) {
              onFilters(filters.with_(originalLanguage: picked));
            }
          },
        ),
    ];

    return Column(
      children: [
        if (chips.isNotEmpty)
          SizedBox(
            height: f == RelayFormFactor.tv ? 56 : 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: RelayLayout.pagePadding(f).copyWith(top: 0, bottom: 0),
              children: [
                for (final chip in chips)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Center(child: chip),
                  ),
                if (filters.isActive)
                  Center(
                    child: _FilterChip(
                      label: 'Clear',
                      value: null,
                      plain: true,
                      onTap: () => onFilters(const SearchFilters()),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: shown.isEmpty
              ? LibraryEmptyState(
                  icon: Icons.filter_alt_off_outlined,
                  message: 'Nothing matches those filters.',
                  actionLabel: 'Clear filters',
                  onAction: () => onFilters(const SearchFilters()),
                )
              : PosterGrid(items: shown, showKind: true),
        ),
      ],
    );
  }
}

/// A pill that names a filter and, once set, its value.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.onTap,
    this.plain = false,
  });

  final String label;

  /// Null while the filter is off.
  final String? value;
  final VoidCallback onTap;

  /// No dropdown arrow, for an action rather than a filter.
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final on = value != null;
    final size = f == RelayFormFactor.tv ? 15.0 : 13.0;

    return RelayTappable(
      borderRadius: 20,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: on ? t.accent.withValues(alpha: 0.18) : t.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? t.accent : t.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              on ? '$label: $value' : label,
              style: TextStyle(
                color: on ? t.ink : t.inkDim,
                fontSize: size,
                fontWeight: on ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (!plain) ...[
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, size: size + 4, color: t.inkDim),
            ],
          ],
        ),
      ),
    );
  }
}

/// A sheet of focusable rows, with "Any" first. Returns a one-element record so
/// that choosing "Any" (null) is distinguishable from dismissing the sheet.
///
/// Built from [RelayTappable] like the Library's sort sheet, for the same
/// reason: Material's menu items have not been checked with a remote.
Future<(T?,)?> _pick<T>(
  BuildContext context, {
  required String title,
  required T? current,
  required List<(T, String)> choices,
  String? note,
}) {
  return showModalBottomSheet<(T?,)>(
    context: context,
    backgroundColor: RelayTheme.of(context).surface,
    isScrollControlled: true,
    builder: (context) {
      final t = RelayTheme.of(context);
      final f = RelayLayout.of(context);

      Widget row(T? value, String label) => RelayTappable(
        borderRadius: 10,
        autofocus: value == current,
        onTap: () => Navigator.of(context).pop((value,)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: t.ink,
                    fontSize: RelayLayout.bodySize(f) + 1,
                  ),
                ),
              ),
              if (value == current) Icon(Icons.check, color: t.accent),
            ],
          ),
        ),
      );

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: Text(
                  title,
                  style: TextStyle(
                    color: t.inkDim,
                    fontSize: RelayLayout.bodySize(f),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (note != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Text(
                    note,
                    style: TextStyle(
                      color: t.inkDim,
                      fontSize: RelayLayout.bodySize(f) - 3,
                      height: 1.4,
                    ),
                  ),
                ),
              row(null, 'Any'),
              for (final (value, label) in choices) row(value, label),
            ],
          ),
        ),
      );
    },
  );
}
