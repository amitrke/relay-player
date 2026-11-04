/// A login read out of the one long link a provider sends.
///
/// **Why this exists (2026-11-03).** Most providers send a subscriber one URL,
/// usually called an M3U link or playlist URL, in a welcome email, and the
/// Xtream login is inside it:
/// `http://<panel-host>:8080/get.php?username=…&password=…&type=m3u_plus`.
/// The add form asked for server, username and
/// password separately, so people had to take that link apart by hand, which
/// is the step that made the setup read as a tool for experts. This takes it
/// apart for them.
///
/// **Only the pasted text is read.** Nothing is fetched to parse it, and the
/// result only fills the same three fields the form already has, which are
/// then verified exactly as typed ones are. That keeps it clear of §8.3: this
/// is not a profile import, it does not reach any address beyond the one the
/// user gave, and it changes nothing but the form.
///
/// Recognised shapes, all seen in the wild and none of them standardised:
/// - `…/get.php`, `…/player_api.php`, `…/xmltv.php` or `…/panel_api.php` with
///   `username` and `password` in the query;
/// - a stream URL, `…/live/<user>/<pass>/<id>.<ext>` (also `movie`,
///   `series`, and the bare `…/<user>/<pass>/<id>` form some players share).
///
/// Anything else is null rather than a guess: a wrong split would be verified
/// against the provider and fail with "wrong username or password", which
/// reads as the user's mistake.
class ProviderLink {
  const ProviderLink({
    required this.host,
    required this.username,
    required this.password,
  });

  /// `scheme://host[:port]`, the shape the add form normalises to.
  final String host;
  final String username;
  final String password;

  static const _queryEndpoints = {
    'get.php',
    'player_api.php',
    'xmltv.php',
    'panel_api.php',
  };

  static const _streamKinds = {'live', 'movie', 'series', 'timeshift'};

  static ProviderLink? tryParse(String raw) {
    final text = _clean(raw);
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return null;
    }
    if (uri.host.isEmpty) return null;
    final host =
        '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty && _queryEndpoints.contains(segments.last)) {
      final user = uri.queryParameters['username']?.trim() ?? '';
      final pass = uri.queryParameters['password'] ?? '';
      if (user.isEmpty || pass.isEmpty) return null;
      return ProviderLink(host: host, username: user, password: pass);
    }

    // A stream URL: the login is the two segments before the stream id.
    // With a kind first (`live/…`) there must be exactly kind, user, pass, id;
    // the bare form must be exactly user, pass, id, so that an ordinary path
    // such as `/files/a/b` is not read as a login.
    if (segments.length == 4 && _streamKinds.contains(segments[0])) {
      return ProviderLink(
        host: host,
        username: segments[1],
        password: segments[2],
      );
    }
    if (segments.length == 3 && _looksLikeStreamId(segments[2])) {
      return ProviderLink(
        host: host,
        username: segments[0],
        password: segments[1],
      );
    }
    return null;
  }

  /// What arrives from an email or a chat: surrounding whitespace, angle
  /// brackets or quotes, a link wrapped over lines, and `&amp;` where the
  /// mail client kept the HTML.
  static String _clean(String raw) {
    var s = raw.replaceAll(RegExp(r'\s+'), '');
    s = s.replaceAll('&amp;', '&');
    const wrappers = ['<>', '""', "''", '()', '[]'];
    var changed = true;
    while (changed && s.length > 1) {
      changed = false;
      for (final w in wrappers) {
        if (s.startsWith(w[0]) && s.endsWith(w[1])) {
          s = s.substring(1, s.length - 1);
          changed = true;
        }
      }
    }
    return s;
  }

  /// A stream id is a number, optionally with an extension (`1234.ts`).
  static bool _looksLikeStreamId(String segment) =>
      RegExp(r'^\d+(\.[A-Za-z0-9]+)?$').hasMatch(segment);
}
