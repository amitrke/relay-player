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
    return RelayFocusable(
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
///
/// Public because a remote has to be able to reach *everything* that responds
/// to a tap. `GestureDetector` cannot: it has no focus node, so D-pad traversal
/// skips it entirely — which is why nothing in the library grid was selectable
/// on a TV. Prefer [RelayTappable] over using this directly; reach for this one
/// only when the focus treatment has to be drawn differently.
class RelayFocusable extends StatefulWidget {
  const RelayFocusable({
    super.key,
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
  State<RelayFocusable> createState() => _FocusableState();
}

class _FocusableState extends State<RelayFocusable> {
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

/// Anything tappable that is not already a button or a [RelaySurface].
///
/// The drop-in replacement for `GestureDetector`, and the reason to prefer it
/// is not style: a `GestureDetector` cannot hold focus, so a D-pad cannot reach
/// it and the thing is simply unusable with a remote. Draws the standard focus
/// ring so the viewer can see where they are from across a room.
class RelayTappable extends StatelessWidget {
  const RelayTappable({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = 12,
    this.autofocus = false,
    this.focusNode,
  });

  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return RelayFocusable(
      onTap: onTap,
      autofocus: autofocus,
      focusNode: focusNode,
      builder: (context, focused) => RelayFocusRing(
        focused: focused,
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(onTap: onTap, borderRadius: radius, child: child),
        ),
      ),
    );
  }
}

/// The one focus treatment, so focus looks the same everywhere it appears.
///
/// A solid accent ring rather than a tint: at two metres a subtle background
/// change is not legible, and Material's default focus overlay is exactly that.
class RelayFocusRing extends StatelessWidget {
  const RelayFocusRing({
    super.key,
    required this.focused,
    required this.child,
    this.borderRadius,
  });

  final bool focused;
  final Widget child;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final radius = borderRadius ?? BorderRadius.circular(12);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: focused ? t.accent : Colors.transparent,
          width: 3,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: t.accent.withValues(alpha: 0.45),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: child,
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
        minimumSize: Size(0, f == RelayFormFactor.tv ? 52 : 48),
        padding: EdgeInsets.symmetric(
            horizontal: f == RelayFormFactor.tv ? 32 : 24),
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

/// The square app mark ("S", for Subnext) used in onboarding and the desktop title bar.
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
        'S',
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

/// Carries D-pad focus across a boundary that directional traversal cannot.
///
/// Wrap the two sides in `FocusScope`s of their own, pass their nodes here, and
/// wrap the pair in this widget.
///
/// **Why this is needed at all.** Focus traversal stops at the edge of the
/// enclosing `FocusScope`: `FocusScopeNode.directionalTraversalEdgeBehavior`
/// defaults to [TraversalEdgeBehavior.stop]. A `Navigator` gives every route a
/// scope, so anything drawn *outside* the Navigator — a navigation rail beside
/// it — is unreachable from inside, however many times the viewer presses
/// towards it. Nothing about the code reads as wrong, and the failure is
/// silent: the key falls through to the nearest scrollable, which scrolls, so
/// the remote appears to do nothing (§11).
///
/// Sits above both sides so it sees arrow keys travelling up from the focused
/// widget, before the app-level `Shortcuts` turns them into a
/// `DirectionalFocusIntent` that will stop at the boundary. It defers to the
/// ordinary move first and only acts once that reports it had nowhere to go, so
/// traversal *within* either side is untouched — and a widget that wants arrow
/// keys for itself, such as a text field moving its caret, has already consumed
/// the event lower down.
class RelayFocusBoundary extends StatelessWidget {
  const RelayFocusBoundary({
    super.key,
    required this.leading,
    required this.main,
    required this.child,
  });

  /// The side reached by pressing left — a rail, a sidebar, a folder tree.
  final FocusScopeNode leading;

  /// The side reached by pressing right back out of [leading].
  final FocusScopeNode main;

  final Widget child;

  /// Performs the ordinary in-scope move, reporting whether it went anywhere.
  ///
  /// Guarded on `context` because with nothing focused the primary focus is the
  /// root scope, whose context is null — [FocusNode.focusInDirection] would
  /// throw on it rather than answer false.
  static bool _moved(TraversalDirection direction) {
    final focused = FocusManager.instance.primaryFocus;
    if (focused?.context == null) return false;
    return focused!.focusInDirection(direction);
  }

  /// Focuses wherever the viewer last was inside [scope], or its first stop.
  ///
  /// Returning to the rail should land on the destination they left from rather
  /// than resetting them to the top every time.
  static void _enter(FocusScopeNode scope) {
    // Unwrapped, because a scope's remembered child is often another scope —
    // the content side of the shell is a Navigator, so it is scope, then route
    // scope, then the widget the viewer actually left. Focusing the scope
    // itself would take focus off-screen: the ring disappears and the next
    // press starts from nowhere.
    FocusNode? remembered = scope.focusedChild;
    while (remembered is FocusScopeNode) {
      remembered = remembered.focusedChild;
    }
    // `canRequestFocus` guards against a stale memory: the content scope is
    // shared by every branch of the home shell's IndexedStack, and a branch
    // that has since gone inactive is wrapped in `ExcludeFocus` so its focus
    // leak can't reach a hidden screen (§11). `requestFocus` on a node with
    // `canRequestFocus == false` is a silent no-op — without this check the
    // remote reads as dead rather than as landing on the branch on screen.
    if (remembered != null && remembered.canRequestFocus) {
      remembered.requestFocus();
      return;
    }

    // Nothing remembered, or it is no longer reachable — first stop on that
    // side. Scopes are skipped for the same reason as above.
    for (final stop in scope.traversalDescendants) {
      if (stop is! FocusScopeNode) {
        stop.requestFocus();
        return;
      }
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final inLeading = leading.hasFocus;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft && !inLeading) {
      if (_moved(TraversalDirection.left)) return KeyEventResult.handled;
      _enter(leading);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowRight && inLeading) {
      if (_moved(TraversalDirection.right)) return KeyEventResult.handled;
      _enter(main);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // Never focusable itself; it is here to watch keys go past.
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: child,
    );
  }
}
