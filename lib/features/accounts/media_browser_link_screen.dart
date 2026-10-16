import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/jellyfin/media_browser_service.dart';
import '../../domain/models/media_server.dart';
import '../../i18n/strings.g.dart';
import 'media_browser_session.dart';

enum _Step { address, password, quickConnect }

/// Signing in to a Jellyfin or Emby server (§6.2).
///
/// Address first, because the server says what it is before anyone signs in:
/// its name, whether it is Jellyfin or Emby, and whether it offers Quick
/// Connect. When it does, that is the default, because it is the one way to
/// sign in on a TV without typing a password with a remote: a six-digit code
/// shown here, approved on a phone already signed in.
class MediaBrowserLinkScreen extends ConsumerStatefulWidget {
  const MediaBrowserLinkScreen({super.key});

  @override
  ConsumerState<MediaBrowserLinkScreen> createState() =>
      _MediaBrowserLinkScreenState();
}

class _MediaBrowserLinkScreenState
    extends ConsumerState<MediaBrowserLinkScreen> {
  final _address = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();

  _Step _step = _Step.address;
  MediaBrowserServerInfo? _info;
  bool _quickConnect = false;
  QuickConnectCode? _code;
  Timer? _poll;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _poll?.cancel();
    _address.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    if (_address.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final info = await MediaBrowserService.probe(_address.text);
      final quick = await MediaBrowserService.quickConnectEnabled(info);
      if (!mounted) return;
      setState(() {
        _info = info;
        _quickConnect = quick;
        _busy = false;
      });
      if (quick) {
        await _startQuickConnect();
      } else {
        setState(() => _step = _Step.password);
      }
    } on MediaServerUnreachable catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  Future<void> _startQuickConnect() async {
    final info = _info!;
    setState(() {
      _step = _Step.quickConnect;
      _busy = true;
      _error = null;
      _code = null;
    });
    try {
      final client = await ref.read(mediaBrowserClientProvider.future);
      final code = await MediaBrowserService.startQuickConnect(info, client);
      if (!mounted) return;
      setState(() {
        _code = code;
        _busy = false;
      });
      _poll?.cancel();
      // Five seconds: often enough that approving on a phone feels immediate,
      // rare enough not to be a load on someone's home server.
      _poll = Timer.periodic(const Duration(seconds: 5), (_) async {
        try {
          final auth = await MediaBrowserService.pollQuickConnect(
            info,
            client,
            code,
          );
          if (auth != null) {
            _poll?.cancel();
            await _done(auth);
          }
        } on MediaServerUnreachable catch (e) {
          _poll?.cancel();
          if (mounted) setState(() => _error = e.message);
        }
      });
    } on MediaServerUnreachable catch (e) {
      if (!mounted) return;
      // Quick Connect said it was on and then would not start: offer the
      // password form rather than a dead end.
      setState(() {
        _busy = false;
        _error = e.message;
        _step = _Step.password;
      });
    }
  }

  Future<void> _signIn() async {
    final info = _info!;
    if (_username.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = await ref.read(mediaBrowserClientProvider.future);
      final auth = await MediaBrowserService.signIn(
        info,
        client,
        username: _username.text.trim(),
        password: _password.text,
      );
      await _done(auth);
    } on MediaServerUnreachable catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  Future<void> _done(MediaBrowserAuth auth) async {
    final info = _info!;
    await ref.read(mediaBrowserSessionProvider.notifier).add(info, auth);
    // The password field is cleared as soon as it is no longer needed; the
    // server's token is what is kept, in secure storage (§3).
    _password.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr.mediaBrowser.connected(name: info.name))),
    );
    context.go('/library');
  }

  void _restart() {
    _poll?.cancel();
    setState(() {
      _step = _Step.address;
      _info = null;
      _code = null;
      _error = null;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final info = _info;

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.ink,
        title: Text(tr.mediaBrowser.title),
      ),
      body: ListView(
        padding: RelayLayout.pagePadding(f).copyWith(top: 12, bottom: 32),
        children: [
          Text(
            tr.mediaBrowser.explain,
            style: TextStyle(color: t.inkDim, fontSize: 13.5, height: 1.55),
          ),
          const SizedBox(height: 22),
          if (info != null) ...[
            Row(
              children: [
                Icon(Icons.dns_outlined, color: t.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr.mediaBrowser.found(
                      name: info.name,
                      kind: info.kind.label,
                      version: info.version,
                    ),
                    style: TextStyle(
                      color: t.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          ...switch (_step) {
            _Step.address => [
              _Field(
                controller: _address,
                label: tr.mediaBrowser.address,
                hint: tr.mediaBrowser.addressHint,
                keyboard: TextInputType.url,
                onSubmitted: _find,
                autofocus: true,
              ),
              _Action(
                busy: _busy,
                busyLabel: tr.mediaBrowser.finding,
                label: tr.mediaBrowser.find,
                onPressed: _find,
              ),
            ],
            _Step.password => [
              _Field(
                controller: _username,
                label: tr.mediaBrowser.username,
                autofocus: true,
              ),
              _Field(
                controller: _password,
                label: tr.mediaBrowser.password,
                obscure: true,
                onSubmitted: _signIn,
              ),
              _Action(
                busy: _busy,
                busyLabel: tr.mediaBrowser.signingIn,
                label: tr.mediaBrowser.signIn,
                onPressed: _signIn,
              ),
              if (_quickConnect)
                RelayTextButton(
                  label: tr.mediaBrowser.useQuickConnect,
                  onPressed: _startQuickConnect,
                ),
            ],
            _Step.quickConnect => [
              Text(
                tr.mediaBrowser.quickConnectExplain,
                style: TextStyle(color: t.inkDim, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 14),
              if (_code case final code?)
                Center(
                  child: SelectableText(
                    code.code,
                    style: TextStyle(
                      color: t.ink,
                      fontSize: f == RelayFormFactor.tv ? 48 : 40,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                    ),
                  ),
                )
              else
                Center(child: CircularProgressIndicator(color: t.accent)),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  tr.mediaBrowser.waiting,
                  style: TextStyle(color: t.inkDim),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  RelayTextButton(
                    label: tr.mediaBrowser.usePassword,
                    autofocus: true,
                    onPressed: () {
                      _poll?.cancel();
                      setState(() => _step = _Step.password);
                    },
                  ),
                  if (_code case final code?
                      when RelayLayout.of(context) != RelayFormFactor.tv)
                    RelayTextButton(
                      label: tr.plex.copyCode,
                      onPressed: () =>
                          Clipboard.setData(ClipboardData(text: code.code)),
                    ),
                ],
              ),
            ],
          },
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              style: TextStyle(color: t.accent, fontSize: 13, height: 1.45),
            ),
          ],
          if (_step != _Step.address) ...[
            const SizedBox(height: 18),
            RelayTextButton(
              label: tr.mediaBrowser.otherAddress,
              onPressed: _restart,
            ),
          ],
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.busy,
    required this.busyLabel,
    required this.label,
    required this.onPressed,
  });

  final bool busy;
  final String busyLabel;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: RelayButton(
      label: busy ? busyLabel : label,
      onPressed: busy ? null : onPressed,
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.obscure = false,
    this.keyboard,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboard;
  final VoidCallback? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c),
    );
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
          RelayFieldTraversal(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              autofocus: autofocus,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: keyboard,
              textInputAction: onSubmitted == null
                  ? TextInputAction.next
                  : TextInputAction.done,
              onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
              style: TextStyle(color: t.ink),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: t.inkDim.withValues(alpha: 0.6)),
                filled: true,
                fillColor: t.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: border(t.line),
                enabledBorder: border(t.line),
                focusedBorder: border(t.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
