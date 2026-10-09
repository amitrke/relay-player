import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/ai/ai_provider.dart';
import '../ai/ai_controller.dart';
import '../ai/ai_recommendations_controller.dart';
import 'suggestions_view.dart';

/// "What should I watch?": the AI recommendations section of the empty Search
/// screen. Shown only when a provider is set up.
///
/// Before the user has allowed it, a button that asks (the consent dialog
/// appears on that first press). After, the picks are already here: they were
/// prepared in the background and kept, so there is nothing to wait for, and a
/// quiet "Updating" shows while a newer set is on its way.
class AiRecommendationsSection extends ConsumerStatefulWidget {
  const AiRecommendationsSection({super.key});

  @override
  ConsumerState<AiRecommendationsSection> createState() => _SectionState();
}

class _SectionState extends ConsumerState<AiRecommendationsSection> {
  @override
  void initState() {
    super.initState();
    // Opening Search is the moment to notice that what was watched has changed
    // since the picks were made. Sends nothing when it has not.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(aiRecommendationsProvider.notifier).refreshIfStale();
      }
    });
  }

  Future<void> _enable() async {
    // Allowing it is what starts the preparation: the controller watches the
    // consent record and rebuilds the moment it is granted.
    await ensureAiConsent(context, ref, AiFeature.recommendations);
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final state = ref.watch(aiRecommendationsProvider).value;
    final provider =
        ref.watch(aiSetupProvider).value?.config.displayName ?? 'your provider';

    // Still working out whether it is allowed, which takes a moment on launch.
    if (state == null) return const SizedBox.shrink();

    if (!state.enabled) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 6),
        child: Row(
          children: [
            _Chip(
              icon: Icons.auto_awesome,
              label: 'What should I watch?',
              onTap: _enable,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Ask $provider to pick from your own library.',
                style: TextStyle(color: t.inkDim, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: RowHeading(
                lead: 'Picked for you by ',
                title: provider,
                color: t.ink,
                dim: t.inkDim,
              ),
            ),
            if (state.refreshing)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: t.accent,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Updating',
                    style: TextStyle(color: t.inkDim, fontSize: 12.5),
                  ),
                ],
              )
            else
              _Chip(
                icon: Icons.refresh,
                label: 'Again',
                onTap: () =>
                    ref.read(aiRecommendationsProvider.notifier).refresh(),
              ),
          ],
        ),
        if (state.items.isNotEmpty)
          PosterRow(items: state.items)
        else if (state.refreshing)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Getting your picks ready...',
              style: TextStyle(color: t.inkDim),
            ),
          ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              state.error!,
              style: TextStyle(color: t.inkDim, fontSize: 12.5, height: 1.5),
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final f = RelayLayout.of(context);
    final size = f == RelayFormFactor.tv ? 15.0 : 13.0;
    return RelayTappable(
      borderRadius: 20,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: t.accent.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.accent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: size + 3, color: t.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: t.ink,
                fontSize: size,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
