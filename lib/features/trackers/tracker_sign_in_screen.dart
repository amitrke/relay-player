import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/trackers/mal.dart';
import '../../data/trackers/tracker.dart';
import '../../i18n/strings.g.dart';
import 'trackers_controller.dart';

/// Signing in to one tracker (§19.2, §19.3), after its consent dialog.
///
/// Trakt and Simkl show a code to type at an address on any device, polled
/// until approved, so a TV types nothing. AniList and MyAnimeList need a
/// browser on this device or a paste; on a TV the screen says to sign in on
/// a phone and use Move to another device.
class TrackerSignInScreen extends ConsumerStatefulWidget {
  const TrackerSignInScreen({super.key, required this.kind});

  final TrackerKind kind;

  @override
  ConsumerState<TrackerSignInScreen> createState() =>
      _TrackerSignInScreenState();
}

class _TrackerSignInScreenState extends ConsumerState<TrackerSignInScreen> {
  SignInStart? _start;
  String? _error;
  bool _busy = false;
  Timer? _poll;
  MalRedirectCatcher? _catcher;
  final _paste = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_begin());
  }

  @override
  void dispose() {
    _poll?.cancel();
    unawaited(_catcher?.close());
    _paste.dispose();
    super.dispose();
  }

  TrackersController get _trackers => ref.read(trackersProvider.notifier);

  Future<void> _begin() async {
    setState(() {
      _error = null;
      _start = null;
    });
    try {
      final start = await _trackers.startSignIn(widget.kind);
      if (!mounted) return;
      setState(() => _start = start);
      switch (start) {
        case DeviceCodeSignIn():
          _poll = Timer.periodic(start.interval, (_) => _tryDeviceCode(start));
        case BrowserSignIn():
          if (widget.kind == TrackerKind.mal) unawaited(_catchRedirect(start));
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _tryDeviceCode(DeviceCodeSignIn start) async {
    if (_busy) return;
    _busy = true;
    try {
      await _trackers.finishSignIn(widget.kind, start);
      _poll?.cancel();
      _done();
    } on SignInPending {
      // Not yet.
    } on SignInFailed catch (e) {
      _poll?.cancel();
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      // A network blip while polling: try again next tick.
    } finally {
      _busy = false;
    }
  }

  /// On a device with a browser, MyAnimeList comes back to a loopback
  /// address the app is listening on, and nothing needs pasting.
  Future<void> _catchRedirect(BrowserSignIn start) async {
    _catcher = MalRedirectCatcher();
    final address = await _catcher!.wait();
    if (address != null && mounted) await _finishBrowser(start, address);
  }

  Future<void> _finishBrowser(BrowserSignIn start, String pasted) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _trackers.finishSignIn(widget.kind, start, pasted: pasted);
      _done();
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$e';
        });
      }
    }
  }

  void _done() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr.trackers.connected(service: widget.kind.label)),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final tv = f == RelayFormFactor.tv;
    final start = _start;

    Widget qr(String data) => Center(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(10),
        child: QrImageView(
          data: data,
          size: tv ? 180 : 160,
          backgroundColor: Colors.white,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.ink,
        title: Text(tr.trackers.signInTitle(service: widget.kind.label)),
      ),
      body: ListView(
        padding: RelayLayout.pagePadding(f).copyWith(top: 12, bottom: 32),
        children: [
          if (start == null && _error == null)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: t.accent)),
            ),
          if (start case DeviceCodeSignIn()) ...[
            Text(
              tr.trackers.deviceCodeExplain(url: start.verificationUrl),
              style: TextStyle(color: t.inkDim, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            Center(
              child: SelectableText(
                start.userCode,
                style: TextStyle(
                  color: t.ink,
                  fontSize: tv ? 46 : 38,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6,
                ),
              ),
            ),
            const SizedBox(height: 16),
            qr(start.verificationUrl),
            const SizedBox(height: 14),
            Center(
              child: Text(
                tr.trackers.waiting,
                style: TextStyle(color: t.inkDim),
              ),
            ),
          ],
          if (start case BrowserSignIn()) ...[
            Text(
              tr.trackers.browserExplain(service: widget.kind.label),
              style: TextStyle(color: t.inkDim, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            if (tv)
              Text(
                tr.trackers.tvHint,
                style: TextStyle(color: t.ink, fontSize: 14, height: 1.5),
              ),
            const SizedBox(height: 12),
            qr(start.url),
            const SizedBox(height: 10),
            Center(
              child: RelayTextButton(
                label: tr.trackers.copyAddress,
                onPressed: () => Clipboard.setData(ClipboardData(text: start.url)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.kind == TrackerKind.mal
                  ? tr.trackers.malPaste
                  : tr.trackers.anilistPaste,
              style: TextStyle(color: t.inkDim, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 10),
            RelayFieldTraversal(
              child: TextField(
                controller: _paste,
                autocorrect: false,
                enableSuggestions: false,
                style: TextStyle(color: t.ink),
                decoration: InputDecoration(
                  labelText: tr.trackers.pasteLabel,
                  labelStyle: TextStyle(color: t.inkDim),
                  filled: true,
                  fillColor: t.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: t.line),
                  ),
                ),
                onSubmitted: (v) => _finishBrowser(start, v),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: RelayButton(
                label: tr.trackers.finish,
                onPressed: _busy ? null : () => _finishBrowser(start, _paste.text),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: t.accent, fontSize: 13.5, height: 1.45),
            ),
            const SizedBox(height: 8),
            RelayTextButton(label: tr.common.tryAgain, onPressed: _begin),
          ],
        ],
      ),
    );
  }
}
