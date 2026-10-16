import '../../domain/models/media_server.dart';

/// The watch-history services a person can connect (architecture.md §19).
enum TrackerKind {
  trakt,
  simkl,
  anilist,
  mal;

  /// Product names, the same in every language.
  String get label => switch (this) {
    trakt => 'Trakt',
    simkl => 'Simkl',
    anilist => 'AniList',
    mal => 'MyAnimeList',
  };

  /// AniList and MyAnimeList list anime only, and match by title, not by
  /// database id; only titles the server tags as anime go to them (§19.3).
  bool get animeOnly => this == anilist || this == mal;

  static TrackerKind? fromName(String? name) {
    for (final k in values) {
      if (k.name == name) return k;
    }
    return null;
  }
}

/// App credentials, compiled in from CI secrets with `--dart-define`
/// (RELEASING.md, "Tracker credentials"). None is in the repository: it is
/// public, and these identify the app to each service. A tracker whose id is
/// empty in a build is not offered in that build at all.
///
/// Trakt's token exchange also needs the app's client secret. Shipping a
/// secret inside an app means anyone can extract it; Trakt's own guidance
/// for installed apps accepts that, and what it protects (rate limits, the
/// app's name on the consent page) is the app's, not the user's (§19.2).
class TrackerCredentials {
  const TrackerCredentials({
    this.traktId = const String.fromEnvironment('TRAKT_CLIENT_ID'),
    this.traktSecret = const String.fromEnvironment('TRAKT_CLIENT_SECRET'),
    this.simklId = const String.fromEnvironment('SIMKL_CLIENT_ID'),
    this.anilistId = const String.fromEnvironment('ANILIST_CLIENT_ID'),
    this.malId = const String.fromEnvironment('MAL_CLIENT_ID'),
  });

  final String traktId;
  final String traktSecret;
  final String simklId;
  final String anilistId;
  final String malId;

  bool has(TrackerKind kind) => switch (kind) {
    TrackerKind.trakt => traktId.isNotEmpty && traktSecret.isNotEmpty,
    TrackerKind.simkl => simklId.isNotEmpty,
    TrackerKind.anilist => anilistId.isNotEmpty,
    TrackerKind.mal => malId.isNotEmpty,
  };
}

/// A signed-in tracker account. Secret (§3): secure storage only.
class TrackerToken {
  const TrackerToken({
    required this.access,
    this.refresh,
    this.expiresAt,
    this.userName,
  });

  final String access;
  final String? refresh;
  final DateTime? expiresAt;

  /// Shown in Settings so the person can see which account it is.
  final String? userName;

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  TrackerToken withUser(String? name) => TrackerToken(
    access: access,
    refresh: refresh,
    expiresAt: expiresAt,
    userName: name,
  );

  Map<String, Object?> toJson() => {
    'access': access,
    'refresh': ?refresh,
    'expiresAt': ?expiresAt?.toUtc().toIso8601String(),
    'user': ?userName,
  };

  static TrackerToken? fromJson(Object? raw) {
    if (raw is! Map || raw['access'] is! String) return null;
    return TrackerToken(
      access: raw['access'] as String,
      refresh: raw['refresh'] as String?,
      expiresAt: DateTime.tryParse('${raw['expiresAt'] ?? ''}'),
      userName: raw['user'] as String?,
    );
  }
}

/// How a sign-in proceeds, which decides what the screen shows.
sealed class SignInStart {
  const SignInStart();
}

/// A short code typed at a web address on any device (Trakt, Simkl). The
/// TV-friendly kind: nothing is typed on the TV.
class DeviceCodeSignIn extends SignInStart {
  const DeviceCodeSignIn({
    required this.userCode,
    required this.verificationUrl,
    required this.deviceCode,
    required this.expiresAt,
    required this.interval,
  });

  final String userCode;
  final String verificationUrl;

  /// What polling asks about. Not shown.
  final String deviceCode;
  final DateTime expiresAt;
  final Duration interval;
}

/// A web page that ends by handing something back: a token shown on the page
/// (AniList), or a code in the address it redirects to (MyAnimeList). The
/// person pastes it, or, on a device that has a browser, the app catches the
/// redirect itself.
class BrowserSignIn extends SignInStart {
  const BrowserSignIn({required this.url, this.verifier, this.state});

  final String url;

  /// PKCE verifier, for MyAnimeList. Never leaves this device until the
  /// token exchange.
  final String? verifier;
  final String? state;
}

/// Not finished yet: a device code that has not been approved.
class SignInPending implements Exception {
  const SignInPending();
}

/// The person refused, or the code ran out. The message is fit to show.
class SignInFailed implements Exception {
  const SignInFailed(this.message);
  final String message;

  @override
  String toString() => message;
}

/// A tracker call that failed in a way worth retrying later (network,
/// server trouble). Anything else drops the event.
class TrackerUnavailable implements Exception {
  const TrackerUnavailable(this.message);
  final String message;

  @override
  String toString() => message;
}

/// The token is no longer accepted and could not be refreshed.
class TrackerSignedOut implements Exception {
  const TrackerSignedOut();
}

/// One finished film or episode, as much as a tracker needs to find it.
///
/// Built from a server's [MediaItem]; nothing in it identifies the server or
/// the person beyond what was watched and when (§19.1).
class WatchedItem {
  const WatchedItem({
    required this.isEpisode,
    required this.title,
    required this.watchedAt,
    this.year,
    this.ids = ExternalIds.none,
    this.showTitle,
    this.showYear,
    this.showIds = ExternalIds.none,
    this.season,
    this.episode,
    this.isAnime = false,
  });

  final bool isEpisode;

  /// The film's title, or the episode's.
  final String title;
  final int? year;
  final ExternalIds ids;
  final String? showTitle;
  final int? showYear;
  final ExternalIds showIds;
  final int? season;
  final int? episode;
  final DateTime watchedAt;
  final bool isAnime;

  /// Same title, same moment: a duplicate, whichever path reported it.
  String get key =>
      '${isEpisode ? 'e' : 'm'}|${showTitle ?? ''}|$title|$season|$episode';

  Map<String, Object?> toJson() => {
    'ep': isEpisode,
    't': title,
    'y': ?year,
    'ids': _idsJson(ids),
    'st': ?showTitle,
    'sy': ?showYear,
    'sids': _idsJson(showIds),
    's': ?season,
    'e': ?episode,
    'at': watchedAt.toUtc().toIso8601String(),
    'anime': isAnime,
  };

  static Map<String, String> _idsJson(ExternalIds i) => {
    'imdb': ?i.imdb,
    'tmdb': ?i.tmdb,
    'tvdb': ?i.tvdb,
  };

  static ExternalIds _idsFrom(Object? raw) => raw is Map
      ? ExternalIds(
          imdb: raw['imdb'] as String?,
          tmdb: raw['tmdb'] as String?,
          tvdb: raw['tvdb'] as String?,
        )
      : ExternalIds.none;

  static WatchedItem? fromJson(Object? raw) {
    if (raw is! Map || raw['t'] is! String) return null;
    final at = DateTime.tryParse('${raw['at']}');
    if (at == null) return null;
    return WatchedItem(
      isEpisode: raw['ep'] == true,
      title: raw['t'] as String,
      year: raw['y'] as int?,
      ids: _idsFrom(raw['ids']),
      showTitle: raw['st'] as String?,
      showYear: raw['sy'] as int?,
      showIds: _idsFrom(raw['sids']),
      season: raw['s'] as int?,
      episode: raw['e'] as int?,
      watchedAt: at,
      isAnime: raw['anime'] == true,
    );
  }

  /// [item] finished at [at]. [show] is the episode's show when the caller
  /// fetched it: an episode's own record often lacks the show's ids, year
  /// and genres, which are what the trackers match on.
  static WatchedItem? from(MediaItem item, {MediaItem? show, DateTime? at}) {
    final episode = item.type == MediaItemType.episode;
    if (!episode && item.type != MediaItemType.movie) return null;
    final genres = [...item.genres, ...?show?.genres];
    return WatchedItem(
      isEpisode: episode,
      title: item.title,
      year: item.year,
      ids: item.ids,
      showTitle: show?.title ?? item.showTitle,
      showYear: show?.year,
      showIds: show?.ids ?? item.showIds,
      season: item.parentIndex,
      episode: item.index,
      watchedAt: at ?? DateTime.now(),
      isAnime: genres.any((g) => g.toLowerCase().contains('anime')),
    );
  }
}

/// One watch-history service.
abstract class Tracker {
  TrackerKind get kind;

  Future<SignInStart> startSignIn();

  /// Finishes a sign-in. For a device code, throws [SignInPending] until it
  /// is approved. For a browser sign-in, [pasted] is what the person copied
  /// (a token, or the address the browser was sent to).
  Future<TrackerToken> finishSignIn(SignInStart start, {String? pasted});

  /// Exchanges a refresh token for a new access token, where the service has
  /// them. Throws [TrackerSignedOut] when it cannot.
  Future<TrackerToken> refresh(TrackerToken token);

  /// Records [item] as watched. Throws [TrackerUnavailable] to be retried,
  /// [TrackerSignedOut] when the token is no longer good; returns false when
  /// the service could not find the title (nothing to retry).
  Future<bool> markWatched(WatchedItem item, TrackerToken token);
}
