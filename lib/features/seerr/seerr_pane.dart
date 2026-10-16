import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/seerr/seerr_client.dart';
import '../../i18n/strings.g.dart';
import 'seerr_controller.dart';

/// Settings → Requests (§20): connect an Overseerr, Jellyseerr or Seerr
/// server, and see what has been asked for.
class SeerrPane extends ConsumerWidget {
  const SeerrPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final client = ref.watch(seerrProvider);
    final style = TextStyle(color: t.inkDim, fontSize: 13.5, height: 1.6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr.seerr.intro, style: style),
        const SizedBox(height: 18),
        if (client == null) const _ConnectForm() else _Connected(client),
      ],
    );
  }
}

class _Connected extends ConsumerWidget {
  const _Connected(this.client);
  final SeerrClient client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = RelayTheme.of(context);
    final requests = ref.watch(seerrRequestsProvider);
    String status(SeerrRequest r) =>
        r.availability == SeerrAvailability.available
        ? tr.seerr.statusAvailable
        : switch (r.status) {
            2 => tr.seerr.statusApproved,
            3 => tr.seerr.statusDeclined,
            _ => tr.seerr.statusPending,
          };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: t.accent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tr.seerr.connected(
                  title: client.info.title,
                  name: client.session.userName ?? '',
                ),
                style: TextStyle(
                  color: t.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            RelayTextButton(
              label: tr.seerr.disconnect,
              onPressed: () => ref.read(seerrProvider.notifier).disconnect(),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          tr.seerr.myRequests,
          style: TextStyle(
            color: t.ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        requests.when(
          loading: () => Padding(
            padding: const EdgeInsets.all(12),
            child: CircularProgressIndicator(color: t.accent),
          ),
          error: (e, _) => Text('$e', style: TextStyle(color: t.inkDim)),
          data: (list) => list.isEmpty
              ? Text(tr.seerr.none, style: TextStyle(color: t.inkDim))
              : Column(
                  children: [
                    for (final r in list)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.title,
                                style: TextStyle(color: t.ink, fontSize: 14),
                              ),
                            ),
                            Text(
                              status(r),
                              style: TextStyle(color: t.inkDim, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

enum _Method { plex, password, apiKey }

class _ConnectForm extends ConsumerStatefulWidget {
  const _ConnectForm();

  @override
  ConsumerState<_ConnectForm> createState() => _ConnectFormState();
}

class _ConnectFormState extends ConsumerState<_ConnectForm> {
  final _address = TextEditingController();
  final _user = TextEditingController();
  final _password = TextEditingController();
  final _key = TextEditingController();
  SeerrServerInfo? _info;
  _Method? _method;
  bool _busy = false;
  String? _error;
  bool _hasPlex = false;

  @override
  void dispose() {
    _address.dispose();
    _user.dispose();
    _password.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() body) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await body();
    } on SeerrException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _find() => _run(() async {
    final info = await SeerrClient.probe(_address.text);
    final plex = await ref.read(seerrProvider.notifier).plexAccountToken();
    if (!mounted) return;
    setState(() {
      _info = info;
      _hasPlex = info.usesPlex && plex != null;
      _method = _hasPlex ? _Method.plex : _Method.password;
    });
  });

  Future<void> _connect() => _run(() async {
    final info = _info!;
    final session = switch (_method!) {
      _Method.plex => await SeerrClient.signIn(
        info,
        plexToken: await ref.read(seerrProvider.notifier).plexAccountToken(),
      ),
      _Method.password => await SeerrClient.signIn(
        info,
        username: _user.text.trim(),
        password: _password.text,
      ),
      _Method.apiKey => await SeerrClient.signIn(
        info,
        apiKey: _key.text.trim(),
      ),
    };
    _password.clear();
    await ref.read(seerrProvider.notifier).connect(info, session);
  });

  Widget _field(
    TextEditingController c,
    String label, {
    String? hint,
    bool obscure = false,
  }) {
    final t = RelayTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RelayFieldTraversal(
        child: TextField(
          controller: c,
          obscureText: obscure,
          autocorrect: false,
          enableSuggestions: false,
          style: TextStyle(color: t.ink),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            labelStyle: TextStyle(color: t.inkDim),
            filled: true,
            fillColor: t.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: t.line),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final info = _info;
    Widget choice(_Method m, String label) => RelayTappable(
      borderRadius: 10,
      onTap: () => setState(() => _method = m),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              _method == m
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: _method == m ? t.accent : t.inkDim,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: TextStyle(color: t.ink, fontSize: 14)),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info == null) ...[
          _field(_address, tr.seerr.address, hint: tr.seerr.addressHint),
          Align(
            alignment: Alignment.centerLeft,
            child: RelayButton(
              label: _busy ? tr.seerr.connecting : tr.seerr.find,
              onPressed: _busy ? null : _find,
            ),
          ),
        ] else ...[
          Text(
            info.title,
            style: TextStyle(
              color: t.ink,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (_hasPlex) choice(_Method.plex, tr.seerr.withPlex),
          choice(_Method.password, tr.seerr.withPassword),
          choice(_Method.apiKey, tr.seerr.withKey),
          const SizedBox(height: 10),
          if (_method == _Method.password) ...[
            _field(_user, tr.seerr.username),
            _field(_password, tr.seerr.password, obscure: true),
          ],
          if (_method == _Method.apiKey) ...[
            _field(_key, tr.seerr.apiKey, obscure: true),
            Text(
              tr.seerr.keyNote,
              style: TextStyle(color: t.inkDim, fontSize: 12.5, height: 1.5),
            ),
            const SizedBox(height: 10),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: RelayButton(
              label: _busy ? tr.seerr.connecting : tr.seerr.connect,
              onPressed: _busy ? null : _connect,
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: t.accent, fontSize: 13)),
        ],
      ],
    );
  }
}
