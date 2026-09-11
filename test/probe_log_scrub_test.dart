import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/features/_spike/probe_log.dart';

/// Phase 0 transcripts get pasted into docs/PHASE0_FINDINGS.md in a public
/// repo. A leak here is a credential leak, so the scrubbing is tested rather
/// than assumed.
void main() {
  setUpAll(() {
    ProbeLog.registerSecrets(['7399143046', 'amitkumar10', 'abc']);
  });

  test('scrubs a password embedded in third-party error text', () {
    // The real leak: media_kit's error string, logged verbatim.
    const leak = 'player error: Failed to open '
        'http://ogold.org:8080/live/amitkumar10/7399143046/244987.ts.';
    final out = ProbeLog.scrub(leak);
    expect(out, isNot(contains('7399143046')));
    expect(out, isNot(contains('amitkumar10')));
    expect(out, contains('ogold.org:8080'), reason: 'host should survive');
    expect(out, contains('244987.ts'), reason: 'stream id should survive');
  });

  test('scrubs through the log sink, not just the helper', () {
    final log = ProbeLog();
    log.bad('Failed: http://h/live/amitkumar10/7399143046/1.ts');
    expect(log.lines.single.message, isNot(contains('7399143046')));
    expect(log.asText(), isNot(contains('7399143046')));
  });

  test('ignores values too short to be credentials', () {
    // 'abc' was registered but is under the length floor; scrubbing it would
    // mangle ordinary words.
    expect(ProbeLog.scrub('abcdef'), 'abcdef');
  });

  test('leaves unrelated text untouched', () {
    const clean = 'get_live_streams OK (2317 ms) — 15951 live streams';
    expect(ProbeLog.scrub(clean), clean);
  });

  test('a Plex token registered at runtime is scrubbed afterwards', () {
    const token = 'xZD8AXkyzKM7FPx5gkEU';
    const url = 'https://x.plex.direct:32400/video/:/transcode/universal/'
        'start.m3u8?X-Plex-Token=$token&session=phase0-1';
    // Before registration it is visible...
    expect(ProbeLog.scrub(url), contains(token));
    ProbeLog.registerSecrets([token]);
    // ...and hidden once pollPin has handed it over.
    expect(ProbeLog.scrub(url), isNot(contains(token)));
    expect(ProbeLog.scrub(url), contains('session=phase0-1'));
  });
}
