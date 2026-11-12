import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_player/core/theme/relay_theme.dart';
import 'package:relay_player/core/theme/relay_tokens.dart';
import 'package:relay_player/features/player/engine/playback_engine.dart';
import 'package:relay_player/features/player/problem_report.dart';
import 'package:relay_player/features/player/problem_report_sheet.dart';
import 'package:relay_player/features/player/report_sender.dart';

/// The in-app problem report (architecture.md section 16.4). The reports land
/// in a public repository, so what these tests pin is what can NOT get out, and
/// that the person reads exactly what is sent.

// The Pixel report that motivated it (MANUAL_TESTING.md section 4).
const _avi = PlaybackDiagnostics(
  container: 'avi',
  videoCodec: 'mpeg4',
  audioCodec: 'ac3',
  audioChannels: 6,
  decoder: 'hardware',
  output: 'direct',
);

ProblemReport _report({
  String error = 'Error decoding audio.',
  PlaybackDiagnostics d = _avi,
  String? note,
}) => ProblemReport(
  error: error,
  diagnostics: d,
  appVersion: '1.0.8+1',
  platform: 'android',
  osVersion: '17',
  note: note,
);

class _Sender implements ReportSender {
  _Sender({this.available = true, this.ok = true});
  @override
  final bool available;
  final bool ok;
  final sent = <Map<String, Object>>[];

  @override
  Future<bool> send(ProblemReport report) async {
    sent.add(report.toJson());
    return ok;
  }
}

Widget _app(Widget child) => MaterialApp(
  builder: (context, child) => RelayTheme(
    tokens: RelayPalettes.midnight,
    palette: RelayPalette.midnight,
    child: child!,
  ),
  home: Scaffold(body: child),
);

void main() {
  group('what is sent', () {
    test('the report is the relay schema, version 1', () {
      expect(_report().toJson(), {
        'v': 1,
        'app_version': '1.0.8+1',
        'platform': 'android',
        'os_version': '17',
        'error': 'Error decoding audio.',
        'container': 'avi',
        'video_codec': 'mpeg4',
        'audio_codec': 'ac3',
        'audio_channels': 6,
        'decoder': 'hardware',
        'output': 'direct',
      });
    });

    test('there is no field that could carry a title or an address', () {
      final keys = _report(note: 'hello').toJson().keys.toSet();
      expect(
        keys,
        everyElement(
          isIn({
            'v', 'app_version', 'platform', 'os_version', 'error', 'container',
            'video_codec', 'audio_codec', 'audio_channels', 'decoder',
            'output', 'note',
          }),
        ),
      );
    });

    test('addresses in the error and the note are hidden', () {
      final json = _report(
        error: 'Failed to open http://panel.example:8080/live/u/p/1.ts',
        note: 'it is at https://nas.example/film.mkv',
      ).toJson();
      final text = jsonEncode(json);
      expect(text, isNot(contains('panel.example')));
      expect(text, isNot(contains('nas.example')));
      expect(text, isNot(contains('http')));
    });

    test('a format field that is not a format name is left out', () {
      final json = _report(
        d: const PlaybackDiagnostics(
          container: 'My Home Movie (2014) at the farm, with Dad and everyone',
          videoCodec: 'hevc',
          audioCodec: '<script>',
        ),
      ).toJson();
      expect(json.containsKey('container'), isFalse);
      expect(json.containsKey('audio_codec'), isFalse);
      expect(json['video_codec'], 'hevc');
    });

    test('long text is cut and control characters become spaces', () {
      final json = _report(error: 'a\nb\t${'x' * 900}').toJson();
      final error = json['error'] as String;
      expect(error.length, lessThanOrEqualTo(ProblemReport.maxErrorLength));
      expect(error, startsWith('a b '));
    });

    test('an empty note is not sent, and a missing track is not invented', () {
      final json = _report(note: '   ', d: const PlaybackDiagnostics()).toJson();
      expect(json.containsKey('note'), isFalse);
      expect(json.containsKey('container'), isFalse);
      expect(json['decoder'], 'unknown');
    });

    test('Copy text is the same facts, one per line, without the version tag', () {
      final text = _report().text;
      expect(text, contains('container: avi'));
      expect(text, contains('error: Error decoding audio.'));
      expect(text, isNot(contains('v: 1')));
    });

    test('the iOS version is read out of the platform string', () {
      expect(ProblemReport.osVersionOf('Version 26.5 (Build 23F77)'), '26.5');
      expect(ProblemReport.osVersionOf('Linux 6.1.99-android14'), isNull);
    });
  });

  group('the relay sender', () {
    Dio dioAnswering(int status, void Function(RequestOptions) seen) {
      final dio = Dio();
      dio.httpClientAdapter = _Adapter((o) {
        seen(o);
        return ResponseBody.fromString('{}', status);
      });
      return dio;
    }

    test('posts the schema to /report and counts only a 202', () async {
      late RequestOptions seen;
      final ok = await RelayReportSender(
        dioAnswering(202, (o) => seen = o),
        'https://relay.example',
      ).send(_report());
      expect(ok, isTrue);
      expect(seen.uri.toString(), 'https://relay.example/report');
      expect(seen.data, _report().toJson());
    });

    test('any other answer is not sent', () async {
      for (final status in [200, 400, 429, 500, 502]) {
        final ok = await RelayReportSender(
          dioAnswering(status, (_) {}),
          'https://relay.example/report',
        ).send(_report());
        expect(ok, isFalse, reason: '$status');
      }
    });

    test('with no relay configured nothing is sent and nothing is offered', () async {
      var calls = 0;
      final sender = RelayReportSender(dioAnswering(202, (_) => calls++), '');
      expect(sender.available, isFalse);
      expect(await sender.send(_report()), isFalse);
      expect(calls, 0);
    });

    test('a network failure is "not sent", not an exception', () async {
      final dio = Dio()..httpClientAdapter = _Adapter((_) => throw const SocketLikeError());
      expect(await RelayReportSender(dio, 'https://relay.example').send(_report()), isFalse);
    });
  });

  group('the sheet', () {
    testWidgets('shows what will be sent, and sends nothing until Send', (tester) async {
      final sender = _Sender();
      await tester.pumpWidget(
        _app(ProblemReportSheet(report: _report(), sender: sender)),
      );
      expect(find.textContaining('container: avi'), findsOneWidget);
      expect(find.textContaining('video_codec: mpeg4'), findsOneWidget);
      expect(sender.sent, isEmpty);

      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(sender.sent, hasLength(1));
      expect(find.text('Sent. Thank you.'), findsOneWidget);
    });

    testWidgets('a note typed by the person is shown and then sent', (tester) async {
      final sender = _Sender();
      await tester.pumpWidget(
        _app(ProblemReportSheet(report: _report(), sender: sender)),
      );
      await tester.enterText(find.byType(TextField), 'picture froze, audio kept going');
      await tester.pump();
      expect(find.textContaining('picture froze'), findsWidgets);
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(sender.sent.single['note'], 'picture froze, audio kept going');
    });

    testWidgets('a failed send says so and still offers Copy', (tester) async {
      await tester.pumpWidget(
        _app(ProblemReportSheet(report: _report(), sender: _Sender(ok: false))),
      );
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not send it'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Send report'), findsOneWidget, reason: 'can try again');
    });

    testWidgets('with no relay there is no Send, only Copy', (tester) async {
      final sender = _Sender(available: false);
      await tester.pumpWidget(
        _app(ProblemReportSheet(report: _report(), sender: sender)),
      );
      expect(find.text('Send report'), findsNothing);
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('Copy puts the text on the clipboard', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await tester.pumpWidget(
        _app(ProblemReportSheet(report: _report(), sender: _Sender(available: false))),
      );
      await tester.tap(find.text('Copy'));
      await tester.pump();
      expect(copied, _report().text);
      expect(find.text('Copied.'), findsOneWidget);
    });
  });
}

class SocketLikeError implements Exception {
  const SocketLikeError();
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this._answer);
  final ResponseBody Function(RequestOptions) _answer;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => _answer(options);

  @override
  void close({bool force = false}) {}
}
