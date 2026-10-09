import 'dart:convert';

import '../filesystem/smb_source.dart';
import '../xtream/xtream_account_store.dart';

/// The things that can be moved to another device, as the user sees them.
///
/// Plex is not here, on purpose (§17.3): a Plex token is bound to the client
/// identifier that requested it, so a copied one cannot be assumed to work, and
/// linking Plex on a TV is already a code on the screen and nothing to type.
enum TransferItem {
  preferences(
    'Preferences',
    'Playback and subtitle choices, hidden words and library placement.',
  ),
  xtream('IPTV accounts', 'Logins and the categories and channels you chose.'),
  smb('Network shares', 'SMB shares and their passwords.'),
  tmdb('TMDB key', 'Your own key for genre, rating and language filters.'),
  ai('AI provider', 'The provider, its model and your key.');

  const TransferItem(this.label, this.description);

  final String label;
  final String description;
}

/// Thrown for a bundle that is not one of ours or is from a newer app.
class TransferFormatException implements Exception {
  const TransferFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// An Xtream account with the password that lives in secure storage.
class TransferredXtream {
  const TransferredXtream(this.account, this.password);

  final XtreamAccount account;
  final String? password;
}

/// An SMB share with the password that lives in secure storage.
class TransferredSmb {
  const TransferredSmb(this.share, this.password);

  final SmbShare share;
  final String? password;
}

/// The AI provider and its key.
class TransferredAi {
  const TransferredAi(this.config, this.key);

  /// `AiProviderConfig.toJson()`, kept as the map it is so this file does not
  /// need to know what is in it.
  final Map<String, String> config;
  final String? key;
}

/// Everything one device sends another, before it is sealed (§17).
///
/// **What it deliberately leaves out:**
/// - Consent. §8.2's acknowledgement for Advanced sources and §9.3's per
///   feature, per provider AI consent are moments the person on *that* device
///   has to have. Copying a "yes" would skip them, so accounts arrive switched
///   off if the receiver has not accepted §8.2, and AI arrives asking.
/// - The Advanced sources switch itself, for the same reason.
/// - Anything cached, and watch history and favourites (§16.3 rules out
///   syncing them, and this is a one-off copy, not sync).
/// - Plex (see [TransferItem]).
class TransferBundle {
  TransferBundle({
    required this.createdAt,
    this.preferences = const {},
    this.xtream = const [],
    this.smb = const [],
    this.tmdbKey,
    this.ai,
  });

  static const format = 'subnext-transfer';
  static const version = 1;

  final DateTime createdAt;

  /// Only keys in [TransferPreferences]; anything else is dropped on read.
  final Map<String, Object> preferences;
  final List<TransferredXtream> xtream;
  final List<TransferredSmb> smb;
  final String? tmdbKey;
  final TransferredAi? ai;

  /// What this bundle contains.
  Set<TransferItem> get items => {
    if (preferences.isNotEmpty) TransferItem.preferences,
    if (xtream.isNotEmpty) TransferItem.xtream,
    if (smb.isNotEmpty) TransferItem.smb,
    if (tmdbKey != null) TransferItem.tmdb,
    if (ai != null) TransferItem.ai,
  };

  /// A line per item for the confirmation screen. Names and counts, never a
  /// host, username or key: this appears on a TV across a living room.
  String describe(TransferItem item) => switch (item) {
    TransferItem.preferences =>
      '${preferences.length} setting${preferences.length == 1 ? '' : 's'}',
    TransferItem.xtream => _count(xtream.length, 'account'),
    TransferItem.smb => _count(smb.length, 'share'),
    TransferItem.tmdb => 'Key',
    TransferItem.ai => 'Provider and key',
  };

  static String _count(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

  /// This bundle cut down to [keep], for a receiver that declined some of it.
  TransferBundle only(Set<TransferItem> keep) => TransferBundle(
    createdAt: createdAt,
    preferences: keep.contains(TransferItem.preferences) ? preferences : {},
    xtream: keep.contains(TransferItem.xtream) ? xtream : const [],
    smb: keep.contains(TransferItem.smb) ? smb : const [],
    tmdbKey: keep.contains(TransferItem.tmdb) ? tmdbKey : null,
    ai: keep.contains(TransferItem.ai) ? ai : null,
  );

  List<int> encode() => utf8.encode(
    jsonEncode({
      'format': format,
      'version': version,
      'createdAt': createdAt.toUtc().toIso8601String(),
      if (preferences.isNotEmpty) 'preferences': preferences,
      if (xtream.isNotEmpty)
        'xtream': [
          for (final x in xtream)
            {
              'account': x.account.toJson(),
              if (x.password != null) 'password': x.password,
            },
        ],
      if (smb.isNotEmpty)
        'smb': [
          for (final s in smb)
            {
              'share': s.share.toJson(),
              if (s.password != null) 'password': s.password,
            },
        ],
      if (tmdbKey != null) 'tmdbKey': tmdbKey,
      if (ai != null)
        'ai': {'config': ai!.config, if (ai!.key != null) 'key': ai!.key},
    }),
  );

  /// Reads a bundle, tolerating what it does not understand inside it and
  /// refusing what it cannot trust: the wrong format, or a version this app
  /// does not know how to read.
  static TransferBundle decode(List<int> bytes) {
    final Object? raw;
    try {
      raw = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const TransferFormatException('That was not a settings bundle.');
    }
    if (raw is! Map || raw['format'] != format) {
      throw const TransferFormatException('That was not a settings bundle.');
    }
    final v = raw['version'];
    if (v is! int || v > version) {
      throw const TransferFormatException(
        'That bundle is from a newer version of the app. Update this device '
        'and try again.',
      );
    }

    return TransferBundle(
      createdAt: DateTime.tryParse('${raw['createdAt']}') ?? DateTime.now(),
      preferences: TransferPreferences.filter(raw['preferences']),
      xtream: [
        if (raw['xtream'] case final List list)
          for (final e in list)
            if (e is Map && XtreamAccount.fromJson(e['account']) != null)
              TransferredXtream(
                XtreamAccount.fromJson(e['account'])!,
                _text(e['password']),
              ),
      ],
      smb: [
        if (raw['smb'] case final List list)
          for (final e in list)
            if (e is Map && SmbShare.fromJson(e['share']) != null)
              TransferredSmb(SmbShare.fromJson(e['share'])!, _text(e['password'])),
      ],
      tmdbKey: _text(raw['tmdbKey']),
      ai: _ai(raw['ai']),
    );
  }

  static String? _text(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  static TransferredAi? _ai(Object? raw) {
    if (raw is! Map || raw['config'] is! Map) return null;
    final config = <String, String>{
      for (final e in (raw['config'] as Map).entries)
        if (e.key is String && e.value is String)
          e.key as String: e.value as String,
    };
    if (config.isEmpty) return null;
    return TransferredAi(config, _text(raw['key']));
  }
}

/// The settings-box keys a bundle may carry, and what each must be.
///
/// An allowlist rather than "whatever the sender had", so a bundle can never
/// write a key the receiver did not agree to move: not the Advanced sources
/// switch, not `onboardingSeen`, not any secret the box must never hold (§3).
/// The strings are the keys the controllers use; `transfer_test.dart` writes
/// through the real controllers and checks they come out the other end, so a
/// renamed key fails there instead of silently dropping out of transfers.
class TransferPreferences {
  const TransferPreferences._();

  static const bools = {'subtitles.on'};

  static const strings = {
    'playback.skipSeconds',
    'playback.audioLanguage',
    'subtitles.language',
    'subtitles.size',
    // A JSON list the hidden-words controller reads back itself.
    'iptv.hiddenWords',
  };

  static const stringMaps = {'plex.libraryMapping'};

  static Iterable<String> get keys => [...bools, ...strings, ...stringMaps];

  /// Longest single value accepted. The biggest real one is the library
  /// mapping, a few hundred bytes per Plex library.
  static const maxValueLength = 64 * 1024;

  /// [raw] cut down to allowlisted keys holding the right type.
  static Map<String, Object> filter(Object? raw) {
    if (raw is! Map) return {};
    final out = <String, Object>{};
    for (final e in raw.entries) {
      final key = e.key;
      final value = e.value;
      if (key is! String) continue;
      if (bools.contains(key) && value is bool) {
        out[key] = value;
      } else if (strings.contains(key) &&
          value is String &&
          value.length <= maxValueLength) {
        out[key] = value;
      } else if (stringMaps.contains(key) && value is Map) {
        final map = {
          for (final m in value.entries)
            if (m.key is String && m.value is String)
              m.key as String: m.value as String,
        };
        if (jsonEncode(map).length <= maxValueLength) out[key] = map;
      }
    }
    return out;
  }
}
