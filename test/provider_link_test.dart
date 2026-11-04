import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/xtream/provider_link.dart';

/// Reading the login out of a provider's link (provider_link.dart). Made-up
/// hosts and logins only (CLAUDE.md §1).
void main() {
  void expectLogin(String link, String host, String user, String pass) {
    final parsed = ProviderLink.tryParse(link);
    expect(parsed, isNotNull, reason: link);
    expect(parsed!.host, host);
    expect(parsed.username, user);
    expect(parsed.password, pass);
  }

  test('the usual playlist link', () {
    expectLogin(
      'http://panel-host.example:8080/get.php?username=demo&password=s3cret&type=m3u_plus&output=ts',
      'http://panel-host.example:8080',
      'demo',
      's3cret',
    );
  });

  test('the API and guide endpoints carry the same login', () {
    for (final endpoint in ['player_api.php', 'xmltv.php', 'panel_api.php']) {
      expectLogin(
        'https://panel-host.example/$endpoint?username=demo&password=pw',
        'https://panel-host.example',
        'demo',
        'pw',
      );
    }
  });

  test('a stream link, with and without its kind', () {
    // An explicit default port is dropped, as Uri does: the same address.
    expectLogin('http://panel-host.example:80/live/demo/pw/1234.ts',
        'http://panel-host.example', 'demo', 'pw');
    expectLogin('http://panel-host.example/movie/demo/pw/99.mkv',
        'http://panel-host.example', 'demo', 'pw');
    expectLogin('http://panel-host.example:8080/demo/pw/1234',
        'http://panel-host.example:8080', 'demo', 'pw');
  });

  test('what an email does to a link', () {
    expectLogin(
      '  <http://panel-host.example:8080/get.php?username=demo&amp;password=pw&amp;type=m3u_plus>  ',
      'http://panel-host.example:8080',
      'demo',
      'pw',
    );
    expectLogin(
      '"http://panel-host.example:8080/get.php?username=demo\n&password=pw"',
      'http://panel-host.example:8080',
      'demo',
      'pw',
    );
  });

  test('percent-encoded characters in a password come back as typed', () {
    expectLogin(
      'http://panel-host.example/get.php?username=demo&password=p%40ss%26word',
      'http://panel-host.example',
      'demo',
      'p@ss&word',
    );
  });

  test('anything else is not a guess', () {
    for (final text in [
      '',
      'panel-host.example:8080',
      'http://panel-host.example:8080',
      'http://panel-host.example/get.php?username=demo',
      'http://panel-host.example/get.php?password=pw',
      'http://panel-host.example/files/a/b',
      'http://panel-host.example/some/long/path/here/x',
      'ftp://panel-host.example/get.php?username=demo&password=pw',
      'username=demo&password=pw',
    ]) {
      expect(ProviderLink.tryParse(text), isNull, reason: text);
    }
  });
}
