import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/data/xtream/xtream_account_store.dart';
import 'package:relay_player/data/xtream/xtream_client.dart';
import 'package:relay_player/features/advanced_sources/xtream_controller.dart';

/// Which format a live channel is opened in (architecture.md §10, "Live over
/// HLS"). Placeholders only: no real host or credential (CLAUDE.md §1).
XtreamAccountInfo _line(List<String> formats) => XtreamAccountInfo(
  status: 'Active',
  isTrial: false,
  maxConnections: 1,
  activeConnections: 0,
  expiresAt: null,
  outputFormats: formats,
);

class _Client extends XtreamClient {
  _Client(this.answer)
    : super(
        host: 'http://panel-host.example.invalid',
        username: 'u',
        password: 'p',
      );

  final Future<XtreamAccountInfo> Function() answer;

  @override
  Future<XtreamAccountInfo> authenticate() => answer();
}

void main() {
  const account = XtreamAccount(
    id: 'a',
    name: 'Line',
    host: 'http://panel-host.example.invalid',
    username: 'u',
  );

  test('HLS when the line allows it, whatever order the panel lists', () {
    expect(_line(['m3u8', 'ts']).liveFormat, 'm3u8');
    expect(_line(['ts', 'm3u8']).liveFormat, 'm3u8');
  });

  test('control: MPEG-TS when HLS is not allowed or nothing is listed', () {
    expect(_line(['ts']).liveFormat, 'ts');
    expect(_line(['rtmp']).liveFormat, 'ts');
    expect(_line([]).liveFormat, 'ts');
  });

  Future<String> formatWith(_Client client) {
    final container = ProviderContainer(
      overrides: [xtreamClientProvider.overrideWith((ref, _) async => client)],
    );
    addTearDown(container.dispose);
    return container.read(xtreamLiveFormatProvider(account).future);
  }

  test('the provider asks the line', () async {
    expect(
      await formatWith(_Client(() async => _line(['ts', 'm3u8']))),
      'm3u8',
    );
  });

  test('a panel that cannot be asked gets .ts, not an error', () async {
    expect(
      await formatWith(_Client(() async => throw XtreamException('down'))),
      'ts',
    );
  });
}
