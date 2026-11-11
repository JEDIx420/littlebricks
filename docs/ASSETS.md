# Asset pipeline and provenance

LittleBricks uses an original identity and a curated interoperable catalogue. This bootstrap includes no third-party meshes, audio, fonts or characters. Implementation follows [ARCHITECTURE.md](ARCHITECTURE.md), [VALIDATION.md](VALIDATION.md), and [AGENTS.md](../AGENTS.md).

## Sources to evaluate

| Source | Verified role / licence | Use in LittleBricks |
| --- | --- | --- |
| [Kenney Brick Kit](https://kenney.nl/assets/brick-kit) | Official CC0 pack; 290 listed files, including variants | Evaluate a small subset for prototype geometry, then add game metadata |
| [Kenney Blocky Characters](https://kenney.nl/assets/blocky-characters) | Official CC0 pack with animation support | Prototype explorer; normalize scale and inspect animations |
| [LDraw parts and contributor terms](https://www.ldraw.org/article/349.html) | Current contribution terms allow CC BY 4.0 or CC0; legacy BY 2.0 contributions are documented | Whitelist actual files and all referenced primitives/subparts; preserve applicable attribution |
| [LDCad Shadow Library](https://github.com/RolandMelkert/LDCadShadowLibrary) | CC BY-SA 4.0 snapping/mirroring metadata, separate from part meshes | Optional later connector-data input, with its own obligations |
| [LDraw Nova](https://github.com/anteloc/ldraw-nova) | AGPL-3.0 code; LDraw/GLB authoring and inspection toolkit | Optional developer authoring tool, outside per-turn gameplay |
| [Nova attribution](https://github.com/anteloc/ldraw-nova/blob/master/ATTRIBUTION.md) | Documentation/material terms include CC BY-SA 4.0 and preserve underlying model licences | Assess copied code, documentation, examples and outputs separately |

Source terms were researched on 2026-11-11. Recheck the exact downloaded release before adoption. A download button or the word "free" is not evidence of redistribution permission. CC0/CC licences do not settle third-party trademarks or every depicted design right.

## Required ingestion process

1. Select an official creator/project source; record the release or commit, source URL and checksum.
2. Inspect the licence and notices for each file and its transitive dependencies. Exclude unknown, incompatible or unreviewed content until resolved.
3. Preserve source author/attribution and record modifications. Conversion to GLB does not erase source obligations.
4. Normalize axes, pivot, units, material palette, dimensions and mesh orientation against the project's documented stud/plate scale.
5. Add allowed rotations, body collision proxies, compatible connector definitions, theme tags and simplified explorer collision.
6. Inspect the part in-engine and run representative placement fixtures. A plausible preview alone is insufficient.
7. Add the approved part to a versioned catalog and generate the distributed notices from the same provenance data.

M0/M1 must establish machine-readable provenance adjacent to `game/assets/`, and published credits/licence notices. Record at least asset ID/version, upstream author, URL, revision/checksum, licence identifier and text location, dependencies, conversion steps, changes, normalized scale and reviewer. Never include credentials or signing material in manifests.

Retain source geometry or reproducible conversion inputs where permitted. Keep large generated exports out of normal source history when they can be reproduced; document retrieval checksums and make release builds reproducible. Do not silently replace an asset used by existing saves.

## Catalogue and themes

Prove a small representative fixture first. The user's expanded-library requirement in [PLACEMENT_AND_CATALOG.md](PLACEMENT_AND_CATALOG.md) supersedes the original 40–60-shape target: audit current entries, then reach 80 and at least 120 verified buildable shapes, with 150 as a stretch goal. Shapes, characters and color/quality variants are separate counts. Prioritize bricks, plates, tiles, slopes, windows/door openings, arches, stairs, roofs, round/curved pieces and theme details. Hinges, flexible parts and arbitrary sideways construction remain outside the current mechanical scope unless their rules and metadata are deliberately implemented.

The current 43-entry manifest and six-item demo tray are different measures; neither proves 43 functional building shapes. Share one canonical anchor/connector transform between meshes, colliders, placement and saves. Rendering collision boxes is insufficient for every curved or sloped part. Prove PC-01–PC-09 before catalogue expansion and inspect every new family; load packs efficiently rather than keeping the full library resident.

Define themes through manifests using the same geometry rules, scale and palette system. Start with Harbour and Forest Cabin; a Space Outpost can follow. Weight structural pieces so mixed bags remain usable. Theme differences should include reviewed original details, color and sound, not unrelated imported asset collections with conflicting scales.

## Music, sounds, fonts and presentation

Follow [AUDIO_VISUAL_SPEC.md](AUDIO_VISUAL_SPEC.md) for actual music loops, ambience, varied brick clicks and credits. Record source, author, exact licence, checksum, edits and rights for both game redistribution and inclusion in exported user films. Do not extend the existing procedural geometry's CC0 label to imported music, fonts, textures or model downloads. Audition loop seams and repeated effects, and inspect fonts/icons at the actual target size. Provide an offline reproducible conversion recipe and the real assets; filenames and silent placeholders do not close the content task.

Original meshes, procedural generic pieces and original toy characters are valid fallbacks when an optional asset tool is unavailable. Keep temporary art clearly identified and do not pass a visual/content gate with unnoticed placeholders. Verify music, sound effects, fonts and UI icons with the same discipline as meshes.

## Brand and code boundaries

Use LittleBricks in product branding. Create a distinctive explorer rather than assuming permission to reproduce an official Minifigure or franchise character. LEGO's [Fair Play guidance](https://www.lego.com/en-us/legal/notices-and-policies/fair-play) and [IP notice](https://www.lego.com/en-us/legal/notices-and-policies/intellectual-property-notice) are not blanket permission for a separately distributed game.

The repository's code licence does not override asset licences. Using Nova to author a model is different from copying Nova implementation into the runtime; assess both correctly. Any incorporated AGPL code or share-alike data needs an explicit compatible distribution decision. Keep accurate attribution even where an optional pack permits use without it. Record unresolved rights questions before public release instead of claiming that all downloaded content is cleared.
