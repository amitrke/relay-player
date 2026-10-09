import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/downloads/download_engine.dart';
import '../../data/downloads/download_record.dart';
import '../../data/plex/plex_service.dart';
import '../accounts/plex_session.dart';
import '../settings/settings_controller.dart';

/// Where downloaded files live: the app's private storage, so they cannot be
/// browsed, shared or picked up by a gallery. Overridden in tests.
final downloadsDirectoryProvider = FutureProvider<Directory>((ref) async {
  // Support, not documents: on iOS the documents folder is what the Files app
  // and iCloud backup see, and a few gigabytes of films belongs in neither.
  final base = await getApplicationSupportDirectory();
  final dir = Directory('${base.path}${Platform.pathSeparator}downloads');
  await dir.create(recursive: true);
  return dir;
});

final downloadEngineProvider = Provider<DownloadEngine>(
  (ref) => const DownloadEngine(),
);

/// Turns a server and an item into something to fetch. A seam for tests.
typedef DownloadSourceResolver =
    Future<PlexDownloadSource> Function(String serverId, String ratingKey);

final downloadSourceResolverProvider = Provider<DownloadSourceResolver>((ref) {
  return (serverId, ratingKey) {
    final server = ref
        .read(connectedServersProvider)
        .where((s) => s.id == serverId)
        .firstOrNull;
    if (server == null) {
      throw const DownloadException(
        'That server is not connected. Reconnect it in Settings, then resume.',
      );
    }
    return server.service.downloadSource(ratingKey);
  };
});

final downloadStoreProvider = Provider<DownloadStore>(
  (ref) => DownloadStore(ref.watch(appSettingsStoreProvider)),
);

/// Everything saved, or being saved, on this device (§18).
final downloadsProvider =
    NotifierProvider<DownloadsController, List<DownloadRecord>>(
      DownloadsController.new,
    );

/// The one place downloads are started, stopped and removed.
///
/// **One at a time, and only while the app is open** (§18.3). Several at once
/// would split the server's upstream and the phone's Wi-Fi between files none
/// of which is watchable yet, and there is no background service: a download
/// that was running when the app closed comes back [DownloadState.paused], and
/// the partial file is kept so resuming continues it.
class DownloadsController extends Notifier<List<DownloadRecord>> {
  DownloadStore get _store => ref.read(downloadStoreProvider);

  /// The key of the download that is running, if any.
  String? _active;
  bool _cancel = false;
  String? _removeWhenStopped;

  @override
  List<DownloadRecord> build() {
    return [
      for (final r in _store.load())
        // Nothing runs while the app is closed, so a record still marked as
        // running or waiting was interrupted. It goes back to the person.
        if (r.state == DownloadState.downloading ||
            r.state == DownloadState.queued)
          r.copyWith(state: DownloadState.paused)
        else
          r,
    ];
  }

  DownloadRecord? find(String serverId, String ratingKey) {
    final key = DownloadRecord.keyOf(serverId, ratingKey);
    return state.where((r) => r.key == key).firstOrNull;
  }

  /// Bytes the downloads take on disk, counting partial files.
  int get bytesUsed => state.fold(
    0,
    (sum, r) => sum + (r.isComplete ? (r.totalBytes ?? 0) : r.receivedBytes),
  );

  /// Adds an item to the queue. Does nothing if it is already there and not
  /// failed; a failed one is retried instead.
  Future<void> enqueue({
    required String serverId,
    required String ratingKey,
    required String title,
    bool isEpisode = false,
  }) async {
    final existing = find(serverId, ratingKey);
    if (existing != null) {
      if (existing.state == DownloadState.failed ||
          existing.state == DownloadState.paused) {
        await resume(serverId, ratingKey);
      }
      return;
    }
    state = [
      ...state,
      DownloadRecord(
        serverId: serverId,
        ratingKey: ratingKey,
        title: title,
        isEpisode: isEpisode,
        addedAt: DateTime.now(),
      ),
    ];
    await _persist();
    unawaited(_pump());
  }

  Future<void> pause(String serverId, String ratingKey) async {
    final key = DownloadRecord.keyOf(serverId, ratingKey);
    if (_active == key) {
      // The running fetch notices at its next chunk and settles itself.
      _cancel = true;
      return;
    }
    _update(key, (r) => r.copyWith(state: DownloadState.paused));
    await _persist();
  }

  Future<void> resume(String serverId, String ratingKey) async {
    final key = DownloadRecord.keyOf(serverId, ratingKey);
    _update(
      key,
      (r) => r.copyWith(state: DownloadState.queued, clearError: true),
    );
    await _persist();
    unawaited(_pump());
  }

  /// Stops it if it is running, and deletes the file, partial or whole.
  Future<void> remove(String serverId, String ratingKey) async {
    final key = DownloadRecord.keyOf(serverId, ratingKey);
    if (_active == key) {
      // Deleting under a running fetch would just recreate the file. Stop it,
      // and let it clean up after itself when it has let go.
      _removeWhenStopped = key;
      _cancel = true;
      return;
    }
    await _discard(key);
  }

  /// The finished file for an item, or null if there is none or it has gone.
  Future<File?> fileFor(String serverId, String ratingKey) async {
    final record = find(serverId, ratingKey);
    final name = record?.fileName;
    if (record == null || !record.isComplete || name == null) return null;
    final dir = await ref.read(downloadsDirectoryProvider.future);
    final file = File('${dir.path}${Platform.pathSeparator}$name');
    return await file.exists() ? file : null;
  }

  // --- Running ---------------------------------------------------------

  Future<void> _pump() async {
    if (_active != null) return;
    final next = state
        .where((r) => r.state == DownloadState.queued)
        .firstOrNull;
    if (next == null) return;
    await _run(next);
  }

  Future<void> _run(DownloadRecord record) async {
    final key = record.key;
    _active = key;
    _cancel = false;
    _update(
      key,
      (r) => r.copyWith(state: DownloadState.downloading, clearError: true),
    );
    await _persist();

    File? part;
    try {
      final source = await ref.read(downloadSourceResolverProvider)(
        record.serverId,
        record.ratingKey,
      );
      final dir = await ref.read(downloadsDirectoryProvider.future);
      final name =
          record.fileName ??
          '${_safe(record.serverId)}_${_safe(record.ratingKey)}.${_safe(source.extension)}';
      part = File('${dir.path}${Platform.pathSeparator}$name.part');

      _update(
        key,
        (r) => r.copyWith(
          title: source.title,
          fileName: name,
          totalBytes: source.sizeBytes,
          duration: source.duration,
          posterPath: source.posterPath,
          isEpisode: source.isEpisode,
        ),
      );

      var lastEmit = DateTime.fromMillisecondsSinceEpoch(0);
      final size = await ref
          .read(downloadEngineProvider)
          .fetch(
            Uri.parse(source.url),
            part,
            cancelled: () => _cancel,
            onProgress: (received, total) {
              // Progress is for the screen, not the disk: held in memory and
              // throttled, so a fast download does not rewrite the settings box
              // hundreds of times a second.
              final now = DateTime.now();
              if (now.difference(lastEmit) < const Duration(milliseconds: 250)) {
                return;
              }
              lastEmit = now;
              _update(
                key,
                (r) =>
                    r.copyWith(receivedBytes: received, totalBytes: total),
              );
            },
          );

      final expected = source.sizeBytes;
      if (expected != null && size != expected) {
        // Longer or shorter than Plex said: not a file to trust. Dropped so the
        // retry starts clean rather than resuming into the same fault.
        await _deleteQuietly(part);
        throw const DownloadException(
          'The file did not match the size the server reported. Try again.',
        );
      }

      final finished = File(part.path.substring(0, part.path.length - 5));
      await part.rename(finished.path);
      _update(
        key,
        (r) => r.copyWith(
          state: DownloadState.complete,
          totalBytes: size,
          receivedBytes: size,
        ),
      );
    } on DownloadCancelled {
      _update(key, (r) => r.copyWith(state: DownloadState.paused));
    } on DownloadException catch (e) {
      _update(
        key,
        (r) => r.copyWith(state: DownloadState.failed, error: e.message),
      );
    } on PlexUnreachable catch (e) {
      _update(
        key,
        (r) => r.copyWith(state: DownloadState.failed, error: e.message),
      );
    } on FileSystemException {
      _update(
        key,
        (r) => r.copyWith(
          state: DownloadState.failed,
          error: 'Could not write the file. The device may be out of space.',
        ),
      );
    } catch (e) {
      _update(
        key,
        (r) => r.copyWith(state: DownloadState.failed, error: '$e'),
      );
    } finally {
      // Record how far a stopped download got, once, now that it has let go.
      if (part != null && await part.exists()) {
        final onDisk = await part.length();
        _update(key, (r) {
          return r.isComplete ? r : r.copyWith(receivedBytes: onDisk);
        });
      }
      _active = null;
      _cancel = false;
      final remove = _removeWhenStopped;
      _removeWhenStopped = null;
      if (remove == key) {
        await _discard(key);
      } else {
        await _persist();
      }
      unawaited(_pump());
    }
  }

  Future<void> _discard(String key) async {
    final record = state.where((r) => r.key == key).firstOrNull;
    state = [
      for (final r in state)
        if (r.key != key) r,
    ];
    await _persist();
    final name = record?.fileName;
    if (name == null) return;
    final dir = await ref.read(downloadsDirectoryProvider.future);
    await _deleteQuietly(File('${dir.path}${Platform.pathSeparator}$name'));
    await _deleteQuietly(
      File('${dir.path}${Platform.pathSeparator}$name.part'),
    );
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  void _update(String key, DownloadRecord Function(DownloadRecord) change) {
    state = [
      for (final r in state)
        if (r.key == key) change(r) else r,
    ];
  }

  Future<void> _persist() => _store.save(state);

  /// A file name from an id: letters, digits, dash and underscore only. Plex
  /// ids are numbers and hex, but this names a file on disk from server input.
  static String _safe(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
}
