# LittleBricks Credits and Attribution Notices

Copyright (c) 2026 LittleBricks Contributors.

---

## 1. Game Code & Core Systems

- **Lead Architecture & Implementation**: LittleBricks Engineering & Specialist Team
- **Engine**: Godot Engine 4.7.2 (MIT License)  
  *Copyright (c) 2007-present Juan Linietsky, Ariel Manzur, and Godot Engine contributors.*  
  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

---

## 2. 3D Catalog & Part Geometry

- **Generic original pieces and connector metadata**: LittleBricks Contributors, CC0-1.0.
- **Room props and common bricks**: [Kenney](https://kenney.nl/), CC0-1.0.
- **Specialty construction, display pieces, and select figure accessories**: [LDraw.org contributors](https://library.ldraw.org/). See [asset attributions](ATTRIBUTION.md) for per-pack authors, part numbers, licences and conversion notes.

---

### Opening screen typography

- **DM Sans** and **DM Serif Text** ship under the SIL Open Font License 1.1. The upstream license files and copyright notices are bundled in `game/assets/ui/fonts/`.
- [DM Sans source](https://github.com/google/fonts/tree/main/ofl/dmsans) and [DM Serif Text source](https://github.com/google/fonts/tree/main/ofl/dmseriftext)

## 3. Soundtrack & Foley

The soundtrack uses recordings released under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/). LittleBricks adjusts cue gain and endpoints and encodes them as stereo Ogg Vorbis. Track sources, SHA-256 checksums and conversion settings are in the [soundtrack ledger](game/assets/audio/soundtrack/sources.json).

| Where it plays | Track | Composer |
| --- | --- | --- |
| Main menu | [Quiet Village 1](https://freemusicarchive.org/music/holiznacc0/gamer-soundtrack-quiet-towns/quiet-village-1/) | HoliznaCC0 |
| Daytime | [Town Theme RPG](https://opengameart.org/content/town-theme-rpg) | The Cynic Project ([cynicmusic](https://cynicmusic.com/)) |
| Daytime | [Quiet Village 4](https://freemusicarchive.org/music/holiznacc0/gamer-soundtrack-quiet-towns/quiet-village-4/) | HoliznaCC0 |
| Daytime | [A New Town](https://opengameart.org/content/a-new-town-rpg-theme) | The Cynic Project ([cynicmusic](https://cynicmusic.com/), from Pixelsphere) |
| Rain | [Quiet Village 3](https://freemusicarchive.org/music/holiznacc0/gamer-soundtrack-quiet-towns/quiet-village-3/) | HoliznaCC0 |
| Night | [Drifting Piano](https://freemusicarchive.org/music/holiznacc0/background-music/drifting-piano/) | HoliznaCC0 |

The original placement, pickup, rotation, reject, and completion sounds are CC0 1.0 and can be regenerated with `python tools/generate_audio_assets.py`.

---

## 4. Visual Identity & Characters

- **Branding**: Original *LittleBricks* logo and icon assets (`icon.svg`, `index.icon.png`, `index.apple-touch-icon.png`).
- **Workshop dog**: [Shiba Inu by Quaternius](https://poly.pizza/m/y4wdQpg767), CC0-1.0.
- **Explorer Figures**: LittleBricks-authored generic explorers and fan interpretations of Darth Vader, Stormtrooper, Iron Man, and Captain America. Selected helmets and Captain America’s shield use attributed LDraw CAD meshes. Character rights belong to their respective owners.

---

## 5. Third-Party Libraries & Tooling

- **FFmpeg**: Video encoding framework for desktop construction replay export. Licensed under LGPL v2.1+.
- **FreeType Project**: Font rendering engine used by Godot Engine. Licensed under the FreeType License (FTL).
- **MbedTLS**: Cryptographic and TLS communication engine used for secure WebSocket connections. Licensed under Apache 2.0.
