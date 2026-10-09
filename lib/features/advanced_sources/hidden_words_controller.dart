import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/xtream/hidden_words.dart';
import '../settings/settings_controller.dart';

const _kHiddenWords = 'iptv.hiddenWords';

/// The words and phrases the user never wants to see from a panel (see
/// [HiddenWords] for how they match).
///
/// One list for every panel, not one per line: it records a taste ("no
/// Germany"), and the same taste applies whichever panel the title comes from.
/// Not a secret and small, so it lives in the settings box.
final hiddenWordsProvider =
    NotifierProvider<HiddenWordsController, List<String>>(
      HiddenWordsController.new,
    );

class HiddenWordsController extends Notifier<List<String>> {
  @override
  List<String> build() {
    final raw = ref.read(appSettingsStoreProvider).getString(_kHiddenWords);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final e in decoded)
          if (e is String) e,
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Adds [raw], tidied. Returns the entry as stored, or null when it was empty
  /// or already there (ignoring case), so the caller knows nothing new was added.
  Future<String?> add(String raw) async {
    final entry = HiddenWords.tidy(raw);
    if (entry == null) return null;
    if (state.any((e) => e.toLowerCase() == entry.toLowerCase())) return null;
    await _write([...state, entry]);
    return entry;
  }

  Future<void> remove(String entry) => _write([
    for (final e in state)
      if (e != entry) e,
  ]);

  Future<void> _write(List<String> next) async {
    state = next;
    await ref
        .read(appSettingsStoreProvider)
        .setString(_kHiddenWords, jsonEncode(next));
  }
}
