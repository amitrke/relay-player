import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/relay_theme.dart';
import '../../core/theme/relay_widgets.dart';
import '../../data/ai/ai_provider.dart';
import '../../data/ai/text_client.dart';
import '../ai/ai_controller.dart';

/// Settings -> AI features: connect your own provider, and say what each
/// feature may send it.
///
/// Replaces the pane that was demo data until 2026-10-09. Everything here reads
/// and writes real state: the provider is tried before it is saved, the key goes
/// to secure storage, and a consent row is the thing `ensureAiConsent` checks.
class AiPane extends ConsumerStatefulWidget {
  const AiPane({super.key});

  @override
  ConsumerState<AiPane> createState() => _AiPaneState();
}

class _AiPaneState extends ConsumerState<AiPane> {
  AiPreset _preset = AiPreset.openRouter;
  final _baseUrl = TextEditingController(text: AiPreset.openRouter.baseUrl);
  final _model = TextEditingController(text: AiPreset.openRouter.model);
  final _key = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _baseUrl.dispose();
    _model.dispose();
    _key.dispose();
    super.dispose();
  }

  void _choose(AiPreset preset) => setState(() {
    _preset = preset;
    _baseUrl.text = preset.baseUrl;
    _model.text = preset.model;
    _error = null;
  });

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(aiSetupProvider.notifier)
          .save(
            AiProviderConfig(
              preset: _preset,
              baseUrl: AiProviderConfig.normaliseBaseUrl(_baseUrl.text),
              model: _model.text.trim(),
            ),
            _key.text,
          );
      if (!mounted) return;
      _key.clear();
      setState(() => _busy = false);
    } on AiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final setup = ref.watch(aiSetupProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect your own provider and your own key. Requests go straight '
          'from this device to the provider you chose, never through us, '
          'because there is no server of ours in between. Nothing is sent '
          'until you allow a feature below.',
          style: TextStyle(color: t.inkDim, fontSize: 13.5, height: 1.6),
        ),
        const SizedBox(height: 18),
        if (setup != null) ..._connected(context, setup) else ..._form(context),
      ],
    );
  }

  List<Widget> _form(BuildContext context) {
    final t = RelayTheme.of(context);
    final local = isPrivateHost(Uri.tryParse(_baseUrl.text)?.host ?? '');

    return [
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final p in AiPreset.values)
            _Pill(label: p.label, on: p == _preset, onTap: () => _choose(p)),
        ],
      ),
      if (_preset.hint != null) ...[
        const SizedBox(height: 10),
        Text(
          _preset.hint!,
          style: TextStyle(color: t.inkDim, fontSize: 12.5, height: 1.5),
        ),
      ],
      const SizedBox(height: 16),
      _field('Address', _baseUrl, onChanged: (_) => setState(() {})),
      const SizedBox(height: 12),
      _field('Model', _model),
      const SizedBox(height: 12),
      _field(
        local ? 'API key (optional for a local server)' : 'API key',
        _key,
        obscure: true,
        onSubmitted: (_) => _save(),
      ),
      if (_error != null) ...[
        const SizedBox(height: 10),
        Text(
          _error!,
          style: TextStyle(color: t.accent, fontSize: 13, height: 1.5),
        ),
      ],
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerLeft,
        child: RelayButton(
          label: _busy ? 'Trying it...' : 'Test and save',
          onPressed: _busy ? null : _save,
        ),
      ),
    ];
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    final t = RelayTheme.of(context);
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c),
    );
    return RelayFieldTraversal(
      child: TextField(
        controller: controller,
        obscureText: obscure,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: onSubmitted == null
            ? TextInputAction.next
            : TextInputAction.done,
        style: TextStyle(color: t.ink),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: t.inkDim),
          filled: true,
          fillColor: t.surface,
          border: border(t.line),
          enabledBorder: border(t.line),
          focusedBorder: border(t.accent),
        ),
      ),
    );
  }

  List<Widget> _connected(BuildContext context, AiSetup setup) {
    final t = RelayTheme.of(context);
    final config = setup.config;
    // Rebuilds when a consent changes.
    ref.watch(aiConsentProvider);
    final consent = ref.read(aiConsentProvider.notifier);

    return [
      RelaySurface(
        borderColor: config.isLocal ? null : t.accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  config.displayName,
                  style: TextStyle(
                    color: t.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  config.isLocal ? 'On your network' : 'Key saved',
                  style: TextStyle(
                    color: config.isLocal ? t.inkDim : t.accent,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              config.model,
              style: TextStyle(
                color: t.inkDim,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Align(
        alignment: Alignment.centerLeft,
        child: RelayButton(
          label: 'Remove provider',
          onPressed: () => ref.read(aiSetupProvider.notifier).remove(),
        ),
      ),
      const SizedBox(height: 26),
      Text(
        'What it may send',
        style: TextStyle(
          color: t.ink,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 10),
      if (config.isLocal)
        Text(
          'This provider is on your own network, so nothing reaches a third '
          'party and no consent is needed.',
          style: TextStyle(color: t.inkDim, fontSize: 13, height: 1.55),
        )
      else
        for (final feature in AiFeature.values) ...[
          _ConsentRow(
            feature: feature,
            providerName: config.displayName,
            grantedAt: consent.grantedAt(feature, config),
            onChanged: (allow) => allow
                ? consent.grant(feature, config)
                : consent.revoke(feature, config),
          ),
          const SizedBox(height: 10),
        ],
    ];
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    return RelayTappable(
      borderRadius: 20,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: on ? t.accent : t.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? t.accent : t.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: on ? t.accentInk : t.inkDim,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.feature,
    required this.providerName,
    required this.grantedAt,
    required this.onChanged,
  });

  final AiFeature feature;
  final String providerName;
  final DateTime? grantedAt;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = RelayTheme.of(context);
    final allowed = grantedAt != null;
    return RelaySurface(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.label,
                  style: TextStyle(
                    color: t.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sends to $providerName: ${feature.dataSent}'
                  '${feature.timing == null ? '' : ' ${feature.timing}'}',
                  style: TextStyle(
                    color: t.inkDim,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  allowed
                      ? 'Allowed on ${grantedAt!.toLocal().toString().substring(0, 10)}'
                      : 'Not allowed yet. You will be asked the first time.',
                  style: TextStyle(
                    color: allowed ? t.accent : t.inkDim,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Pill(
            label: allowed ? 'Switch off' : 'Allow',
            on: false,
            onTap: () => onChanged(!allowed),
          ),
        ],
      ),
    );
  }
}
