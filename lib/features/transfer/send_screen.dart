import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/platform/device_kind.dart';
import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/transfer/pairing.dart';
import '../../data/transfer/transfer_bundle.dart';
import '../../data/transfer/transfer_client.dart';
import 'transfer_service.dart';
import 'transfer_widgets.dart';

/// Settings -> Move to another device -> Send (§17).
///
/// Pick what to move, then scan the code the other device is showing (or type
/// it). Nothing leaves this device until a pairing is in hand, and what is sent
/// is sealed with that pairing's secret.
class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({
    super.key,
    this.client = const TransferClient(),
    this.canScan,
  });

  /// Test seams. [canScan] defaults to "a phone or tablet with a camera".
  final TransferClient client;
  final bool? canScan;

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

enum _Phase { loading, choose, connect, sending, done, failed }

class _SendScreenState extends ConsumerState<SendScreen> {
  _Phase _phase = _Phase.loading;
  CollectedSettings? _collected;
  Set<TransferItem> _selected = {};
  String? _error;

  bool _typing = false;
  String? _scanHint;
  MobileScannerController? _scanner;
  final _address = TextEditingController();
  final _code = TextEditingController();

  /// The camera exists on a phone or tablet. A TV has none, and a desktop's
  /// webcam is not what anyone points at another screen, so both type.
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
    _scanner?.dispose();
    _address.dispose();
    _code.dispose();
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

  void _toConnect() {
    setState(() {
      _typing = !_canScan;
      _scanHint = null;
      _error = null;
      _phase = _Phase.connect;
    });
    if (!_typing) _scanner ??= _newScanner();
  }

  MobileScannerController _newScanner() => MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  void _onScan(BarcodeCapture capture) {
    if (_phase != _Phase.connect) return;
    for (final barcode in capture.barcodes) {
      final pairing = PairingInfo.tryParse(barcode.rawValue ?? '');
      if (pairing != null) {
        unawaited(_send(pairing));
        return;
      }
    }
    if (capture.barcodes.isNotEmpty) {
      setState(() => _scanHint = 'That is not a code from this app.');
    }
  }

  void _sendTyped() {
    final pairing = PairingInfo.tryParse('${_address.text} ${_code.text}');
    if (pairing == null) {
      setState(() {
        _scanHint =
            'Check the address (like 192.168.1.20:41234) and the 16-character '
            'code.';
      });
      return;
    }
    unawaited(_send(pairing));
  }

  Future<void> _send(PairingInfo pairing) async {
    if (_phase == _Phase.sending) return;
    setState(() => _phase = _Phase.sending);
    unawaited(_scanner?.stop());
    try {
      await widget.client.send(
        pairing,
        _collected!.bundle.only(_selected),
      );
      if (!mounted) return;
      setState(() => _phase = _Phase.done);
    } on TransferException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail('Something went wrong: $e');
    }
  }

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
        const TransferText('There is nothing set up on this device to send yet.')
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

  List<Widget> _connect(BuildContext context) {
    final t = RelayTheme.of(context);
    final hint = _scanHint;
    final scanning = !_typing && _scanner != null;

    return [
      TransferText(
        scanning
            ? 'On the other device, open Settings, Move to another device, '
                  'and choose Receive. Point the camera at the code it shows.'
            : 'On the other device, open Settings, Move to another device, and '
                  'choose Receive. Then enter what it shows.',
      ),
      const SizedBox(height: 16),
      if (scanning)
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 300,
            child: MobileScanner(
              controller: _scanner,
              onDetect: _onScan,
              errorBuilder: (context, error) => Container(
                color: t.surface,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(20),
                child: Text(
                  error.errorCode == MobileScannerErrorCode.permissionDenied
                      ? 'The camera is switched off for this app. Type the '
                            'code instead, or allow the camera in your '
                            'phone\'s settings.'
                      : 'The camera could not start. Type the code instead.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.inkDim, height: 1.5),
                ),
              ),
            ),
          ),
        )
      else ...[
        _field(context, 'Address', _address, '192.168.1.20:41234'),
        const SizedBox(height: 12),
        _field(context, 'Code', _code, 'ABCD-EFGH-JKMN-PQRS', caps: true),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: RelayButton(label: 'Send', onPressed: _sendTyped),
        ),
      ],
      if (hint != null) ...[
        const SizedBox(height: 12),
        TransferText(hint),
      ],
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          if (_canScan)
            RelayTextButton(
              label: scanning ? 'Type the code instead' : 'Scan instead',
              onPressed: () => setState(() {
                _typing = !_typing;
                _scanHint = null;
                // The scanner widget starts its controller when it is built,
                // so showing it needs no start() here (a second one races it).
                if (!_typing) {
                  _scanner ??= _newScanner();
                } else {
                  unawaited(_scanner?.stop());
                }
              }),
            ),
          RelayTextButton(
            label: 'Back',
            onPressed: () {
              unawaited(_scanner?.stop());
              setState(() => _phase = _Phase.choose);
            },
          ),
        ],
      ),
    ];
  }

  Widget _field(
    BuildContext context,
    String label,
    TextEditingController controller,
    String hint, {
    bool caps = false,
  }) {
    final t = RelayTheme.of(context);
    return TextField(
      controller: controller,
      autocorrect: false,
      enableSuggestions: false,
      textCapitalization: caps
          ? TextCapitalization.characters
          : TextCapitalization.none,
      keyboardType: caps ? TextInputType.visiblePassword : TextInputType.url,
      style: TextStyle(color: t.ink),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: t.inkDim),
        hintStyle: TextStyle(color: t.inkDim.withValues(alpha: 0.6)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: t.line),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: t.accent, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
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
