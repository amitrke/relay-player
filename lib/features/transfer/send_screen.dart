import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/platform/device_kind.dart';
import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/transfer/lan_address.dart';
import '../../data/transfer/pairing.dart';
import '../../data/transfer/transfer_bundle.dart';
import '../../data/transfer/transfer_client.dart';
import '../../data/transfer/transfer_offer.dart';
import 'pairing_widgets.dart';
import 'transfer_service.dart';
import 'transfer_widgets.dart';

/// Settings -> Move to another device -> Send (§17).
///
/// Pick what to move, then pair with the other device in whichever of three ways
/// suits the two of them (§17.7):
///
/// - **Scan** the code it shows, on a device with a camera.
/// - **Show** a code for it to scan, on a device without one. This is how a TV
///   sends to a phone with nothing typed.
/// - **Type** the address and code, when neither can scan.
///
/// Nothing leaves this device until a pairing is in hand, and what is sent is
/// sealed with that pairing's secret. When this device shows the code, each
/// request to be sent the settings also waits for a person here to say yes.
class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({
    super.key,
    this.client = const TransferClient(),
    this.canScan,
    this.makeOfferServer,
    this.findAddress = findLanAddress,
  });

  /// Test seams. [canScan] defaults to "a phone or tablet with a camera".
  final TransferClient client;
  final bool? canScan;
  final TransferOfferServer Function()? makeOfferServer;
  final Future<String?> Function() findAddress;

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

enum _Phase { loading, choose, connect, sending, done, failed }

enum _Mode { scan, show, type }

class _SendScreenState extends ConsumerState<SendScreen> {
  _Phase _phase = _Phase.loading;
  CollectedSettings? _collected;
  Set<TransferItem> _selected = {};
  String? _error;

  _Mode _mode = _Mode.type;
  TransferOfferServer? _offer;
  PairingInfo? _offerPairing;

  /// Bumped whenever the code on offer changes or is withdrawn, so a late answer
  /// from an old listener is recognised and ignored.
  int _generation = 0;

  /// The camera exists on a phone or tablet. A TV has none, and a desktop's
  /// webcam is not what anyone points at another screen.
  bool get _canScan =>
      widget.canScan ??
      (!DeviceKind.isTelevision && (Platform.isAndroid || Platform.isIOS));

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _generation++;
    unawaited(_offer?.close());
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final collected = await ref.read(transferServiceProvider).collect();
      if (!mounted) return;
      setState(() {
        _collected = collected;
        _selected = {...collected.bundle.items};
        _phase = _Phase.choose;
      });
    } catch (e) {
      _fail('Could not read this device\'s settings: $e');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _phase = _Phase.failed;
    });
  }

  // --- Pairing ---------------------------------------------------------

  /// Where to start: scan when there is a camera, otherwise show a code, so a
  /// device that cannot scan is never left typing by default.
  void _toConnect() => unawaited(_setMode(_canScan ? _Mode.scan : _Mode.show));

  Future<void> _setMode(_Mode mode) async {
    await _withdrawOffer();
    if (!mounted) return;
    setState(() {
      _mode = mode;
      _error = null;
      _phase = _Phase.connect;
    });
    if (mode == _Mode.show) await _startOffer();
  }

  Future<void> _withdrawOffer() async {
    _generation++;
    final offer = _offer;
    _offer = null;
    _offerPairing = null;
    await offer?.close();
  }

  Future<void> _startOffer() async {
    final generation = ++_generation;
    final host = await widget.findAddress();
    if (!mounted || generation != _generation) return;
    if (host == null) {
      _fail(
        'This device is not on a Wi-Fi or Ethernet network. Connect it to the '
        'same network as the other device and try again.',
      );
      return;
    }

    final offer = widget.makeOfferServer?.call() ?? TransferOfferServer();
    try {
      final pairing = await offer.start(host: host);
      if (!mounted || generation != _generation) {
        await offer.close();
        return;
      }
      setState(() {
        _offer = offer;
        _offerPairing = pairing;
      });
      unawaited(_awaitRequest(offer, pairing, generation));
    } catch (e) {
      _fail('Could not start listening: $e');
    }
  }

  Future<void> _awaitRequest(
    TransferOfferServer offer,
    PairingInfo pairing,
    int generation,
  ) async {
    final request = await offer.request;
    if (!mounted || generation != _generation) {
      request?.deny();
      return;
    }
    if (request == null) {
      _fail('That code has expired. Start again for a new one.');
      return;
    }

    final allowed = await _askApproval(request);
    if (!mounted || generation != _generation) {
      request.deny();
      return;
    }
    if (allowed != true) {
      request.deny();
      // Back to a fresh code: the old one has answered once and is spent.
      await _setMode(_Mode.show);
      return;
    }
    request.approve();
    await _send(
      PairingInfo(
        host: request.host,
        port: request.port,
        secret: pairing.secret,
      ),
    );
  }

  /// The person here sees who is asking, and what would go, before anything does.
  ///
  /// This is the control that makes showing a code safe. A code on a screen can
  /// be photographed by anyone in the room, and without this they would simply be
  /// handed the settings. "Not now" is focused first so a stray press on a remote
  /// refuses rather than sends.
  Future<bool?> _askApproval(PushRequest request) {
    final bundle = _collected!.bundle.only(_selected);
    final kinds = TransferItem.values.where(bundle.items.contains);
    final summary = [for (final k in kinds) bundle.titled(k)].join('\n');
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final t = RelayTheme.of(context);
        return AlertDialog(
          backgroundColor: t.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            'Send to ${request.host}?',
            style: TextStyle(
              color: t.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'A device on your network scanned this code and is asking for:\n\n'
            '$summary\n\n'
            'Only agree if you just asked for this on that device.',
            style: TextStyle(color: t.inkDim, fontSize: 14, height: 1.55),
          ),
          actions: [
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: t.inkDim),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: t.accent,
                foregroundColor: t.accentInk,
              ),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _send(PairingInfo pairing) async {
    if (_phase == _Phase.sending) return;
    setState(() => _phase = _Phase.sending);
    try {
      await widget.client.send(pairing, _collected!.bundle.only(_selected));
      if (!mounted) return;
      setState(() => _phase = _Phase.done);
    } on TransferException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail('Something went wrong: $e');
    }
  }

  // --- Build -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return TransferScaffold(
      title: 'Send settings',
      children: switch (_phase) {
        _Phase.loading => const [TransferBusy('Reading your settings…')],
        _Phase.choose => _choose(context),
        _Phase.connect => _connect(context),
        _Phase.sending => const [
          TransferBusy(
            'Sending. The other device will ask before it saves anything.',
          ),
        ],
        _Phase.done => _done(context),
        _Phase.failed => _failed(context),
      },
    );
  }

  List<Widget> _choose(BuildContext context) {
    final collected = _collected!;
    final bundle = collected.bundle;
    final items = TransferItem.values.where(bundle.items.contains).toList();

    return [
      const TransferText(
        'Copies these to another device on the same Wi-Fi, so you do not have '
        'to type them again. It goes straight there and is encrypted; nothing '
        'passes through us.',
      ),
      const SizedBox(height: 18),
      if (items.isEmpty)
        const TransferText(
          'There is nothing set up on this device to send yet.',
        )
      else
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
      for (final note in collected.notes) ...[
        const SizedBox(height: 4),
        TransferText(note),
      ],
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: RelayButton(
          label: 'Continue',
          onPressed: _selected.isEmpty ? null : _toConnect,
        ),
      ),
    ];
  }

  /// The ways to pair other than the one on screen, and Back.
  List<Widget> _modeButtons({bool autofocusFirst = false}) {
    var first = autofocusFirst;
    bool take() {
      final v = first;
      first = false;
      return v;
    }

    return [
      if (_mode != _Mode.scan && _canScan)
        RelayTextButton(
          label: 'Scan its code instead',
          autofocus: take(),
          onPressed: () => unawaited(_setMode(_Mode.scan)),
        ),
      if (_mode != _Mode.show)
        RelayTextButton(
          label: 'Show a code instead',
          autofocus: take(),
          onPressed: () => unawaited(_setMode(_Mode.show)),
        ),
      if (_mode != _Mode.type)
        RelayTextButton(
          label: 'Type the code instead',
          autofocus: take(),
          onPressed: () => unawaited(_setMode(_Mode.type)),
        ),
      RelayTextButton(
        label: 'Back',
        autofocus: take(),
        onPressed: () async {
          await _withdrawOffer();
          if (mounted) setState(() => _phase = _Phase.choose);
        },
      ),
    ];
  }

  List<Widget> _connect(BuildContext context) {
    switch (_mode) {
      case _Mode.scan:
        return [
          const TransferText(
            'On the other device, open Settings, Move to another device, and '
            'choose Receive. Point the camera at the code it shows.',
          ),
          const SizedBox(height: 16),
          PairingScanner(onPairing: (p) => unawaited(_send(p))),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: _modeButtons()),
        ];
      case _Mode.show:
        final pairing = _offerPairing;
        if (pairing == null) return const [TransferBusy('Getting ready…')];
        return [
          PairingDisplay(
            pairing: pairing,
            instructions:
                'On the other device, open Settings, Move to another device, '
                'and choose Receive, then Scan its code and point its camera '
                'here. You will be asked before anything is sent.',
            waitingLabel: 'Waiting for the other device…',
            actions: _modeButtons(autofocusFirst: true),
          ),
        ];
      case _Mode.type:
        return [
          const TransferText(
            'On the other device, open Settings, Move to another device, and '
            'choose Receive. Then enter what it shows.',
          ),
          const SizedBox(height: 16),
          PairingEntry(
            submitLabel: 'Send',
            onSubmit: (p) => unawaited(_send(p)),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: _modeButtons()),
        ];
    }
  }

  List<Widget> _done(BuildContext context) => [
    const TransferText(
      'Sent. The other device has saved your settings.',
      dim: false,
      bold: true,
    ),
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
        // Back to the code step, not the start: the choice of what to send is
        // still right, and the receiver needs a fresh code only if it says so.
        RelayButton(
          label: 'Try again',
          autofocus: true,
          onPressed: _collected == null ? _load : _toConnect,
        ),
        RelayTextButton(label: 'Close', onPressed: () => context.pop()),
      ],
    ),
  ];
}
