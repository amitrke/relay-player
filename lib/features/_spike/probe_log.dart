import 'package:flutter/material.dart';

/// Severity of a single [ProbeLog] line.
enum LogLevel { info, good, warn, bad }

/// One timestamped line in a probe's transcript.
@immutable
class LogLine {
  const LogLine(this.at, this.level, this.message);

  final DateTime at;
  final LogLevel level;
  final String message;
}

/// Append-only transcript for a probe run.
///
/// Phase 0 is about producing evidence, not a nice UX -- so every probe writes
/// a timestamped narrative here and the UI just renders it. Timings matter as
/// much as success/failure (see docs/architecture.md S5 on XMLTV parse cost),
/// which is why [time] exists.
class ProbeLog extends ChangeNotifier {
  final List<LogLine> _lines = [];

  List<LogLine> get lines => List.unmodifiable(_lines);

  /// Secrets scrubbed from every line, registered once at startup.
  ///
  /// Masking at each call site does not work: the most dangerous strings come
  /// from *other people's* code. media_kit's `Failed to open <url>` and Dio's
  /// exception text both embed the full URL, password and all, and those reach
  /// the log verbatim through `_log.bad('$e')`. Since these transcripts exist
  /// to be pasted into docs/PHASE0_FINDINGS.md — in a public repo — scrubbing
  /// has to happen at the sink, where nothing can bypass it.
  static final List<String> _secrets = [];

  /// Registers strings to mask. Call once, before any probe runs.
  static void registerSecrets(Iterable<String> secrets) {
    for (final s in secrets) {
      // Very short values would mangle unrelated text; a real credential is
      // never 3 characters.
      if (s.trim().length >= 4 && !_secrets.contains(s)) _secrets.add(s);
    }
    // Longest first, so a password that contains another secret as a substring
    // is still fully replaced.
    _secrets.sort((a, b) => b.length.compareTo(a.length));
  }

  static String scrub(String text) {
    var out = text;
    for (final s in _secrets) {
      out = out.replaceAll(s, '••••');
    }
    return out;
  }

  void _add(LogLevel level, String message) {
    _lines.add(LogLine(DateTime.now(), level, scrub(message)));
    notifyListeners();
  }

  void info(String m) => _add(LogLevel.info, m);
  void good(String m) => _add(LogLevel.good, m);
  void warn(String m) => _add(LogLevel.warn, m);
  void bad(String m) => _add(LogLevel.bad, m);

  void clear() {
    _lines.clear();
    notifyListeners();
  }

  /// Runs [body], logging how long it took. Failures are logged and rethrown
  /// as a swallowed `null` so a probe can keep going to its next step.
  Future<T?> time<T>(String label, Future<T> Function() body) async {
    final sw = Stopwatch()..start();
    info('$label ...');
    try {
      final result = await body();
      sw.stop();
      good('$label OK  (${sw.elapsedMilliseconds} ms)');
      return result;
    } catch (e, st) {
      sw.stop();
      bad('$label FAILED after ${sw.elapsedMilliseconds} ms');
      bad('  $e');
      final first = st.toString().split('\n').take(3).join('\n  ');
      bad('  $first');
      return null;
    }
  }

  /// The whole transcript as text, for pasting into docs/PHASE0_FINDINGS.md.
  String asText() => _lines
      .map((l) =>
          '[${l.at.toIso8601String().substring(11, 23)}] '
          '${l.level.name.toUpperCase().padRight(4)}  ${l.message}')
      .join('\n');
}

/// Renders a [ProbeLog] as a monospace transcript.
class ProbeLogView extends StatelessWidget {
  const ProbeLogView({super.key, required this.log});

  final ProbeLog log;

  static const _colors = {
    LogLevel.info: Color(0xFF9AA0A6),
    LogLevel.good: Color(0xFF4CAF50),
    LogLevel.warn: Color(0xFFFFA726),
    LogLevel.bad: Color(0xFFEF5350),
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: log,
      builder: (context, _) {
        if (log.lines.isEmpty) {
          return const Center(
            child: Text('No output yet -- run a probe.',
                style: TextStyle(color: Color(0xFF9AA0A6))),
          );
        }
        return Container(
          color: const Color(0xFF12141A),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: log.lines.length,
            itemBuilder: (context, i) {
              final line = log.lines[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: SelectableText(
                  '${line.at.toIso8601String().substring(11, 19)}  ${line.message}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.4,
                    color: _colors[line.level],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
