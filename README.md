# Relay Player

A general-purpose media player that relays a stream from whatever source you
point it at — a Plex server, a NAS or local files, or an optional IPTV
provider — across Android phone/tablet, iOS, and Android TV/Fire TV.

**Status: Phase 0 (validation).** There is no shippable app yet. Debug builds
boot into a spike harness that exists to answer four architectural questions
with evidence; release builds show a placeholder.

## Documentation

- [docs/architecture.md](docs/architecture.md) — architecture, store-policy
  risk analysis, and the phased delivery plan
- [docs/PHASE0_FINDINGS.md](docs/PHASE0_FINDINGS.md) — the Phase 0 deliverable;
  fill it in as the probes run

## Running the Phase 0 spike

```sh
cp lib/features/_spike/spike_config.example.dart \
   lib/features/_spike/spike_config.dart
# fill in real hosts/credentials -- spike_config.dart is gitignored

flutter run -d windows            # fastest loop; answers the protocol questions
flutter run -d <android-device>   # required for SAF/MediaStore/decode questions
```

The harness has four tabs, each mapping to one open question:

| Tab | Question | Doc |
|---|---|---|
| Player | Does libmpv tolerate real IPTV streams? | §10 |
| Plex | Is `dart_plex` viable, especially transcode teardown? | §6 |
| SMB | Does `smb://` work natively, or is the bridge needed? | §7.2 |
| Parse | XMLTV cost, and does this M3U carry usable metadata? | §5 |

Record every result in `docs/PHASE0_FINDINGS.md`. Negative results are the
point of the phase.

## Credentials

Never commit real provider credentials. `spike_config.dart` is gitignored;
the tracked `.example` file is the template. This is a public repo.

## License

See [LICENSE](LICENSE).
