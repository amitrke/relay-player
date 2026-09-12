import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Whether the app is running on a television.
///
/// This has to come from the platform. Flutter cannot tell: a 1080p TV reports
/// **960 × 540 dp** (1920 px at 320 dpi) and 4K panels raise density to land in
/// the same place, so by size alone a TV is indistinguishable from a tablet.
/// `MediaQuery.navigationMode` is not an answer either — it defaults to
/// `traditional` and only changes if the app sets it, so a check against it can
/// never fire. Both of those were the reason `RelayFormFactor.tv` was
/// unreachable and every 10-foot size in `RelayLayout` was dead code on real TV
/// hardware (architecture.md §11).
///
/// Resolved once before the first frame and then read synchronously, because
/// layout decisions happen in `build` and an async answer would render the
/// phone layout first and visibly correct itself.
class DeviceKind {
  const DeviceKind._();

  static const MethodChannel _channel = MethodChannel('relay_player/platform');

  static bool _isTelevision = false;

  /// True on Android TV, Google TV and Fire TV. Always false elsewhere.
  static bool get isTelevision => _isTelevision;

  /// Asks the platform once. Safe to call on any platform.
  static Future<void> detect() async {
    if (!Platform.isAndroid) return;
    try {
      _isTelevision =
          await _channel.invokeMethod<bool>('isTelevision') ?? false;
    } catch (e) {
      // A missing handler is not worth failing startup over — it only means
      // the app renders as a tablet, which is what it did before this existed.
      debugPrint('DeviceKind: could not determine device type ($e)');
      _isTelevision = false;
    }
  }

  /// Test seam: forces the answer without a platform round trip.
  @visibleForTesting
  static void debugSetTelevision(bool value) => _isTelevision = value;
}
