import '../i18n/strings.g.dart';

/// Any `scheme://...` address in [text] replaced by "(address hidden)".
///
/// For every message that reaches the screen or the log from a source's own
/// error. A panel stream is `{host}/live/{username}/{password}/{id}.ts` and its
/// API takes the same pair as query parameters (§4), and libmpv and dio both
/// put the address they failed on into their error text: on 2026-10-31 a
/// channel that would not open showed its whole URL, line password included,
/// on the TV's error screen. §4 keeps that URL out of routes and logs; this
/// keeps it off screens and out of `debugPrint`, where it is just as visible
/// to anyone in the room or reading a bug report.
///
/// Whole addresses, not only their credentials: the host names the provider,
/// which this app's own text never does (CLAUDE.md §1), and a server address
/// says nothing a person can act on that the message around it does not.
String redactAddresses(String text) => text.replaceAll(
  RegExp(r'[a-zA-Z][a-zA-Z0-9+.\-]*://\S+'),
  tr.errors.addressHidden,
);
