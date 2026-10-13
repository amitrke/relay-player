import 'dart:convert';

import '../local/app_settings_store.dart';

/// Where a download is. Only [complete] is playable.
enum DownloadState {
  /// Waiting for its turn. One download runs at a time.
  queued,
  downloading,

  /// Stopped by the person, or by the app closing (§18.3). The partial file is
  /// kept, and resuming continues it.
  paused,

  /// Stopped by an error. The partial file is kept for a retry.
  failed,
  complete,
}

/// One Plex item saved on this device (§18).
///
/// **Holds no token and no URL.** The URL that fetches a file carries the
/// server's token (§3), so it is built fresh from the live connection each time
/// a download starts or resumes and is gone when the fetch ends. What is kept
/// here is only what the Downloads list needs, plus the unsigned artwork path
/// that history keeps for the same reason.
class DownloadRecord {
  const DownloadRecord({
    required this.serverId,
    required this.ratingKey,
    required this.title,
    required this.addedAt,
    this.state = DownloadState.queued,
    this.fileName,
    this.totalBytes,
    this.receivedBytes = 0,
    this.duration = Duration.zero,
    this.posterPath,
    this.isEpisode = false,
    this.error,
  });

  final String serverId;
  final String ratingKey;
  final String title;
  final DateTime addedAt;
  final DownloadState state;

  /// The file inside the downloads directory, once the source has been
  /// resolved. Not a path: the directory is decided at run time.
  final String? fileName;

  /// The size Plex reported, or the size on disk once complete.
  final int? totalBytes;

  /// How much is on disk. Live progress is held in memory and only written
  /// when the state changes, so this is the last settled value.
  final int receivedBytes;
  final Duration duration;
  final String? posterPath;
  final bool isEpisode;

  /// Why it [DownloadState.failed], in words for the person.
  final String? error;

  /// `plex:<server>:<ratingKey>`, matching the history key for the same title.
  String get key => keyOf(serverId, ratingKey);

  static String keyOf(String serverId, String ratingKey) =>
      'plex:$serverId:$ratingKey';

  bool get isComplete => state == DownloadState.complete;

  /// 0 to 1, or null when the total is not known.
  double? get fraction {
    final total = totalBytes;
    if (total == null || total <= 0) return null;
    return (receivedBytes / total).clamp(0.0, 1.0);
  }

  DownloadRecord copyWith({
    String? title,
    DownloadState? state,
    String? fileName,
    int? totalBytes,
    int? receivedBytes,
    Duration? duration,
    String? posterPath,
    bool? isEpisode,
    String? error,
    bool clearError = false,
  }) => DownloadRecord(
    serverId: serverId,
    ratingKey: ratingKey,
    title: title ?? this.title,
    addedAt: addedAt,
    state: state ?? this.state,
    fileName: fileName ?? this.fileName,
    totalBytes: totalBytes ?? this.totalBytes,
    receivedBytes: receivedBytes ?? this.receivedBytes,
    duration: duration ?? this.duration,
    posterPath: posterPath ?? this.posterPath,
    isEpisode: isEpisode ?? this.isEpisode,
    error: clearError ? null : (error ?? this.error),
  );

  Map<String, Object?> toJson() => {
    'serverId': serverId,
    'ratingKey': ratingKey,
    'title': title,
    'addedAt': addedAt.toUtc().toIso8601String(),
    'state': state.name,
    'fileName': ?fileName,
    'totalBytes': ?totalBytes,
    'receivedBytes': receivedBytes,
    'durationMs': duration.inMilliseconds,
    'posterPath': ?posterPath,
    'isEpisode': isEpisode,
    'error': ?error,
  };

  static DownloadRecord? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final serverId = raw['serverId'];
    final ratingKey = raw['ratingKey'];
    final title = raw['title'];
    if (serverId is! String || ratingKey is! String || title is! String) {
      return null;
    }
    return DownloadRecord(
      serverId: serverId,
      ratingKey: ratingKey,
      title: title,
      addedAt: DateTime.tryParse('${raw['addedAt']}') ?? DateTime.now(),
      state:
          DownloadState.values
              .where((s) => s.name == raw['state'])
              .firstOrNull ??
          DownloadState.paused,
      fileName: raw['fileName'] is String ? raw['fileName'] as String : null,
      totalBytes: raw['totalBytes'] is int ? raw['totalBytes'] as int : null,
      receivedBytes: raw['receivedBytes'] is int
          ? raw['receivedBytes'] as int
          : 0,
      duration: Duration(
        milliseconds: raw['durationMs'] is int ? raw['durationMs'] as int : 0,
      ),
      posterPath: raw['posterPath'] is String
          ? raw['posterPath'] as String
          : null,
      isEpisode: raw['isEpisode'] == true,
      error: raw['error'] is String ? raw['error'] as String : null,
    );
  }
}

/// The download records, in the settings box (§3).
///
/// Not secret, so the box is the right place; the token that fetches a file is
/// never among the fields (see [DownloadRecord]).
class DownloadStore {
  DownloadStore(this._settings);

  final AppSettingsStore _settings;

  static const _key = 'downloads.items';

  List<DownloadRecord> load() {
    final raw = _settings.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [for (final e in decoded) ?DownloadRecord.fromJson(e)];
    } on FormatException {
      return const [];
    }
  }

  Future<void> save(List<DownloadRecord> records) => _settings.setString(
    _key,
    jsonEncode([for (final r in records) r.toJson()]),
  );
}
