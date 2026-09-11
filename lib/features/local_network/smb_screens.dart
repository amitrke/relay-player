import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/filesystem/smb_source.dart';
import '../library/poster_grid.dart';
import 'smb_controller.dart';

/// Adds a network share (§7.2).
///
/// A flagship source, not an Advanced one: §12 screen 2 lists Local & Network
/// alongside Plex as always available, because a NAS is someone's own files.
class AddSmbScreen extends ConsumerStatefulWidget {
  const AddSmbScreen({super.key});

  @override
  ConsumerState<AddSmbScreen> createState() => _AddSmbScreenState();
}

class _AddSmbScreenState extends ConsumerState<AddSmbScreen> {
  final _host = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _domain = TextEditingController();
  final _name = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_host, _username, _password, _domain, _name]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyAndSave() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final host = _host.text.trim();
    try {
      // Connect before saving. A share that cannot be reached should be
      // rejected here rather than becoming a configured source that fails
      // every time it is opened.
      final session = await SmbSession.connect(
        host: host,
        username: _username.text.trim(),
        password: _password.text,
        domain: _domain.text.trim(),
      );
      await session.shares();
      await session.close();

      final share = SmbShare(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim().isEmpty ? host : _name.text.trim(),
        host: host,
        username: _username.text.trim(),
        domain: _domain.text.trim(),
      );
      await ref
          .read(smbSharesProvider.notifier)
          .save(share, password: _password.text);

      if (mounted) context.go('/library?tab=local');
    } catch (e) {
      setState(() {
        _busy = false;
        _error = 'Could not connect: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.ink,
        title: const Text('Add a network share'),
      ),
      body: ListView(
        padding: RelayLayout.pagePadding(f).copyWith(top: 12, bottom: 32),
        children: [
          Text(
            'A NAS or a shared folder on another computer on your network.',
            style: TextStyle(color: t.inkDim, fontSize: 13, height: 1.55),
          ),
          const SizedBox(height: 22),
          _Field(controller: _host, label: 'Server address', hint: 'e.g. nas'),
          _Field(controller: _username, label: 'Username'),
          _Field(controller: _password, label: 'Password', obscure: true),
          _Field(controller: _domain, label: 'Domain (optional)'),
          _Field(controller: _name, label: 'Name (optional)'),
          const SizedBox(height: 10),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFB8574E)),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: t.ink, fontSize: 13, height: 1.45),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_busy)
            Center(child: CircularProgressIndicator(color: t.accent))
          else
            RelayButton(label: 'Connect and add', onPressed: _verifyAndSave),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: t.inkDim,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            autocorrect: false,
            enableSuggestions: false,
            style: TextStyle(color: t.ink),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: t.inkDim.withValues(alpha: 0.6)),
              filled: true,
              fillColor: t.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: t.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: t.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: t.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Browses one share: its top-level shares, then folders and videos (§12
/// screen 4).
class SmbBrowseScreen extends ConsumerWidget {
  const SmbBrowseScreen({
    super.key,
    required this.shareId,
    required this.path,
  });

  final String shareId;
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);

    final share = ref
        .watch(smbSharesProvider)
        .where((s) => s.id == shareId)
        .firstOrNull;

    if (share == null) {
      return Scaffold(
        backgroundColor: t.bg,
        appBar: AppBar(backgroundColor: t.bg, foregroundColor: t.ink),
        body: const Center(child: Text('That share is no longer configured.')),
      );
    }

    final listing = ref.watch(smbListingProvider((share, path)));

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.ink,
        title: Text(path.isEmpty ? share.name : _lastSegment(path)),
      ),
      body: listing.when(
        loading: () => Center(child: CircularProgressIndicator(color: t.accent)),
        error: (e, _) => LibraryEmptyState(
          icon: Icons.lan_outlined,
          // Phase 0 left SMB failure behaviour untested and called it out: a
          // sleeping NAS or a dropped Wi-Fi is the common case, not a corrupt
          // share, so say that first.
          message: 'Could not reach this share. The server may be asleep or '
              'off the network.\n\n$e',
          onRetry: () => ref.invalidate(smbListingProvider((share, path))),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const LibraryEmptyState(
              icon: Icons.folder_outlined,
              message: 'No videos or folders here.',
            );
          }
          return ListView.builder(
            padding: RelayLayout.pagePadding(f).copyWith(top: 12, bottom: 28),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final entry = entries[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => context.push(
                      entry.isDirectory
                          ? '/smb/$shareId?path=${Uri.encodeQueryComponent(entry.path)}'
                          : '/smbplay/$shareId?path=${Uri.encodeQueryComponent(entry.path)}',
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(
                            entry.isDirectory
                                ? Icons.folder_outlined
                                : Icons.movie_outlined,
                            color: t.inkDim,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              entry.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: t.ink,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!entry.isDirectory && entry.sizeBytes > 0)
                            Text(
                              _size(entry.sizeBytes),
                              style:
                                  TextStyle(color: t.inkDim, fontSize: 12.5),
                            ),
                          const SizedBox(width: 10),
                          Icon(Icons.chevron_right, color: t.inkDim),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _lastSegment(String path) {
    final trimmed =
        path.endsWith('/') ? path.substring(0, path.length - 1) : path;
    final slash = trimmed.lastIndexOf('/');
    return slash == -1 ? trimmed : trimmed.substring(slash + 1);
  }

  static String _size(int bytes) {
    final mb = bytes / (1024 * 1024);
    return mb >= 1024
        ? '${(mb / 1024).toStringAsFixed(1)} GB'
        : '${mb.round()} MB';
  }
}
