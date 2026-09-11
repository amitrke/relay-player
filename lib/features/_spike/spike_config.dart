/// Test resources for the Phase 0 probes, supplied at build time.
///
/// **This file is tracked and contains no secrets.** It used to be a gitignored
/// copy of a template, which meant a tracked file imported an untracked one and
/// the repo did not build from a clean clone — CI found that immediately, and
/// so would anyone cloning it.
///
/// Values come from `--dart-define`, so credentials never touch the working
/// tree at all. Pass only what the probe you are running needs:
///
/// ```
/// flutter run -d windows \
///   --dart-define=XTREAM_HOST=http://panel.example:8080 \
///   --dart-define=XTREAM_USERNAME=... \
///   --dart-define=XTREAM_PASSWORD=...
/// ```
///
/// Everything defaults to empty, and each probe reports what it is missing
/// rather than failing obscurely.
///
/// The recording rule still applies to anything written *about* a run: never
/// put a real provider host, token or LAN address into
/// docs/PHASE0_FINDINGS.md, a fixture, or a commit message. Naming a provider
/// in a public repo undercuts §1's primary-purpose argument just as much as
/// leaking the password does.
class SpikeConfig {
  // --- Xtream (§4) -----------------------------------------------------
  /// Scheme and port included, e.g. `http://line.example.com:8080`.
  static const String xtreamHost =
      String.fromEnvironment('XTREAM_HOST');
  static const String xtreamUsername =
      String.fromEnvironment('XTREAM_USERNAME');
  static const String xtreamPassword =
      String.fromEnvironment('XTREAM_PASSWORD');

  // --- M3U / XMLTV (§5) ------------------------------------------------
  /// A large XMLTV guide is the interesting case for the parse probe — small
  /// files will not reveal the main-isolate jank §5 warns about.
  static const String m3uUrl = String.fromEnvironment('M3U_URL');
  static const String xmltvUrl = String.fromEnvironment('XMLTV_URL');

  // --- SMB (§7.2) ------------------------------------------------------
  /// No scheme, e.g. `192.168.1.50`.
  static const String smbHost = String.fromEnvironment('SMB_HOST');
  static const String smbShare = String.fromEnvironment('SMB_SHARE');
  static const String smbUsername = String.fromEnvironment('SMB_USERNAME');
  static const String smbPassword = String.fromEnvironment('SMB_PASSWORD');

  /// Often empty, or `WORKGROUP`.
  static const String smbDomain = String.fromEnvironment('SMB_DOMAIN');

  /// A real video file on the share, for the playback bridge test.
  static const String smbTestFilePath =
      String.fromEnvironment('SMB_TEST_FILE');

  // --- Direct URL probe ------------------------------------------------
  /// Anything to make media_kit chew. Leave unset to type it in the UI.
  static const String scratchUrl = String.fromEnvironment('SCRATCH_URL');
}
