# App icon

## What to edit

The three `.svg` files are the source of truth. Everything else in this folder
and every icon under `android/`, `ios/` and `windows/` is generated from them.

| File | Role |
| --- | --- |
| `relay_icon.svg` | The full icon: dark `#14121C` ground, arc, play mark. Used for iOS, Windows, the Play Store listing, and pre-adaptive Android launchers. |
| `relay_icon_foreground.svg` | Android adaptive foreground. No background — the arc and play mark only, on transparency. |
| `relay_icon_monochrome.svg` | Android 13+ themed icon. Same geometry, everything white; the system tints this one layer to match the wallpaper. |

## Why there are PNGs too

`flutter_launcher_icons` reads raster input only — it cannot rasterise SVG. The
`relay_icon*.png` files are 1024×1024 exports of the matching SVG and exist
purely to feed the generator. **After changing an SVG, re-export its PNG at
1024×1024 before regenerating**, or the tool will silently keep using the old
artwork.

`play_store_512.png` is the 512×512 store-listing icon, downscaled from
`relay_icon.png`. It is not read by the build.

## Regenerating

```
dart run flutter_launcher_icons
```

Configuration lives in the `flutter_launcher_icons:` section of `pubspec.yaml`.
Two settings there are deliberate and worth not "fixing":

- **`adaptive_icon_background: "#14121C"`** rather than an image. The play mark
  in the foreground is white, so it needs the dark ground behind it; the tool's
  default is white, which would erase it.
- **`adaptive_icon_foreground_inset: 0`**, against a default of 16%. The
  foreground is drawn at 0.80× the flat icon's arc radius, which puts its outer
  edge 334px from centre on a 1024px canvas — just inside the 341px that a
  circular launcher mask leaves visible. It is already sized for the safe zone,
  so insetting again would shrink the mark to roughly two thirds of the circle.

The generated sets are committed, so a clean clone builds with the right icons
without anyone needing this tool installed.
