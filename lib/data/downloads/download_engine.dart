import 'dart:async';
import 'dart:io';

/// A fetch that failed, with a message fit to show.
class DownloadException implements Exception {
  const DownloadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The fetch was stopped on purpose (paused or removed), not by an error.
class DownloadCancelled implements Exception {
  const DownloadCancelled();
}

/// Writes one URL into one file, continuing a partial file if there is one.
///
/// Its own class so the manager can be tested without a network, and so the
/// part that has to be right about HTTP (ranges, a server that ignores them, a
/// body that stops early) is in one place with its own tests.
class DownloadEngine {
  const DownloadEngine({this.connectTimeout = const Duration(seconds: 15)});

  final Duration connectTimeout;

  /// Fetches [url] into [file], appending after what [file] already holds.
  ///
  /// Returns the size of the finished file. [cancelled] is polled between
  /// chunks; when it turns true the fetch stops and throws
  /// [DownloadCancelled], leaving the partial file for a later resume.
  Future<int> fetch(
    Uri url,
    File file, {
    required bool Function() cancelled,
    required void Function(int received, int? total) onProgress,
  }) async {
    var start = await file.exists() ? await file.length() : 0;

    final client = HttpClient()..connectionTimeout = connectTimeout;
    try {
      final request = await client.getUrl(url);
      if (start > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$start-');
      }
      final response = await request.close();

      if (response.statusCode == HttpStatus.requestedRangeNotSatisfiable) {
        // "Nothing at or after that byte": usually because the file is already
        // whole, e.g. the app was closed between the last chunk and the rename.
        // The server says how long it is, so check rather than assume.
        final total = _totalFromContentRange(
          response.headers.value(HttpHeaders.contentRangeHeader),
        );
        await response.drain<void>();
        if (total != null && total == start) return start;
        // Longer than the server's copy: the file changed underneath us.
        await file.delete();
        throw const DownloadException(
          'The file changed on the server. Start the download again.',
        );
      }

      if (response.statusCode == HttpStatus.unauthorized ||
          response.statusCode == HttpStatus.forbidden) {
        await response.drain<void>();
        throw const DownloadException(
          'The server would not let this device download that.',
        );
      }
      if (response.statusCode != HttpStatus.ok &&
          response.statusCode != HttpStatus.partialContent) {
        await response.drain<void>();
        throw DownloadException(
          'The server answered ${response.statusCode}.',
        );
      }

      // A server that ignores Range answers 200 with the whole file. Appending
      // that after the partial copy would make a file twice as long and
      // corrupt, so start over.
      if (response.statusCode == HttpStatus.ok) start = 0;

      final length = response.contentLength;
      final total = length < 0 ? null : start + length;

      final sink = file.openWrite(
        mode: start == 0 ? FileMode.write : FileMode.append,
      );
      var received = start;
      var stopped = false;
      try {
        await for (final chunk in response) {
          if (cancelled()) {
            stopped = true;
            break;
          }
          sink.add(chunk);
          received += chunk.length;
          onProgress(received, total);
        }
      } finally {
        await sink.close();
      }
      if (stopped) throw const DownloadCancelled();

      // A body that ends early is a dropped connection, not a finished file.
      // Checked against the length the server promised.
      if (total != null && received < total) {
        throw const DownloadException(
          'The connection dropped part-way. Resume to continue.',
        );
      }
      return received;
    } on SocketException {
      throw const DownloadException(
        'Could not reach the server. Check the connection and resume.',
      );
    } on HttpException {
      throw const DownloadException(
        'The connection dropped part-way. Resume to continue.',
      );
    } on TimeoutException {
      throw const DownloadException('The server took too long to answer.');
    } finally {
      client.close(force: true);
    }
  }

  /// `N` from `Content-Range: bytes */N`.
  static int? _totalFromContentRange(String? header) {
    if (header == null) return null;
    final match = RegExp(r'/(\d+)\s*$').firstMatch(header);
    return match == null ? null : int.tryParse(match.group(1)!);
  }
}
