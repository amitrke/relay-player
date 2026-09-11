// Copy this file to `spike_config.dart` and fill in your real test resources.
//
//     cp lib/features/_spike/spike_config.example.dart \
//        lib/features/_spike/spike_config.dart
//
// `spike_config.dart` is gitignored. Do NOT commit real credentials -- this is
// a public repo, and an Xtream provider credential in git history is exactly
// the kind of thing docs/architecture.md S1 spends its whole risk budget
// avoiding. The probes read these values but never persist or transmit them
// anywhere other than the host you point them at.

class SpikeConfig {
  // --- Xtream (S4) -----------------------------------------------------
  // Host must include scheme and port, e.g. 'http://line.example.com:8080'.
  static const String xtreamHost = '';
  static const String xtreamUsername = '';
  static const String xtreamPassword = '';

  // --- M3U / XMLTV (S5) ------------------------------------------------
  // Any playlist URL. A large XMLTV guide is the interesting case for the
  // parse probe -- small files won't reveal the main-isolate jank S5 warns of.
  static const String m3uUrl = '';
  static const String xmltvUrl = '';

  // --- SMB (S7.2) ------------------------------------------------------
  static const String smbHost = '';        // e.g. '192.168.1.50' (no scheme)
  static const String smbShare = '';       // e.g. 'media'
  static const String smbUsername = '';
  static const String smbPassword = '';
  static const String smbDomain = '';      // often '' or 'WORKGROUP'
  // Path to a real video file on the share, for the playback bridge test.
  // e.g. '/media/movies/sample.mkv'
  static const String smbTestFilePath = '';

  // --- Direct URL probe ------------------------------------------------
  // Anything you want media_kit to chew on. Leave blank to type it in the UI.
  static const String scratchUrl = '';
}
