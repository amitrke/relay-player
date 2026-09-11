import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/features/_spike/probe_log.dart';

/// Phase 0 transcripts get pasted into docs/PHASE0_FINDINGS.md in a public
/// repo. A leak there is a credential leak, so the scrubbing is tested rather
/// than assumed.
///
/// **Every value below is fabricated.** Never paste a real host, username,
/// password or token into a test fixture — a test that guards against leaking
/// credentials is a singularly bad place to store them, and test files are as
/// public as any other tracked file.
void main() {
  const fakeUser = 'testuser99';
  const fakePass = 'not-a-real-password';
  const fakeHost = 'panel.example.invalid:8080';

  setUpAll(() {
    // 'abc' is deliberately below the length floor.
    ProbeLog.registerSecrets([fakePass, fakeUser, 'abc']);
  });

  test('scrubs credentials embedded in third-party error text', () {
    // Shape of the real leak: media_kit's error string, logged verbatim.
    const leak = 'player error: Failed to open '
        'http://$fakeHost/live/$fakeUser/$fakePass/244987.ts.';
    final out = ProbeLog.scrub(leak);
    expect(out, isNot(contains(fakePass)));
    expect(out, isNot(contains(fakeUser)));
    expect(out, contains(fakeHost), reason: 'host should survive');
    expect(out, contains('244987.ts'), reason: 'stream id should survive');
  });

  test('scrubs through the log sink, not just the helper', () {
    final log = ProbeLog();
    log.bad('Failed: http://h/live/$fakeUser/$fakePass/1.ts');
    expect(log.lines.single.message, isNot(contains(fakePass)));
    expect(log.asText(), isNot(contains(fakePass)));
  });

  test('ignores values too short to be credentials', () {
    // Scrubbing 'abc' would mangle ordinary words.
    expect(ProbeLog.scrub('abcdef'), 'abcdef');
  });

  test('leaves unrelated text untouched', () {
    const clean = 'get_live_streams OK (2317 ms) — 15951 live streams';
    expect(ProbeLog.scrub(clean), clean);
  });

  test('a token registered at runtime is scrubbed afterwards', () {
    // Stands in for the Plex auth token, which arrives from pollPin rather
    // than from config and so must register itself mid-run.
    const fakeToken = 'FAKEtoken0123456789';
    const url = 'https://server.example.invalid:32400/video/:/transcode/'
        'universal/start.m3u8?X-Plex-Token=$fakeToken&session=phase0-1';
    expect(ProbeLog.scrub(url), contains(fakeToken));
    ProbeLog.registerSecrets([fakeToken]);
    expect(ProbeLog.scrub(url), isNot(contains(fakeToken)));
    expect(ProbeLog.scrub(url), contains('session=phase0-1'));
  });
}
