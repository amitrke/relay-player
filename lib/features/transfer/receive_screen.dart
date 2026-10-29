import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/platform/device_kind.dart';
import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/transfer/lan_address.dart';
import '../../data/transfer/pairing.dart';
import '../../data/transfer/transfer_bundle.dart';
import '../../data/transfer/transfer_client.dart';
import '../../data/transfer/transfer_server.dart';
import 'pairing_widgets.dart';
import 'transfer_service.dart';
import 'transfer_widgets.dart';
import '../../i18n/strings.g.dart';

/// Settings -> Move to another device -> Receive (§17).
///
/// By default it shows a QR code and a short code and listens on the local
/// network until a bundle arrives. When the *other* device is the one without a
/// camera, it can instead **scan or type that device's code** (§17.7): this
/// device then listens under that code's secret and asks the other to send,
/// and the other asks its own person first.
///
/// Either way nothing is written until the person here has seen what arrived
/// and said yes, and the listener lives only as long as this screen does.
class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({
    super.key,
    this.server,
    this.makeServer,
    this.client = const TransferClient(),
    this.canScan,
    this.findAddress = findLanAddress,
  });

  /// Test seams. [server] is the first listener this screen starts, and
  /// [makeServer] makes any later one (a screen that joins the other device's
  /// code replaces its listener). The app makes its own, asks the OS for its
  /// address, and decides for itself whether there is a camera.
  final TransferServer? server;
  final TransferServer Function()? makeServer;
  final TransferClient client;
  final bool? canScan;
  final Future<String?> Function() findAddress;

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

enum _Phase {
  starting,
  waiting,
  scan,
  type,
  joining,
  awaitingPush,
  review,
  applying,
  done,
  failed,
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  _Phase _phase = _Phase.starting;
  TransferServer? _server;
  PairingInfo? _pairing;
  IncomingTransfer? _incoming;
  Set<TransferItem> _selected = {};
  String? _error;
  List<String> _notes = const [];
  bool _usedSeam = false;

  /// Bumped whenever the listener changes, so an answer from one that has been
  /// replaced is recognised and ignored.
  int _generation = 0;

  bool get _canScan =>
      widget.canScan ??
      (!DeviceKind.isTelevision && (Platform.isAndroid || Platform.isIOS));

  @override
  void initState() {
    super.initState();
    unawaited(_showMine());
  }

  @override
  void dispose() {
    _generation++;
    // Also tells a sender who is still waiting that the answer is no.
    unawaited(_server?.close());
    super.dispose();
  }

  // --- Listening -------------------------------------------------------

  /// Starts a listener, replacing any there is, and waits in the background for
  /// something to arrive. [secret] is the other device's, when joining its code.
  Future<PairingInfo?> _listen({Uint8List? secret}) async {
    final generation = ++_generation;
    final previous = _server;
    _server = null;
    await previous?.close();

    final host = await widget.findAddress();
    if (!mounted || generation != _generation) return null;
    if (host == null) {
      _fail(tr.transfer.noNetwork);
      return null;
    }

    final TransferServer server;
    if (!_usedSeam && widget.server != null) {
      _usedSeam = true;
      server = widget.server!;
    } else {
      server = widget.makeServer?.call() ?? TransferServer();
    }
    try {
      final pairing = await server.start(host: host, secret: secret);
      if (!mounted || generation != _generation) {
        await server.close();
        return null;
      }
      _server = server;
      unawaited(_awaitIncoming(server, generation));
      return pairing;
    } catch (e) {
      _fail(tr.transfer.cannotListen(error: '$e'));
      return null;
    }
  }

  Future<void> _awaitIncoming(TransferServer server, int generation) async {
    final incoming = await server.incoming;
    if (!mounted || generation != _generation) return;
    if (incoming == null) {
      // Closed with nothing received: it ran out of time, or was shut after
      // too many wrong codes. Either way the code involved is dead.
      if (_phase == _Phase.waiting ||
          _phase == _Phase.joining ||
          _phase == _Phase.awaitingPush) {
        _fail(tr.transfer.expired);
      }
      return;
    }
    setState(() {
      _incoming = incoming;
      _selected = {...incoming.bundle.items};
      _phase = _Phase.review;
    });
  }

  Future<void> _stopListening() async {
    _generation++;
    final server = _server;
    _server = null;
    await server?.close();
  }

  /// Shows this device's own code, which is where it starts.
  Future<void> _showMine() async {
    setState(() => _phase = _Phase.starting);
    final pairing = await _listen();
    if (pairing == null || !mounted) return;
    setState(() {
      _pairing = pairing;
      _phase = _Phase.waiting;
    });
  }

  Future<void> _choose(_Phase phase) async {
    // No code is on screen while this device reads the other's, so nothing
    // should be listening for it.
    await _stopListening();
    if (mounted) setState(() => _phase = phase);
  }

  /// Joins a code the other device is showing: listens under its secret, then
  /// asks it to send. It asks its own person first, so this may take a while.
  Future<void> _join(PairingInfo offer) async {
    if (_phase == _Phase.joining) return;
    setState(() => _phase = _Phase.joining);
    final mine = await _listen(secret: offer.secret);
    if (mine == null || !mounted) return;
    try {
      await widget.client.requestPush(offer, mine.port);
      // The bundle can arrive before this returns; only step forward, never
      // back over the review.
      if (mounted && _phase == _Phase.joining) {
        setState(() => _phase = _Phase.awaitingPush);
      }
    } on TransferException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail(tr.transfer.wentWrong(error: '$e'));
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _phase = _Phase.failed;
    });
  }

  // --- Applying --------------------------------------------------------

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
      _fail(tr.transfer.receive.cannotSave(error: '$e'));
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

  // --- Build -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return TransferScaffold(
      title: tr.transfer.receive.title,
      children: switch (_phase) {
        _Phase.starting => [TransferBusy(tr.transfer.gettingReady)],
        _Phase.waiting => [_waiting(context)],
        _Phase.scan => _scan(context),
        _Phase.type => _type(context),
        _Phase.joining => [TransferBusy(tr.transfer.receive.asking)],
        _Phase.awaitingPush => [
          TransferBusy(tr.transfer.receive.awaitingPush),
        ],
        _Phase.review => _review(context),
        _Phase.applying => [TransferBusy(tr.transfer.receive.saving)],
        _Phase.done => _done(context),
        _Phase.failed => _failed(context),
      },
    );
  }

  Widget _waiting(BuildContext context) {
    final pairing = _pairing!;
    return PairingDisplay(
      pairing: pairing,
      instructions: tr.transfer.receive.waitingInstructions,
      waitingLabel: tr.transfer.waitingOther,
      actions: [
        RelayTextButton(
          label: tr.common.cancel,
          autofocus: true,
          onPressed: () => context.pop(),
        ),
        if (RelayLayout.of(context) != RelayFormFactor.tv)
          RelayTextButton(
            label: tr.transfer.copyCode,
            onPressed: () => Clipboard.setData(
              ClipboardData(text: '${pairing.address} ${pairing.displayCode}'),
            ),
          ),
        // For when the other device has no camera and is showing the code.
        if (_canScan)
          RelayTextButton(
            label: tr.transfer.scanInstead,
            onPressed: () => unawaited(_choose(_Phase.scan)),
          ),
        RelayTextButton(
          label: tr.transfer.typeInstead,
          onPressed: () => unawaited(_choose(_Phase.type)),
        ),
      ],
    );
  }

  List<Widget> _scan(BuildContext context) => [
    TransferText(tr.transfer.receive.scanInstructions),
    const SizedBox(height: 16),
    PairingScanner(onPairing: (p) => unawaited(_join(p))),
    const SizedBox(height: 8),
    Wrap(
      spacing: 8,
      children: [
        RelayTextButton(
          label: tr.transfer.receive.showMine,
          onPressed: () => unawaited(_showMine()),
        ),
        RelayTextButton(
          label: tr.transfer.typeInstead,
          onPressed: () => unawaited(_choose(_Phase.type)),
        ),
        RelayTextButton(label: tr.common.cancel, onPressed: () => context.pop()),
      ],
    ),
  ];

  List<Widget> _type(BuildContext context) => [
    TransferText(tr.transfer.receive.typeInstructions),
    const SizedBox(height: 16),
    PairingEntry(
      submitLabel: tr.transfer.receive.connect,
      onSubmit: (p) => unawaited(_join(p)),
    ),
    const SizedBox(height: 8),
    Wrap(
      spacing: 8,
      children: [
        RelayTextButton(
          label: tr.transfer.receive.showMine,
          onPressed: () => unawaited(_showMine()),
        ),
        if (_canScan)
          RelayTextButton(
            label: tr.transfer.scanInstead,
            onPressed: () => unawaited(_choose(_Phase.scan)),
          ),
        RelayTextButton(label: tr.common.cancel, onPressed: () => context.pop()),
      ],
    ),
  ];

  List<Widget> _review(BuildContext context) {
    final bundle = _incoming!.bundle;
    final items = TransferItem.values.where(bundle.items.contains).toList();
    return [
      TransferText(tr.transfer.receive.review),
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
            label: tr.transfer.receive.saveThese,
            onPressed: _selected.isEmpty ? null : _apply,
          ),
          RelayTextButton(
            label: tr.transfer.receive.decline,
            onPressed: _decline,
          ),
        ],
      ),
    ];
  }

  List<Widget> _done(BuildContext context) => [
    TransferText(tr.transfer.receive.saved, dim: false, bold: true),
    for (final note in _notes) ...[
      const SizedBox(height: 12),
      TransferText(note),
    ],
    const SizedBox(height: 20),
    Align(
      alignment: Alignment.centerLeft,
      child: RelayButton(
        label: tr.transfer.done,
        autofocus: true,
        onPressed: () => context.pop(),
      ),
    ),
  ];

  List<Widget> _failed(BuildContext context) => [
    TransferError(_error ?? tr.transfer.wentWrongPlain),
    const SizedBox(height: 18),
    Wrap(
      spacing: 12,
      children: [
        RelayButton(
          label: tr.common.tryAgain,
          autofocus: true,
          onPressed: _again,
        ),
        RelayTextButton(
          label: tr.transfer.close,
          onPressed: () => context.pop(),
        ),
      ],
    ),
  ];
}
