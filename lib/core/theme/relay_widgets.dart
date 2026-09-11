import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'relay_theme.dart';
import 'relay_tokens.dart';

/// A raised card on [RelayTokens.surface] with a hairline border.
class RelaySurface extends StatelessWidget {
  const RelaySurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
  });

  final Widget child;
  final EdgeInsets padding;

  /// Overrides the hairline — used to mark a selected or focused row.
  final Color? borderColor;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? t.line),
      ),
      child: child,
    );

    if (onTap == null) return content;

    // A plain InkWell is not enough on TV: the row has to show a focus ring
    // from D-pad traversal, not just a touch ripple (§11).
    return _Focusable(
      onTap: onTap!,
      focusNode: focusNode,
      autofocus: autofocus,
      builder: (context, focused) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: focused
              ? [BoxShadow(color: t.accent.withValues(alpha: 0.5), blurRadius: 0, spreadRadius: 3)]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Wires a widget for both pointer and D-pad interaction, exposing focus state.
class _Focusable extends StatefulWidget {
  const _Focusable({
    required this.onTap,
    required this.builder,
    this.focusNode,
    this.autofocus = false,
  });

  final VoidCallback onTap;
  final Widget Function(BuildContext, bool focused) builder;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<_Focusable> createState() => _FocusableState();
}

class _FocusableState extends State<_Focusable> {
  FocusNode? _internal;
  bool _focused = false;

  FocusNode get _node => widget.focusNode ?? (_internal ??= FocusNode());

  @override
  void dispose() {
    _internal?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _node,
      autofocus: widget.autofocus,
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: (node, event) {
        // A TV remote's centre button arrives as `select` on Android TV and as
        // `gameButtonA` from some Fire TV remotes; keyboards send enter/space.
        final activate = {
          LogicalKeyboardKey.select,
          LogicalKeyboardKey.enter,
          LogicalKeyboardKey.numpadEnter,
          LogicalKeyboardKey.space,
          LogicalKeyboardKey.gameButtonA,
        };
        if (event is KeyDownEvent && activate.contains(event.logicalKey)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: widget.builder(context, _focused),
    );
  }
}

/// Primary action, filled with the accent.
class RelayButton extends StatelessWidget {
  const RelayButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    return FilledButton(
      autofocus: autofocus,
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: t.accent,
        foregroundColor: t.accentInk,
        minimumSize: Size(0, f == RelayFormFactor.tv ? 64 : 48),
        padding: EdgeInsets.symmetric(
            horizontal: f == RelayFormFactor.tv ? 40 : 24),
        textStyle: TextStyle(
          fontSize: RelayLayout.bodySize(f) + 1,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label),
    );
  }
}

/// Secondary action — text only, dim until focused.
class RelayTextButton extends StatelessWidget {
  const RelayTextButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: t.inkDim,
        minimumSize: Size(0, f == RelayFormFactor.tv ? 64 : 48),
        textStyle: TextStyle(fontSize: RelayLayout.bodySize(f)),
      ),
      child: Text(label),
    );
  }
}

/// The square app mark ("R") used in onboarding and the desktop title bar.
class RelayMark extends StatelessWidget {
  const RelayMark({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.accent,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Text(
        'R',
        style: TextStyle(
          color: t.accentInk,
          fontSize: size * 0.5,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

/// The standing legal note that appears on onboarding and in About.
///
/// §10 puts DRM explicitly out of scope, and the design canvas surfaces that
/// to the user rather than leaving it to be discovered. Keep the wording:
/// naming the services is what makes it actually informative.
class RelayDrmNotice extends StatelessWidget {
  const RelayDrmNotice({super.key});

  static const String text =
      'No DRM. Protected commercial catalogues such as Netflix or Disney+ '
      'cannot be played.';

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    return Text(
      text,
      textAlign: f == RelayFormFactor.tv ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        color: t.inkDim,
        fontSize: RelayLayout.bodySize(f) - 1,
        height: 1.5,
      ),
    );
  }
}
