# Strings

Every string the app shows lives here. See `docs/architecture.md` §12.3.

- `en.i18n.json` is the base, written in English, and the only reviewed
  language.
- `es`, `fr` and `de` are **drafts**, machine-made on 2026-10-15 and not yet
  read by a speaker. They show in debug builds and never in release builds
  (`reviewedLocales` in `lib/core/i18n/app_locale.dart`).
- `strings*.g.dart` is generated. After editing any `.i18n.json`, run:

  ```sh
  dart run slang
  ```

  `test/i18n_test.dart` fails if you forget, if a translation is missing a key
  or a `{placeholder}`, or if a widget gets a literal English string.

## Reviewing a draft

Read it in the running app (a debug build with the device set to that
language), and check the consent texts for meaning as well as fluency:
`ai.feature.*`, `ai.consent*`, `settings.metadata.consent`,
`settings.advanced.*`. When it is done, add the locale to `reviewedLocales`
and record who reviewed it, and when, in §12.3.

## Adding a language

Copy `en.i18n.json` to `<locale>.i18n.json`, translate the values, keep every
key and `{placeholder}`, and give plurals the forms the language needs
(`one`, `few`, `many`, `other`, ...; `other` is required). Run `dart run slang`
and the tests. It starts as a draft.
