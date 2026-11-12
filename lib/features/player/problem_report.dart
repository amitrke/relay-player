import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../../core/redact.dart';
import 'engine/playback_engine.dart';

/// What the person sends when they press "Report a problem" on the player's
/// error screen (architecture.md section 16.4).
///
/// **Diagnostics only.** It carries the error line, the formats, which decoder
/// and output path were in use, and the platform. It carries no title, address,
/// path, server, account or library name, and there is no field for one. The
/// repository the reports land in is public, so a report is public once filed:
/// every string is cleaned here, the relay checks again, and the person reads
/// the exact [toJson] contents before anything is sent.
@immutable
class ProblemReport {
  const ProblemReport({
    required this.error,
    required this.diagnostics,
    required this.appVersion,
    required this.platform,
    this.osVersion,
    this.note,
  });

  /// The player's error line (already free of addresses; cleaned again).
  final String error;
  final PlaybackDiagnostics diagnostics;

  /// `1.0.8+1`: the version and build number.
  final String appVersion;

  /// One of the relay's platform names; see [platformName].
  final String platform;
  final String? osVersion;

  /// Optional, written by the person, short.
  final String? note;

  static const maxErrorLength = 300;
  static const maxNoteLength = 500;

  /// The relay accepts format fields that look like format names and refuses
  /// the rest, so anything else is left out here rather than failing the whole
  /// report. Mirrors `TOKEN` in `tool/report-relay/worker.js`.
  static final _formatName = RegExp(r'^[A-Za-z0-9 ._+\-/()]{1,40}$');

  static String? _format(String? value) =>
      value != null && _formatName.hasMatch(value) ? value : null;

  static String _clean(String text, int max) {
    final flat = redactAddresses(text)
        .replaceAll(RegExp(r'[\x00-\x1f\x7f]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return flat.length <= max ? flat : flat.substring(0, max);
  }

  ProblemReport withNote(String? text) => ProblemReport(
        error: error,
        diagnostics: diagnostics,
        appVersion: appVersion,
        platform: platform,
        osVersion: osVersion,
        note: text,
      );

  /// The relay's schema, version 1, and **exactly** what is sent. The preview
  /// the person reads is built from this map, so the two cannot differ.
  Map<String, Object> toJson() {
    final d = diagnostics;
    final note = this.note == null ? '' : _clean(this.note!, maxNoteLength);
    return {
      'v': 1,
      'app_version': appVersion,
      'platform': platform,
      if (_format(osVersion) != null) 'os_version': osVersion!,
      'error': _clean(error, maxErrorLength),
      if (_format(d.container) != null) 'container': d.container!,
      if (_format(d.videoCodec) != null) 'video_codec': d.videoCodec!,
      if (_format(d.audioCodec) != null) 'audio_codec': d.audioCodec!,
      if (d.audioChannels != null && d.audioChannels! >= 0 && d.audioChannels! <= 16)
        'audio_channels': d.audioChannels!,
      'decoder': d.decoder,
      'output': d.output,
      if (note.isNotEmpty) 'note': note,
    };
  }

  /// Plain text for Copy, and for the person to paste anywhere.
  String get text => toJson()
      .entries
      .where((e) => e.key != 'v')
      .map((e) => '${e.key}: ${e.value}')
      .join('\n');

  /// The relay's platform name for this device.
  static String platformName() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'other';
  }

  /// `26.5` from iOS's "Version 26.5 (Build 23F77)". Null elsewhere: Dart's
  /// Android string is the kernel's, which says nothing about the Android
  /// version, and an unhelpful value is worse than none.
  static String? osVersionOf(String operatingSystemVersion) {
    final m = RegExp(r'Version (\d+(?:\.\d+)*)').firstMatch(operatingSystemVersion);
    return m?.group(1);
  }
}
