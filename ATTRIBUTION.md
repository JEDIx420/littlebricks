# Third-Party Licenses & Asset Attributions

LittleBricks is an open-source cooperative building experience licensed under the **MIT License**.
This document outlines the licenses and attributions for third-party technologies and assets incorporated into the project.

---

## 1. Game Engine

### Godot Engine
- **License**: MIT License
- **Copyright**: (c) 2014-present Godot Engine contributors; (c) 2007-2014 Juan Linietsky, Ariel Manzur.
- **Website**: https://godotengine.org

```
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 2. 3D Parts & Catalog Assets

Original LittleBricks parts and explorer body geometry are documented in the [asset provenance ledger](game/assets/provenance.json). Imported assets retain their source licenses.

### LDraw construction and display pieces

| Pack | Part numbers | Primary LDraw authors |
| --- | --- | --- |
| Galactic Hangar | 2507, 43722a, 43723a, 3943b, 3960 | James Jessiman, Donald Sutter |
| Heroes HQ | 75902, 30162, 4740 | Howard Lande, Paul Easter, James Jessiman |
| Castle Keep | 6066, 30136, 30044, 30055, 3846, 3847, 4499 | James Jessiman, Steve Bliss, John Van Zwieten |

The pack meshes use [LDraw.org](https://library.ldraw.org/) files under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). LittleBricks flattened the source dependency trees to triangulated OBJ meshes and normalized axes, pivots, and stud scale. LittleBricks adds mounts and connection metadata. The [asset ledger](game/assets/provenance.json) records each model's exact source, authors, licences, and hashes, including the contributing primitive and subpart files. Rebuild with `python tools/import_ldraw_packs.py --cache /path/to/ldraw-cache`.

Kenney's [Brick Kit](https://kenney.nl/assets/brick-kit) and [Furniture Kit](https://kenney.nl/assets/furniture-kit) retain CC0-1.0 terms.

### LDraw figure accessories

| Accessory | LDraw part | Principal author |
| --- | --- | --- |
| Darth Vader helmet | 30368 | Paul Easter |
| Stormtrooper patterned helmet | 30408p01 | Alex Taylor |
| Iron Man helmet and gold visor | 10907c01 | Magnus Forsberg |
| Captain America patterned shield | 75902p02 | Philippe Hurbain |

These accessories use [LDraw Parts Library](https://library.ldraw.org/) data distributed under [CC BY 4.0](game/assets/sourced/ldraw_figures/CC-BY-4.0.txt), with original file contributors, additional credits, licenses, pinned source, and checksums listed in [the accessory source ledger](game/assets/sourced/ldraw_figures/sources.json). LittleBricks converted the CAD surfaces to glTF, retained source patterns and colors, and adapted normals, black plastic shading, coordinates, and scale for the game.

The LDraw data licenses cover the contributed CAD files. Franchise names and character designs remain associated with their respective rights holders. LittleBricks is an independent project and is not endorsed by the LEGO Group, Lucasfilm, or Marvel.
