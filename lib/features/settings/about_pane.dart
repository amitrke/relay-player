import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../onboarding/onboarding_screen.dart';

/// Settings → About (§12.1): version, the general disclaimer (§1), the privacy
/// policy, and open-source licences.
///
/// The first §12.1 section that exists because a store needs it rather than
/// because a user asked for it. Play wants a privacy policy reachable from
/// inside the app as well as from the listing, and a reviewer reading the
/// disclaimer here should find the same sentence onboarding showed — so it is
/// [OnboardingScreen.blurb], not a second copy that can drift.
class AboutPane extends StatelessWidget {
  const AboutPane({super.key});

  /// Served from `site/` by `.github/workflows/pages.yml` (docs/STORE_LISTING.md).
  static const String privacyPolicyUrl =
      'https://amitrke.github.io/relay-player/privacy.html';

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final body = TextStyle(color: t.inkDim, fontSize: 13, height: 1.6);
    final label = TextStyle(
        color: t.ink, fontSize: 14, fontWeight: FontWeight.w600);

    // A Column, not a ListView: both Settings layouts already scroll.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subnext Player', style: label),
        const SizedBox(height: 4),
        // Read at runtime rather than baked in: CI sets the version from the
        // tag (`--build-name`) and the build number from the run, so a
        // hardcoded string would be wrong on every build but the one it was
        // typed for. An untagged build reads "0.0.0 (n)", deliberately —
        // docs/RELEASING.md, "The fallback version is 0.0.0, on purpose".
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snap) {
            final info = snap.data;
            return Text(
              info == null
                  ? 'Version …'
                  : 'Version ${info.version} (${info.buildNumber})',
              style: body,
            );
          },
        ),
        const SizedBox(height: 18),
        Text(OnboardingScreen.blurb, style: body),
        const SizedBox(height: 18),
        Text('Privacy policy', style: label),
        const SizedBox(height: 4),
        Text(
          'No account, no backend and no analytics. The full policy is at:',
          style: body,
        ),
        const SizedBox(height: 4),
        // Shown as text, not a link. Many Google TV devices have no browser
        // to hand a URL to, and pulling in url_launcher for the phone case
        // alone would add a dependency to render a link some users cannot
        // follow. Selectable so it can be copied on a phone.
        SelectableText(privacyPolicyUrl,
            style: body.copyWith(color: t.accent)),
        const SizedBox(height: 22),
        // Flutter's own licence page, which collects the LICENSE of every
        // Dart package in the build. The native libmpv/FFmpeg binaries
        // media_kit bundles are not Dart packages, so on Android they are
        // added separately by registerNativeLicenses (core/native_licenses.dart).
        RelayButton(
          label: 'Open-source licences',
          onPressed: () async {
            final info = await PackageInfo.fromPlatform();
            if (!context.mounted) return;
            showLicensePage(
              context: context,
              applicationName: 'Subnext Player',
              applicationVersion: '${info.version} (${info.buildNumber})',
            );
          },
        ),
      ],
    );
  }
}
