import 'package:flutter/foundation.dart';

import '../../i18n/strings.g.dart';

/// Languages a native speaker has read through (architecture.md §12.3).
///
/// English is the base and was written, not translated. Every other file in
/// `lib/i18n/` is a **draft**: machine-made on 2026-10-15 to prove the
/// pipeline end to end, and not yet read by anyone who speaks the language.
/// A draft shows in debug builds, so it can be reviewed in place, and is
/// never shown in a release build, where the app stays in English. Add a
/// locale here in the same change that records who reviewed it.
const reviewedLocales = {AppLocale.en};

/// Follows the device's language, as every app on a TV is expected to. There
/// is no in-app language setting yet.
void applyDeviceLocale({bool release = kReleaseMode}) {
  final device = AppLocaleUtils.findDeviceLocale();
  LocaleSettings.setLocale(localeFor(device, release: release));
}

/// [device], or English when [device] is a draft and this is a release build.
AppLocale localeFor(AppLocale device, {required bool release}) =>
    !release || reviewedLocales.contains(device) ? device : AppLocale.en;
