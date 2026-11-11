---
name: littlebricks-assets
description: Prepare and validate LittleBricks bricks, theme packs, toy explorers, audio, and visual assets. Use when finding free content, converting LDraw or GLB, adding connector/collision metadata, normalizing scale, expanding a catalogue, or auditing licences and attribution.
---

# Prepare LittleBricks assets

Read [AGENTS.md](../../../AGENTS.md), [ASSETS](../../../docs/ASSETS.md), [ARCHITECTURE](../../../docs/ARCHITECTURE.md), and the assigned task. Confirm the coordinator's file ownership and active catalogue version.

For this campaign, follow [PLACEMENT_AND_CATALOG](../../../docs/PLACEMENT_AND_CATALOG.md) and LB-056 in [RECOVERY_PLAN](../../../docs/RECOVERY_PLAN.md): audit existing entries, then 80 and at least 120 verified buildable shapes, with 150 as a stretch target. Complete the canonical lattice and PC fixtures before expansion. Color variants, characters and unsupported records do not count. Render meshes must depict actual slopes/curves/openings rather than merely reusing collision boxes. Preserve the six-piece multiplayer hand while enabling a usable full solo catalogue.

## Choose the smallest useful input

Prefer original art or reviewed creator/project sources. Evaluate Kenney's documented CC0 packs first for prototype needs. Use LDraw/Nova or LDCad metadata only where they help the assigned task and their separate terms are understood. Read the available Godot/Blender/asset tooling instructions; discover actual tools before calling them. Fall back to a reproducible local conversion pipeline when an optional plugin is unavailable.

Do not install a large pack or tool framework just to obtain one shape. Do not put runtime AI calls into ordinary building or offline solo play.

## Ingest and prove a part

1. Record source URL, author, revision/checksum, licence, dependencies and modifications before import. Inspect actual file headers and all included subparts.
2. Normalize units, axes, pivot, materials and dimensions against the documented stud/plate scale. Preserve useful source inputs and a reproducible conversion recipe.
3. Add stable ID/version, permitted rotations, render data, placement body proxies, connector transforms/types and simplified explorer collision.
4. Keep intended stud/socket engagement separate from forbidden overlap. Preserve arch/window openings. A bounding-box-only shortcut cannot represent every shape.
5. Inspect the imported part in the running game from relevant views; test connection, rotation, stacking, rejection, and character clearance where relevant.
6. Profile representative repeated use before increasing catalogue/scene limits. Distinguish shape count from color/quality variants.
7. Update the versioned catalogue and generated attribution together. Do not silently change a part used by existing saves.

Build themes from compatible core parts, palettes and a few reviewed details. Keep mixed bags structurally useful. Maintain a distinctive LittleBricks identity and original explorer; a mesh download is not trademark or character clearance.

For music, sounds, fonts and visual presentation, read [EXPERIENCE_DESIGN](../../../docs/EXPERIENCE_DESIGN.md) and [AUDIO_VISUAL_SPEC](../../../docs/AUDIO_VISUAL_SPEC.md). Deliver real licensed source/runtime assets, clean loop boundaries and a compact varied click set. Record rights for game redistribution and exported-film inclusion; audition on phone speakers/headphones and inspect the actual integrated visuals. Never infer that a new audio/downloaded asset shares the procedural catalogue's CC0 designation.

## Handoff

Return reviewed assets/metadata, source and licence records, conversion steps, executed fixtures, visual evidence, performance observations and unresolved gaps. Tell the coordinator which manifest/schema changes require integration. Do not mark unavailable in-engine or device checks as passed. Require independent verification before closing the asset task.
