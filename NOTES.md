# Research notes: Paperman (paperman.cc)

Researched 2026-09-30 from paperman.cc, paperman.cc/pricing, and third-party listings (Setapp, Digital Trends, macapp.supply). One listing page (onmymenubar.app) returned 403, so menu bar and hotkey details are thin.

## What it is
A screen utility that lays a matte, paper-like texture over the display. It reduces glare and harsh contrast. It does not shift color temperature like night-mode filters. Built with Rust; under 25 MB at rest, near-zero idle CPU.

## Features
| Area | What Paperman does |
|---|---|
| Textures | 7 shipping, 2 more "coming soon". Names include Classic Matte, Whisper Weave (fabric), Sunbaked Parchment (heavy grain, amber), Saddle Linen (coarse weave, warm), Painter's Press (cold-press tooth), Mulberry Veil (plum undertone), Vellum Mist (translucent haze). |
| Intensity | "Precision opacity", 15% to 30%. |
| Tint / warmth | Baked into some textures (amber, plum, earthy). Separate "Desk Lamp" mode: ambient light presets such as Soft Candlelight, Midnight Oil, Nook Lantern, Gallery Spot, Golden Hour, Quiet Aurora. |
| Grain | Part of each texture; no separate grain control found. |
| Per-app | App exclusion list: texture hides for chosen apps. |
| Per-display | Multi-monitor: applies to all displays with one control. |
| Scheduling | Circadian schedule: automatic on/off by sunrise and sunset. Windows also has automatic theme switching. |
| Hotkey | Third-party listings say hotkeys are configurable. No default key found. |
| Menu bar | Runs as a background menu bar app on macOS. Layout not confirmed. |
| Platforms | macOS and Windows. |

## Pricing
- **Lite (free):** Windows only. 1 hour of effect per day. Classic Matte only.
- **Unlimited:** $9.95 one-time (list $11.99). All textures. 2 device activations on direct download.
- **Mac:** Mac App Store (one-time, Apple ID, Family Sharing), direct download (one-time, 2 devices), or Setapp (7-day trial).
- 14-day money-back guarantee. Volume licensing for schools and teams.

## What we build (our own, no Paperman assets or names)
MVP covers: on/off toggle, global hotkey, intensity slider, 2+ procedural textures, warmth tint, multi-display, persisted settings, click-through overlay. Later: per-app exclusion (needs frontmost-app tracking, no special permission), sunrise/sunset schedule (needs location), Windows port.
