import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/xtream/xtream_account_store.dart';
import '../../data/xtream/xtream_client.dart';
import 'xtream_controller.dart';

/// Adds an Xtream line (§4), reachable only behind the Advanced Sources gate.
///
/// The form verifies before it saves. A panel that answers with `auth: 0`, or an
/// address that is not a panel at all, should be rejected here rather than
/// becoming a configured source that silently returns nothing.
class AddXtreamScreen extends ConsumerStatefulWidget {
  const AddXtreamScreen({super.key});

  @override
  ConsumerState<AddXtreamScreen> createState() => _AddXtreamScreenState();
}

class _AddXtreamScreenState extends ConsumerState<AddXtreamScreen> {
  final _name = TextEditingController();
  final _host = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();

  /// Where the keyboard's Done on the last field sends focus (see [_Field]).
  final _verifyFocus = FocusNode();

  bool _busy = false;
  String? _error;
  XtreamAccountInfo? _info;

  /// Set once the line is saved, or discarded on purpose, so leaving no
  /// longer loses anything by accident.
  bool _added = false;

  List<TextEditingController> get _fields =>
      [_host, _username, _password, _name];

  bool get _hasInput => _fields.any((c) => c.text.isNotEmpty);

  @override
  void initState() {
    super.initState();
    // Rebuilds so PopScope.canPop follows the fields: nothing typed means Back
    // can leave without asking.
    for (final c in _fields) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    for (final c in _fields) {
      c.removeListener(_onFieldChanged);
      c.dispose();
    }
    _verifyFocus.dispose();
    super.dispose();
  }

  /// The keyboard's Done on the last field: go to the button, not nowhere.
  ///
  /// Done's default is to unfocus, which on a remote leaves no focus at all:
  /// seen on the Chromecast 2026-09-28, where the D-pad then did nothing and
  /// *Verify and add* could not be reached. Focusing the button rather than
  /// pressing it keeps one deliberate OK between typing and a network call.
  /// The button can sit below the fold on a TV, so it is scrolled into view.
  void _toVerify() {
    _verifyFocus.requestFocus();
    _revealVerify();
  }

  /// Scrolls the button into view after the frame that moved it.
  ///
  /// Needed after a failed check too: the error box is inserted above the
  /// button and pushes it below the fold on a TV, where focus stays on it but
  /// nothing scrolls to follow.
  void _revealVerify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final button = _verifyFocus.context;
      if (button != null && button.mounted) {
        Scrollable.ensureVisible(button, alignment: 0.5);
      }
    });
  }

  /// Back with something typed asks first.
  ///
  /// On a remote, Back is also how the keyboard is closed, so one press too
  /// many used to leave the screen and throw away a server address, username
  /// and password typed a letter at a time (found on the Chromecast,
  /// 2026-09-28). *Keep editing* has initial focus, so the same slip twice
  /// still keeps the form.
  Future<void> _confirmLeave() async {
    final t = RelayTheme.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Discard this line?',
            style: TextStyle(
                color: t.ink, fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(
          'What you typed here has not been saved.',
          style: TextStyle(color: t.inkDim, fontSize: 14, height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: t.inkDim),
            child: const Text('Discard'),
          ),
          FilledButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            style: FilledButton.styleFrom(
                backgroundColor: t.accent, foregroundColor: t.accentInk),
            child: const Text('Keep editing'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      setState(() => _added = true); // Lets the pop below through.
      Navigator.of(context).pop();
    }
  }

  /// Accepts what people actually paste: a bare host, a host:port, or a full
  /// URL with a trailing slash or a `/player_api.php` already on the end.
  static String _normaliseHost(String raw) {
    var host = raw.trim();
    if (host.isEmpty) return host;
    if (!host.contains('://')) host = 'http://$host';
    final uri = Uri.tryParse(host);
    if (uri == null) return host;
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  Future<void> _verifyAndSave() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });

    final host = _normaliseHost(_host.text);
    final client = XtreamClient(
      host: host,
      username: _username.text.trim(),
      password: _password.text,
    );

    try {
      final info = await client.authenticate();
      if (!info.isActive) {
        setState(() {
          _busy = false;
          _error = 'The panel says this line is "${info.status}".';
        });
        _revealVerify();
        return;
      }

      final account = XtreamAccount(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim().isEmpty ? host : _name.text.trim(),
        host: host,
        username: _username.text.trim(),
      );
      await ref
          .read(xtreamAccountsProvider.notifier)
          .save(account, password: _password.text);

      if (!mounted) return;
      setState(() {
        _busy = false;
        _info = info;
        _added = true;
      });
      // Straight into category selection: §4.1 is opt-in, so a line with
      // nothing chosen yet shows an empty Live TV tab until the user picks.
      context.pushReplacement(
          '/advanced/xtream/${account.id}/categories/live');
    } on XtreamException catch (e) {
      setState(() {
        _busy = false;
        _error = e.message;
      });
      _revealVerify();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _added || !_hasInput,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: _form(context),
    );
  }

  Widget _form(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.ink,
        title: const Text('Add a playlist or panel'),
      ),
      body: ListView(
        padding: RelayLayout.pagePadding(f).copyWith(top: 12, bottom: 32),
        children: [
          Text(
            'Subnext Player does not provide, host, or endorse any content or '
            'provider. You supply the address and the login, and the app plays '
            'whatever that address returns.',
            style: TextStyle(color: t.inkDim, fontSize: 13, height: 1.55),
          ),
          const SizedBox(height: 22),
          _Field(
            controller: _host,
            label: 'Server address',
            hint: 'host:port',
            keyboardType: TextInputType.url,
          ),
          _Field(controller: _username, label: 'Username'),
          _Field(controller: _password, label: 'Password', obscure: true),
          _Field(
            controller: _name,
            label: 'Name (optional)',
            hint: 'What you want to call this line',
            action: TextInputAction.done,
            onSubmitted: _toVerify,
          ),
          const SizedBox(height: 10),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFB8574E)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFFB8574E), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: t.ink, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Stays in the tree while checking, rather than swapping for a
          // spinner as it did until 2026-09-28: removing the button took the
          // remote's focus with it, so after a failed check (a typo, a panel
          // that is down) the D-pad had nothing to land on. A no-op rather
          // than null while busy, because a disabled button drops focus too.
          // Keyed because the error box is inserted above it: unkeyed, the
          // list matched children by position, rebuilt the button as a new
          // element and dropped its focus (seen on the TV emulator).
          RelayButton(
            key: const ValueKey('verify'),
            label: _busy ? 'Checking…' : 'Verify and add',
            focusNode: _verifyFocus,
            onPressed: _busy ? () {} : _verifyAndSave,
          ),
          if (_info != null) ...[
            const SizedBox(height: 16),
            Text(
              'Connected. ${_info!.maxConnections} concurrent stream'
              '${_info!.maxConnections == 1 ? '' : 's'} allowed.',
              style: TextStyle(color: t.inkDim, fontSize: 13),
            ),
          ],
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
    this.keyboardType,
    this.action = TextInputAction.next,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;

  /// The keyboard's action key. On a TV this is the only way through the form
  /// that does not mean dismissing the keyboard and walking focus by hand:
  /// while the keyboard is up the D-pad moves across its keys, not between
  /// fields (see TvImeProxyView on the Android side). `next` moves focus to the
  /// following field and reopens the keyboard there.
  final TextInputAction action;

  /// Replaces the action's default. Set on the last field, whose `done` would
  /// otherwise drop focus altogether.
  final VoidCallback? onSubmitted;

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
          RelayFieldTraversal(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: keyboardType,
              textInputAction: action,
              onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
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
          ),
        ],
      ),
    );
  }
}
