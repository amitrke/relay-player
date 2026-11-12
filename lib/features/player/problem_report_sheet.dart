import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/platform/device_kind.dart';
import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../i18n/strings.g.dart';
import 'problem_report.dart';
import 'report_sender.dart';

/// Shows the report for the person to read, and sends it only when they press
/// Send (architecture.md section 16.4). Nothing leaves the device before that.
Future<void> showProblemReportSheet(
  BuildContext context,
  ProblemReport report,
  ReportSender sender,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: RelayTheme.of(context).surface,
    isScrollControlled: true,
    builder: (_) => ProblemReportSheet(report: report, sender: sender),
  );
}

enum _Stage { idle, sending, sent, failed }

class ProblemReportSheet extends StatefulWidget {
  const ProblemReportSheet({
    super.key,
    required this.report,
    required this.sender,
  });

  final ProblemReport report;
  final ReportSender sender;

  @override
  State<ProblemReportSheet> createState() => _ProblemReportSheetState();
}

class _ProblemReportSheetState extends State<ProblemReportSheet> {
  final _note = TextEditingController();
  _Stage _stage = _Stage.idle;
  bool _copied = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// The report as it would be sent right now, note included.
  ProblemReport get _current => widget.report.withNote(_note.text);

  Future<void> _send() async {
    setState(() => _stage = _Stage.sending);
    final ok = await widget.sender.send(_current);
    if (!mounted) return;
    setState(() => _stage = ok ? _Stage.sent : _Stage.failed);
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _current.text));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    // The same map the sender posts, so what is shown is what is sent.
    final entries = _current
        .toJson()
        .entries
        .where((e) => e.key != 'v')
        .toList();
    final status = switch (_stage) {
      _Stage.sending => tr.player.reportSending,
      _Stage.sent => tr.player.reportSent,
      _Stage.failed => tr.player.reportFailed,
      _Stage.idle => _copied ? tr.player.reportCopied : null,
    };

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr.player.reportTitle,
              style: TextStyle(
                color: t.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr.player.reportIntro,
              style: TextStyle(color: t.inkDim, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: t.line),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                [for (final e in entries) '${e.key}: ${e.value}'].join('\n'),
                style: TextStyle(
                  color: t.ink,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            // Typing with a remote is miserable, and the note is optional.
            if (!DeviceKind.isTelevision && _stage != _Stage.sent) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLength: 200,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(hintText: tr.player.reportNote),
              ),
            ],
            if (status != null) ...[
              const SizedBox(height: 8),
              Text(status, style: TextStyle(color: t.inkDim)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (widget.sender.available && _stage != _Stage.sent)
                  RelayButton(
                    label: tr.player.reportSend,
                    autofocus: true,
                    onPressed: _stage == _Stage.sending ? null : _send,
                  ),
                RelayTextButton(
                  label: tr.player.reportCopy,
                  autofocus: !widget.sender.available,
                  onPressed: _copy,
                ),
                RelayTextButton(
                  label: _stage == _Stage.sent
                      ? tr.common.back
                      : tr.common.cancel,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
