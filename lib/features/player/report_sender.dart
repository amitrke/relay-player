import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'problem_report.dart';

/// Where a problem report is posted: the relay in `tool/report-relay/`
/// (architecture.md section 16.4), passed at build time as
/// `--dart-define=REPORT_RELAY_URL=https://...`.
///
/// **Empty by default, and while it is empty nothing can be sent**: the report
/// screen offers Copy only. The address is public and is not a secret, but it
/// stays out of the repository until a relay is deployed, and the privacy
/// policy and store declarations must change in the same release that sets it
/// (`tool/report-relay/README.md`).
const kReportRelayUrl = String.fromEnvironment('REPORT_RELAY_URL');

abstract class ReportSender {
  /// Whether a relay is configured. When false, only Copy is offered.
  bool get available;

  /// Posts [report]. True only when the relay accepted it; false for any
  /// failure, since the person can do nothing different about the reason.
  Future<bool> send(ProblemReport report);
}

class RelayReportSender implements ReportSender {
  RelayReportSender(this._dio, this._url);

  final Dio _dio;
  final String _url;

  @override
  bool get available => _url.isNotEmpty;

  @override
  Future<bool> send(ProblemReport report) async {
    if (!available) return false;
    try {
      final res = await _dio.post<void>(
        _url.endsWith('/report') ? _url : '$_url/report',
        data: report.toJson(),
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          // Anything but the relay's 202 counts as not sent.
          validateStatus: (status) => status == 202,
        ),
      );
      return res.statusCode == 202;
    } on DioException {
      return false;
    }
  }
}

/// Overridden in tests with a fake.
final reportSenderProvider = Provider<ReportSender>(
  (ref) => RelayReportSender(Dio(), kReportRelayUrl),
);
