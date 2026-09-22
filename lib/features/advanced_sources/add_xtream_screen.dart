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

  bool _busy = false;
  String? _error;
  XtreamAccountInfo? _info;

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
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
          if (_busy)
            Center(child: CircularProgressIndicator(color: t.accent))
          else
            RelayButton(label: 'Verify and add', onPressed: _verifyAndSave),
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
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;

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
            keyboardType: keyboardType,
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
