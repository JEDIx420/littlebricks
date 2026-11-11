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

All 126 buildable part shapes and connector definitions across Bricks, Plates, Tiles, Slopes, Openings/Arches, Structures, Thematic Decorations, and Explorers in `game/assets/catalog/parts_manifest.json` are authored parametrically:
- **Licence**: Creative Commons Zero v1.0 Universal (CC0-1.0) Public Domain Dedication.
- **Provenance**: Original procedural coordinate mathematics adhering to open orthogonal stud pitch standards (8.0mm stud pitch, 9.6mm brick height, 3.2mm plate height).
- **Compatibility**: Designed with original generic geometry and clearances, free from proprietary trademarks, minifigure silhouettes, or branded logos.

---

### Opening screen typography

- **DM Sans** and **DM Serif Text** ship under the SIL Open Font License 1.1. The upstream license files and copyright notices are bundled in `game/assets/ui/fonts/`.
- [DM Sans source](https://github.com/google/fonts/tree/main/ofl/dmsans) and [DM Serif Text source](https://github.com/google/fonts/tree/main/ofl/dmseriftext)

## 3. Original Audio, Music & Foley

All audio assets located in `game/assets/audio/` were synthesized and mastered specifically for LittleBricks:
- **Licence**: Creative Commons Zero v1.0 Universal (CC0-1.0) Public Domain Dedication.
- **Music Compositions**:
  - `music_menu.ogg` — *Open the Brick Box*, an original 51-second felt-key and plucked-string theme.
  - `music_building.ogg` — *Afternoon at the Table*, an original 82-second stereo loop with a lighter melodic part.
  - Both tracks are rendered from the original LittleBricks score by `tools/generate_audio_assets.py` and are available under these CC0 terms, including use in game-generated films.
- **Sound Effects (SFX)**:
  - `click_place.wav`: Crisp tactile ABS mechanical connection click.
  - `pickup.wav`: Subtle acoustic part lift transient.
  - `rotate.wav`: Soft directional rotation snap.
  - `reject.wav`: Gentle low-frequency non-punitive invalid notification.
  - `chime.wav`: Harmonious accomplishment chime for finish agreement and exploration reveals.
- **Redistribution Rights**: Fully authorized for inclusion in game releases, web builds, and exported user video films (`.mp4`) across all platforms without royalty obligations.

---

## 4. Visual Identity & Characters

- **Branding**: Original *LittleBricks* logo and icon assets (`icon.svg`, `index.icon.png`, `index.apple-touch-icon.png`).
- **Explorer Figures**: Original generic toy explorer miniature (`explorer_candidate_01`, `explorer_figure_01..04`) designed as modular geometric toy figures, avoiding any third-party character copyright or trademark conflicts.

---

## 5. Third-Party Libraries & Tooling

- **FFmpeg**: Video encoding framework for desktop construction replay export. Licensed under LGPL v2.1+.
- **FreeType Project**: Font rendering engine used by Godot Engine. Licensed under the FreeType License (FTL).
- **MbedTLS**: Cryptographic and TLS communication engine used for secure WebSocket connections. Licensed under Apache 2.0.
