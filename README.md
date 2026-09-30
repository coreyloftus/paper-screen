# PaperScreen

A macOS menu bar utility that lays a soft paper texture over every display, to cut glare and harsh contrast. Our own implementation; see `NOTES.md` for the research that shaped the feature list.

## Plan

**Stack:** native Swift + AppKit, built with SwiftPM (no Xcode needed, Command Line Tools are enough). Apple Silicon, macOS 13+. Windows comes later as a separate port.

**How it works**
- One borderless, transparent window per display, at `.screenSaver` level. `canJoinAllSpaces` and `fullScreenAuxiliary` put it above full-screen apps.
- The windows ignore mouse events, never become key or main, and the view returns nil from `hitTest`. The app is `LSUIElement` (no Dock icon). So the overlay cannot take clicks or keyboard input.
- Each window draws a paper-coloured veil (lifts blacks, dims whites) and a tiled grain texture on top. Window alpha is the intensity.
- Textures are generated in code from seeded, wrapping noise (256 px tiles, one texture pixel per screen pixel). No image assets.
- Global hotkey uses Carbon `RegisterEventHotKey`. It needs no Accessibility or Input Monitoring permission.
- Settings live in `UserDefaults`.

**MVP scope:** on/off (menu bar + `Ctrl+Opt+P`), intensity slider, warmth slider, four textures, multi-display, persisted settings.

**Later:** custom hotkey, per-app exclusion, sunrise/sunset schedule, launch at login, Windows.

## Run

```sh
./build.sh
open build/PaperScreen.app
```

A page icon appears in the menu bar. Click it for the controls. Quit from the same menu.

Launch arguments override saved settings for one run, for example:

```sh
open build/PaperScreen.app --args -enabled YES -intensity 0.3 -texture woven
```

Textures: `softGrain`, `woven`, `blotter`, `coldTooth`.
