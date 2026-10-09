import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/transfer/pairing.dart';
import 'transfer_widgets.dart';

/// The QR code, address and 16-character code that one device shows so the
/// other can find it, with whatever the screen wants beside them.
///
/// Used by both screens, since either end can be the one showing (§17.7): the
/// receiver by default, and the sender when it is the device without a camera.
class PairingDisplay extends StatelessWidget {
  const PairingDisplay({
    super.key,
    required this.pairing,
    required this.instructions,
    required this.waitingLabel,
    required this.actions,
  });

  final PairingInfo pairing;

  /// What to do on the other device, in a sentence or two.
  final String instructions;
  final String waitingLabel;

  /// Buttons under the code. The first should take focus.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);

    final steps = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TransferText(instructions),
        const SizedBox(height: 16),
        const TransferText('No camera? Choose Type the code there, and enter:'),
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
        TransferBusy(waitingLabel),
        const SizedBox(height: 6),
        Wrap(children: actions),
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
}

/// A camera view that reads one pairing code and reports it.
///
/// Owns its controller, so the camera is on exactly as long as this widget is:
/// leaving the step (or the screen) switches it off, which the screens used to
/// have to remember to do.
class PairingScanner extends StatefulWidget {
  const PairingScanner({super.key, required this.onPairing});

  final ValueChanged<PairingInfo> onPairing;

  @override
  State<PairingScanner> createState() => _PairingScannerState();
}

class _PairingScannerState extends State<PairingScanner> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;
  bool _foreign = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final pairing = PairingInfo.tryParse(barcode.rawValue ?? '');
      if (pairing != null) {
        _done = true;
        widget.onPairing(pairing);
        return;
      }
    }
    if (capture.barcodes.isNotEmpty && !_foreign) {
      setState(() => _foreign = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 300,
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => Container(
                color: t.surface,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(20),
                child: Text(
                  error.errorCode == MobileScannerErrorCode.permissionDenied
                      ? 'The camera is switched off for this app. Type the '
                            'code instead, or allow the camera in your '
                            "phone's settings."
                      : 'The camera could not start. Type the code instead.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.inkDim, height: 1.5),
                ),
              ),
            ),
          ),
        ),
        if (_foreign) ...[
          const SizedBox(height: 12),
          const TransferText('That is not a code from this app.'),
        ],
      ],
    );
  }
}

/// The address and code, typed, for a device with no camera or no patience.
///
/// Focus starts in Address with the keyboard up, and the keyboard's Next key
/// carries on to Code and its Done key submits, because that is the only way
/// through a form with a remote: while the keyboard is up the D-pad moves over
/// its keys and not between fields (§11). Without this taking focus on arrival
/// nothing holds it, since the button that did has just left, and a remote then
/// does nothing at all (seen on the Google TV emulator).
class PairingEntry extends StatefulWidget {
  const PairingEntry({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
  });

  final String submitLabel;
  final ValueChanged<PairingInfo> onSubmit;

  @override
  State<PairingEntry> createState() => _PairingEntryState();
}

class _PairingEntryState extends State<PairingEntry> {
  final _address = TextEditingController();
  final _code = TextEditingController();
  final _addressFocus = FocusNode();
  String? _hint;

  @override
  void initState() {
    super.initState();
    // After the frame, since the field is not in the tree until this builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _addressFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _address.dispose();
    _code.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final pairing = PairingInfo.tryParse('${_address.text} ${_code.text}');
    if (pairing == null) {
      setState(() {
        _hint =
            'Check the address (like 192.168.1.20:41234) and the 16-character '
            'code.';
      });
      return;
    }
    widget.onSubmit(pairing);
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    bool caps = false,
    bool last = false,
    FocusNode? focusNode,
  }) {
    final t = RelayTheme.of(context);
    // Wrapped as every text field in the app has to be (RelayFieldTraversal):
    // without it Up and Down are swallowed as caret moves inside a one-line
    // field, so a remote could not get from Address to Code or on to the button.
    return RelayFieldTraversal(
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: last ? TextInputAction.done : TextInputAction.next,
        onSubmitted: last ? (_) => _submit() : null,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          'Address',
          _address,
          '192.168.1.20:41234',
          focusNode: _addressFocus,
        ),
        const SizedBox(height: 12),
        _field('Code', _code, 'ABCD-EFGH-JKMN-PQRS', caps: true, last: true),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: RelayButton(label: widget.submitLabel, onPressed: _submit),
        ),
        if (_hint != null) ...[
          const SizedBox(height: 12),
          TransferText(_hint!),
        ],
      ],
    );
  }
}
