import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/transfer/lan_address.dart';
import '../../data/transfer/pairing.dart';
import '../../data/transfer/transfer_bundle.dart';
import '../../data/transfer/transfer_server.dart';
import 'transfer_service.dart';
import 'transfer_widgets.dart';

/// Settings -> Move to another device -> Receive (§17).
///
/// Shows a QR code and a short code, listens on the local network until a
/// bundle arrives, and writes nothing until the person here has seen what is in
/// it and said yes. The listener lives only as long as this screen does.
class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key, this.server, this.findAddress = findLanAddress});

  /// Test seams; the app always makes its own server and asks the OS for its
  /// address.
  final TransferServer? server;
  final Future<String?> Function() findAddress;

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

enum _Phase { starting, waiting, review, applying, done, failed }

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  late final TransferServer _server = widget.server ?? TransferServer();

  _Phase _phase = _Phase.starting;
  PairingInfo? _pairing;
  IncomingTransfer? _incoming;
  Set<TransferItem> _selected = {};
  String? _error;
  List<String> _notes = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    // Also tells a sender who is still waiting that the answer is no.
    unawaited(_server.close());
    super.dispose();
  }

  Future<void> _start() async {
    try {
      final host = await widget.findAddress();
      if (host == null) {
        _fail(
          'This device is not on a Wi-Fi or Ethernet network. Connect it to '
          'the same network as the other device and try again.',
        );
        return;
      }
      final pairing = await _server.start(host: host);
      if (!mounted) return;
      setState(() {
        _pairing = pairing;
        _phase = _Phase.waiting;
      });
      final incoming = await _server.incoming;
      if (!mounted) return;
      if (incoming == null) {
        // Closed with nothing received: it ran out of time, or was shut after
        // too many wrong codes. Either way the code on screen is dead.
        if (_phase == _Phase.waiting) {
          _fail('That code has expired. Start again for a new one.');
        }
        return;
      }
      setState(() {
        _incoming = incoming;
        _selected = {...incoming.bundle.items};
        _phase = _Phase.review;
      });
    } catch (e) {
      _fail('Could not start listening: $e');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _phase = _Phase.failed;
    });
  }

  Future<void> _apply() async {
    final incoming = _incoming;
    if (incoming == null || _selected.isEmpty) return;
    setState(() => _phase = _Phase.applying);
    try {
      final result = await ref
          .read(transferServiceProvider)
          .apply(incoming.bundle.only(_selected));
      // Only now does the sender hear that it worked.
      incoming.accept();
      if (!mounted) return;
      setState(() {
        _notes = result.notes;
        _phase = _Phase.done;
      });
    } on TransferApplyException catch (e) {
      incoming.decline();
      _fail(e.message);
    } catch (e) {
      incoming.decline();
      _fail('Could not save the settings: $e');
    }
  }

  void _decline() {
    _incoming?.decline();
    context.pop();
  }

  void _again() {
    // A listener takes one bundle, so another go needs a new screen.
    context.pushReplacement('/transfer/receive');
  }

  @override
  Widget build(BuildContext context) {
    return TransferScaffold(
      title: 'Receive settings',
      children: switch (_phase) {
        _Phase.starting => const [TransferBusy('Getting ready…')],
        _Phase.waiting => [_waiting(context)],
        _Phase.review => _review(context),
        _Phase.applying => const [TransferBusy('Saving…')],
        _Phase.done => _done(context),
        _Phase.failed => _failed(context),
      },
    );
  }

  Widget _waiting(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final pairing = _pairing!;

    final steps = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TransferText(
          'On the device that has your settings, open Settings, Move to '
          'another device, and choose Send. Then scan this code.',
        ),
        const SizedBox(height: 16),
        const TransferText(
          'No camera? Choose Type the code there, and enter:',
        ),
        const SizedBox(height: 10),
        Text(
          pairing.address,
          style: TextStyle(
            color: t.ink,
            fontSize: RelayLayout.bodySize(f) + 4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          pairing.displayCode,
          style: TextStyle(
            color: t.ink,
            fontSize: RelayLayout.bodySize(f) + 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 18),
        const TransferBusy('Waiting for the other device…'),
        const SizedBox(height: 6),
        Row(
          children: [
            RelayTextButton(
              label: 'Cancel',
              autofocus: true,
              onPressed: () => context.pop(),
            ),
            if (RelayLayout.of(context) != RelayFormFactor.tv)
              RelayTextButton(
                label: 'Copy code',
                onPressed: () => Clipboard.setData(
                  ClipboardData(text: '${pairing.address} ${pairing.displayCode}'),
                ),
              ),
          ],
        ),
      ],
    );

    // White with black modules whatever the theme: a scanner needs the contrast,
    // and an inverted code in a dark theme is the commonest way for scanning to
    // fail. The one place a fixed colour is correct.
    final qr = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(6),
      child: QrImageView(
        data: pairing.uri,
        size: f == RelayFormFactor.tv ? 200 : 220,
        backgroundColor: Colors.white,
        semanticsLabel: 'Code to scan from the other device',
      ),
    );

    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= 600
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(child: steps),
                const SizedBox(width: 32),
                qr,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: qr),
                const SizedBox(height: 20),
                steps,
              ],
            ),
    );
  }

  List<Widget> _review(BuildContext context) {
    final bundle = _incoming!.bundle;
    final items = TransferItem.values.where(bundle.items.contains).toList();
    return [
      const TransferText(
        'Another device wants to send you these. Anything that is already '
        'here with the same name is replaced; nothing else is removed.',
      ),
      const SizedBox(height: 18),
      TransferChecklist(
        items: items,
        selected: _selected,
        describe: bundle.describe,
        onToggle: (item) => setState(() {
          final next = {..._selected};
          if (!next.remove(item)) next.add(item);
          _selected = next;
        }),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          RelayButton(
            label: 'Save these',
            onPressed: _selected.isEmpty ? null : _apply,
          ),
          RelayTextButton(label: 'Decline', onPressed: _decline),
        ],
      ),
    ];
  }

  List<Widget> _done(BuildContext context) => [
    const TransferText('Done. Your settings are on this device.', dim: false, bold: true),
    for (final note in _notes) ...[
      const SizedBox(height: 12),
      TransferText(note),
    ],
    const SizedBox(height: 20),
    Align(
      alignment: Alignment.centerLeft,
      child: RelayButton(
        label: 'Done',
        autofocus: true,
        onPressed: () => context.pop(),
      ),
    ),
  ];

  List<Widget> _failed(BuildContext context) => [
    TransferError(_error ?? 'Something went wrong.'),
    const SizedBox(height: 18),
    Wrap(
      spacing: 12,
      children: [
        RelayButton(label: 'Try again', autofocus: true, onPressed: _again),
        RelayTextButton(label: 'Close', onPressed: () => context.pop()),
      ],
    ),
  ];
}
