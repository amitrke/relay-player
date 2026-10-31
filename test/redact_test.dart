import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/redact.dart';

/// Addresses never reach the screen or the log (core/redact.dart). Found on
/// 2026-10-31, when a channel that would not open showed its whole stream URL,
/// line password included, on the TV's error screen. Placeholders only here:
/// no real host or credential ever goes in a fixture (CLAUDE.md §1).
void main() {
  test('a stream URL in libmpv\'s error is hidden, credentials and all', () {
    final shown = redactAddresses(
      'Failed to open http://<panel-host>:8080/live/user1/pass1/123.ts.',
    );
    expect(shown, 'Failed to open (address hidden)');
    expect(shown, isNot(contains('pass1')));
    expect(shown, isNot(contains('user1')));
  });

  test('an API query string is hidden too', () {
    expect(
      redactAddresses(
        'DioException: GET https://<panel-host>/player_api.php'
        '?username=u&password=p failed',
      ),
      'DioException: GET (address hidden) failed',
    );
  });

  test('control: a message with no address is left alone', () {
    expect(
      redactAddresses('This channel is not responding.'),
      'This channel is not responding.',
    );
  });
}
