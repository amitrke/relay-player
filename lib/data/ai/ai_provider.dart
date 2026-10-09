/// The kinds of provider the setup screen offers.
///
/// Every one of them speaks the OpenAI Chat Completions wire format, so one
/// client serves all of them (section 9.1: "a generic OpenAI-compatible endpoint
/// covers most self-hosted or third-party OpenAI-API-shaped services in one
/// config"). They differ only in where they live and what the setup form
/// pre-fills. Anthropic and Gemini speak their own formats and need their own
/// clients, which are not built yet.
enum AiPreset {
  openRouter(
    'OpenRouter',
    'https://openrouter.ai/api/v1',
    // Deliberately empty. OpenRouter's catalogue, and which models are free,
    // changes often, and a model id written down here would go stale and fail
    // with a confusing "not found".
    '',
    'Model ids are listed at openrouter.ai/models. Free ones end in ":free".',
  ),
  openAi('OpenAI', 'https://api.openai.com/v1', 'gpt-4o-mini', null),
  ollama(
    'Ollama',
    'http://localhost:11434/v1',
    'llama3.1',
    'Use your computer\'s address on this network, for example '
        'http://192.168.1.20:11434/v1. Nothing leaves your network.',
  ),
  custom('Other', '', '', 'Any service that speaks the OpenAI chat format.');

  const AiPreset(this.label, this.baseUrl, this.model, this.hint);

  final String label;
  final String baseUrl;
  final String model;

  /// Shown under the form for this preset, when there is something to say.
  final String? hint;

  static AiPreset? fromName(String? name) {
    for (final p in values) {
      if (p.name == name) return p;
    }
    return null;
  }
}

/// One configured provider. No secret in it: the key lives in secure storage
/// (section 3) and is joined back in when a client is built.
class AiProviderConfig {
  const AiProviderConfig({
    required this.preset,
    required this.baseUrl,
    required this.model,
  });

  final AiPreset preset;

  /// Without a trailing slash.
  final String baseUrl;
  final String model;

  String get host => Uri.tryParse(baseUrl)?.host ?? '';

  /// Whether requests stay on this device or this network.
  ///
  /// Decided from the address, not from the preset: "Other" pointed at a LAN
  /// machine is just as local, and "Ollama" pointed at a public host is not.
  /// Section 9.3 exempts local providers from the consent flow because nothing
  /// reaches a third party, so getting this wrong in the permissive direction
  /// would skip a disclosure Apple requires.
  bool get isLocal => isPrivateHost(host);

  /// Request fields only this provider understands.
  ///
  /// OpenRouter takes `reasoning: {enabled: false}`, which stops a reasoning
  /// model burning the reply budget on thinking. It is a request, not a
  /// guarantee: a model that cannot run without reasoning ignores it. Keyed on
  /// the host, not the preset, so "Other" pointed at openrouter.ai gets it too,
  /// and nothing else does, since OpenAI's API rejects fields it does not know.
  Map<String, Object?> get requestExtras => host.endsWith('openrouter.ai')
      ? const {
          'reasoning': {'enabled': false},
        }
      : const {};

  /// What the consent dialog and the settings list call this provider. The
  /// real name where there is one (section 9.3 forbids "AI service"), the host
  /// for anything custom.
  String get displayName => preset == AiPreset.custom ? host : preset.label;

  Map<String, String> toJson() => {
    'preset': preset.name,
    'baseUrl': baseUrl,
    'model': model,
  };

  static AiProviderConfig? fromJson(Map<String, String> json) {
    final preset = AiPreset.fromName(json['preset']);
    final baseUrl = json['baseUrl'];
    final model = json['model'];
    if (preset == null || baseUrl == null || model == null) return null;
    return AiProviderConfig(preset: preset, baseUrl: baseUrl, model: model);
  }

  /// [baseUrl] tidied: trimmed, no trailing slash.
  static String normaliseBaseUrl(String raw) =>
      raw.trim().replaceAll(RegExp(r'/+$'), '');
}

/// Loopback, link-local, private-range and `.local` hosts.
bool isPrivateHost(String host) {
  final h = host.toLowerCase();
  if (h.isEmpty) return false;
  if (h == 'localhost' || h.endsWith('.local') || h == '::1') return true;

  final parts = h.split('.');
  if (parts.length != 4) return false;
  final octets = [for (final p in parts) int.tryParse(p)];
  if (octets.any((o) => o == null || o < 0 || o > 255)) return false;
  final [a, b, ...] = octets.cast<int>();
  return a == 10 ||
      a == 127 ||
      (a == 192 && b == 168) ||
      (a == 172 && b >= 16 && b <= 31) ||
      (a == 169 && b == 254);
}

/// What a feature needs a model for, and what it sends.
///
/// The wording is the consent dialog's, so it names the data category exactly
/// (section 9.3). Only features that exist are listed: a consent row for
/// something the app cannot do would advertise it.
enum AiFeature {
  naturalSearch(
    'Natural-language search',
    'Your search text, and the titles and years in your library.',
  ),
  recommendations(
    'Recommendations',
    'The films you watched recently, and the titles and years of what you '
        'have not watched yet in your library.',
    timing:
        'Picks are prepared in the background shortly after the app opens, '
        'but only when what you watched has changed or they are over a day '
        'old, so it is not a request on every launch.',
  );

  const AiFeature(this.label, this.dataSent, {this.timing});

  final String label;
  final String dataSent;

  /// When sending happens, if that is not simply "when you ask". Shown in the
  /// consent dialog, because background sending is part of what is agreed to.
  final String? timing;
}
