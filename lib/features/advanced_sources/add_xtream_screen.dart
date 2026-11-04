import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/platform/device_kind.dart';
import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/xtream/provider_link.dart';
import '../../data/xtream/xtream_account_store.dart';
import '../../data/xtream/xtream_client.dart';
import 'setup_steps.dart';
import 'xtream_controller.dart';
import '../../i18n/strings.g.dart';

/// How the person has their login: the one long link most providers send, or
/// the server, username and password some send instead.
enum _Mode { link, login }

/// Adds an IPTV subscription (an Xtream line, §4), reachable only behind the
/// Advanced Sources gate. Step 1 of 3 ([SetupSteps]).
///
/// The form verifies before it saves. A panel that answers with `auth: 0`, or an
/// address that is not a panel at all, should be rejected here rather than
/// becoming a configured source that silently returns nothing.
///
/// **It starts by asking how the provider sent the login (2026-11-03).** It
/// used to open on four fields under the title "Xtream Codes login", which
/// assumed the person knew their provider's software and had the three parts
/// to hand. Most have one link from a welcome email instead, so that is the
/// first choice: paste it, and [ProviderLink] fills the same fields, which are
/// then checked exactly as typed ones are. The third choice brings across a
/// setup that already exists on another device (§17) rather than retyping it.
///
/// **On a TV the form opens on the fields.** Pasting is not something a remote
/// does, so there the link is not the starting choice; copying from a phone is
/// the better way in on a TV, and mockup row 5 is meant to make it the first.
class AddXtreamScreen extends ConsumerStatefulWidget {
  const AddXtreamScreen({super.key});

  @override
  ConsumerState<AddXtreamScreen> createState() => _AddXtreamScreenState();
}

class _AddXtreamScreenState extends ConsumerState<AddXtreamScreen> {
  final _link = TextEditingController();
  final _name = TextEditingController();
  final _host = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();

  /// Where the keyboard's Done on the last field sends focus (see [_Field]).
  final _verifyFocus = FocusNode();

  late _Mode _mode = DeviceKind.isTelevision ? _Mode.login : _Mode.link;
  bool _showPassword = false;
  bool _busy = false;
  String? _error;

  /// Set once the line is saved, or discarded on purpose, so leaving no
  /// longer loses anything by accident.
  bool _added = false;

  List<TextEditingController> get _fields => [
    _link,
    _host,
    _username,
    _password,
    _name,
  ];

  bool get _hasInput => _fields.any((c) => c.text.isNotEmpty);

  ProviderLink? get _parsed => ProviderLink.tryParse(_link.text);

  @override
  void initState() {
    super.initState();
    // Rebuilds so PopScope.canPop follows the fields: nothing typed means Back
    // can leave without asking. The link's preview follows it the same way.
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
  /// the button could not be reached. Focusing the button rather than
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

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    _link.text = text.trim();
  }

  void _choose(_Mode mode) => setState(() {
    _mode = mode;
    _error = null;
  });

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
        title: Text(
          tr.xtream.addLine.discardTitle,
          style: TextStyle(
            color: t.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          tr.xtream.addLine.discardBody,
          style: TextStyle(color: t.inkDim, fontSize: 14, height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: t.inkDim),
            child: Text(tr.xtream.addLine.discard),
          ),
          FilledButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            style: FilledButton.styleFrom(
              backgroundColor: t.accent,
              foregroundColor: t.accentInk,
            ),
            child: Text(tr.xtream.addLine.keepEditing),
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

  /// The name when none is given. It used to be the server address, which is
  /// the provider's own host: harmless on this device, but it then labelled
  /// the subscription in Settings and in Live TV, and in anything captured
  /// from them (§1). A plain label instead, numbered when it is taken.
  String _defaultName() {
    final base = tr.xtream.addLine.defaultName;
    final taken = {for (final a in ref.read(xtreamAccountsProvider)) a.name};
    if (!taken.contains(base)) return base;
    var n = 2;
    while (taken.contains('$base $n')) {
      n++;
    }
    return '$base $n';
  }

  Future<void> _verifyAndSave() async {
    // From a link, the same three fields the form has, so what follows is one
    // path whichever way the login arrived.
    if (_mode == _Mode.link) {
      final parsed = _parsed;
      if (parsed == null) {
        setState(() => _error = tr.xtream.addLine.notALink);
        _revealVerify();
        return;
      }
      _host.text = parsed.host;
      _username.text = parsed.username;
      _password.text = parsed.password;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final host = _normaliseHost(_host.text);
    final client = ref.read(xtreamClientFactoryProvider)(
      host: host,
      username: _username.text.trim(),
      password: _password.text,
    );

    try {
      final info = await client.authenticate();
      if (!info.isActive) {
        setState(() {
          _busy = false;
          _error = tr.xtream.addLine.inactive(status: info.status);
        });
        _revealVerify();
        return;
      }

      final account = XtreamAccount(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim().isEmpty ? _defaultName() : _name.text.trim(),
        host: host,
        username: _username.text.trim(),
      );
      await ref
          .read(xtreamAccountsProvider.notifier)
          .save(account, password: _password.text);

      if (!mounted) return;
      setState(() {
        _busy = false;
        _added = true;
      });
      // Step 2: what the provider said about the subscription, before any
      // choosing. Until 2026-11-03 this went straight to the category list,
      // and the "Connected" line set here was never on screen long enough to
      // be read.
      context.pushReplacement(
        '/advanced/xtream/${account.id}/connected',
        extra: info,
      );
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
    final parsed = _parsed;

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.ink,
        title: Text(tr.xtream.add),
      ),
      body: ListView(
        padding: RelayLayout.pagePadding(f).copyWith(top: 4, bottom: 32),
        children: [
          const SetupSteps(step: 1),
          const SizedBox(height: 22),
          Text(
            tr.xtream.addLine.how,
            style: TextStyle(
              color: t.ink,
              fontSize: RelayLayout.bodySize(f) + 5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr.xtream.addLine.howHint,
            style: TextStyle(color: t.inkDim, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          _ModeOption(
            icon: Icons.link,
            title: tr.xtream.addLine.modeLink,
            subtitle: tr.xtream.addLine.modeLinkSub,
            selected: _mode == _Mode.link,
            onTap: () => _choose(_Mode.link),
          ),
          _ModeOption(
            icon: Icons.vpn_key_outlined,
            title: tr.xtream.addLine.modeLogin,
            subtitle: tr.xtream.addLine.modeLoginSub,
            selected: _mode == _Mode.login,
            onTap: () => _choose(_Mode.login),
          ),
          _ModeOption(
            icon: Icons.devices_outlined,
            title: tr.xtream.addLine.modeDevice,
            subtitle: tr.xtream.addLine.modeDeviceSub,
            selected: false,
            onTap: () => context.push('/transfer/receive'),
          ),
          const SizedBox(height: 16),
          if (_mode == _Mode.link) ...[
            _Field(
              controller: _link,
              label: tr.xtream.addLine.link,
              keyboardType: TextInputType.url,
              lines: 3,
              trailing: RelayFocusHalo(
                borderRadius: BorderRadius.circular(8),
                child: TextButton(
                  onPressed: _paste,
                  style: TextButton.styleFrom(foregroundColor: t.accent),
                  child: Text(tr.xtream.addLine.paste),
                ),
              ),
            ),
            if (parsed != null)
              _FoundLogin(
                parsed: parsed,
                showPassword: _showPassword,
                onTogglePassword: () =>
                    setState(() => _showPassword = !_showPassword),
              )
            else if (_link.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  tr.xtream.addLine.notALink,
                  style: TextStyle(color: t.inkDim, fontSize: 13, height: 1.5),
                ),
              ),
          ] else ...[
            _Field(
              controller: _host,
              label: tr.xtream.addLine.host,
              hint: tr.xtream.addLine.hostHint,
              keyboardType: TextInputType.url,
            ),
            _Field(controller: _username, label: tr.smb.username),
            _Field(
              controller: _password,
              label: tr.smb.password,
              obscure: true,
            ),
          ],
          _Field(
            controller: _name,
            label: tr.xtream.addLine.name,
            hint: tr.xtream.addLine.nameHint,
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
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFB8574E),
                    size: 18,
                  ),
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
            label: _busy
                ? tr.xtream.addLine.checking
                : tr.xtream.addLine.verify,
            focusNode: _verifyFocus,
            onPressed: _busy ? () {} : _verifyAndSave,
          ),
          const SizedBox(height: 22),
          // Below the button now, not above the form: it is the same
          // statement the acknowledgement made a moment ago (§8.2), and at the
          // top it was the first thing on a screen meant to say "this is easy".
          Text(
            tr.xtream.addLine.noContent,
            style: TextStyle(color: t.inkDim, fontSize: 12.5, height: 1.55),
          ),
        ],
      ),
    );
  }
}

/// One of the three ways in. A radio-like row rather than a segmented
/// control: each needs a sentence of its own, since the names providers give
/// these things ("M3U", "Xtream Codes") are exactly what people do not know.
class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        selected: selected,
        // RelayTappable and not RelaySurface(onTap:): the surface draws its own focus
        // shadow, which the D-pad audit does not count as a ring, and its
        // InkWell adds a second stop with no ring at all (test/dpad, 2026-11-03).
        child: RelayTappable(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? t.accent : t.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: selected ? t.accent : t.inkDim),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: t.ink,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: t.inkDim,
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What was read out of the link, before anything is sent: so a wrong paste
/// shows up here, and not as "wrong username or password" from the provider.
/// The password is hidden unless asked for, as in the typed form.
class _FoundLogin extends StatelessWidget {
  const _FoundLogin({
    required this.parsed,
    required this.showPassword,
    required this.onTogglePassword,
  });

  final ProviderLink parsed;
  final bool showPassword;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final valueStyle = TextStyle(color: t.ink, fontSize: 13.5);
    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: TextStyle(color: t.inkDim, fontSize: 13)),
          ),
          Expanded(child: value),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: RelaySurface(
        borderColor: t.accent,
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: t.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr.xtream.addLine.found,
                    style: TextStyle(
                      color: t.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            row(
              tr.xtream.addLine.server,
              Text(
                parsed.host,
                style: valueStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            row(
              tr.smb.username,
              Text(
                parsed.username,
                style: valueStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            row(
              tr.smb.password,
              Row(
                children: [
                  Expanded(
                    child: Text(
                      showPassword
                          ? parsed.password
                          : '•' * parsed.password.length.clamp(6, 12),
                      style: valueStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  RelayFocusHalo(
                    borderRadius: BorderRadius.circular(8),
                    child: TextButton(
                      onPressed: onTogglePassword,
                      style: TextButton.styleFrom(foregroundColor: t.accent),
                      child: Text(
                        showPassword
                            ? tr.xtream.addLine.hide
                            : tr.xtream.addLine.show,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    this.lines = 1,
    this.trailing,
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

  /// More than one for the link, which is long and wraps: a field that
  /// scrolled sideways hid the part of it that matters, the login.
  final int lines;

  /// Beside the label: the link's Paste button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: t.inkDim,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ?trailing,
            ],
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
              minLines: lines,
              maxLines: lines,
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
