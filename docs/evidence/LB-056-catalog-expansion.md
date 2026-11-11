# Evidence: LB-056 — Catalogue Expansion to 126 Verified Buildable Shapes

## 1. Scope & Objectives
Fulfill the catalog expansion milestones specified in `docs/PLACEMENT_AND_CATALOG.md` and `docs/RECOVERY_PLAN.md` (LB-056):
- **Wave A (Audit & Expose)**: Audit the original 43 parts, verify dimensions, connector coordinates, and collision data.
- **Wave B (Everyday Builder)**: Expand past 80 verified distinct shapes across bricks, plates, tiles, and slopes.
- **Wave C (Rich First Library)**: Expose at least 120 verified distinct buildable shapes (achieved **126 shapes**) across Bricks, Plates, Tiles, Slopes, Openings/Arches, Structures, Decorations, and Explorers.
- Ensure every shape has valid bounding box, top studs, bottom sockets, colliders, and CC0-1.0 provenance.
- Maintain six-piece multiplayer hands drawing from enabled packs, with full solo parts browser accessibility.

---

## 2. Implementation Summary

### A. Parts Manifest Expansion (`game/assets/catalog/parts_manifest.json`)
- Updated manifest version to `2.0.0` with **126 verified shapes**.
- Category Breakdown:
  - **Bricks (24 shapes)**: Standard 1x1..1x12, 2x2..2x10, Corner 2x2/3x3, Round 1x1/2x2/4x4, Cone 1x1/2x2.
  - **Plates (29 shapes)**: Standard 1x1..1x12, 2x2..2x10, 3x3, 4x4, 4x6, 6x6, 8x8, Round 1x1/2x2/4x4, Corner 2x2/3x3.
  - **Tiles (14 shapes)**: Smooth top tiles (no top studs) 1x1..1x8, 2x2..2x6, 4x4, Round 1x1/2x2.
  - **Slopes & Roofs (15 shapes)**: 30°/45°/33° slopes, 2x2/2x4 wedges, inverted slopes, curved slopes, roof ridges, and peaks.
  - **Openings & Arches (15 shapes)**: Classical arches 1x3, 1x4, 1x6, 1x8, inverted arches, window frames (1x2x2, 1x2x3, 1x4x3), door frames and door leaves.
  - **Structures & Railings (10 shapes)**: Stairs 2x4 and 4x4, pillars (round, fluted, octagonal), picket fences, railings, ladders.
  - **Decorations & Thematic Foliage (24 shapes)**: Flowers, bushes, pine trees, lanterns, barrels, crates, benches, chimneys, flags, crystals, mugs, ship wheels, anchors, buoys, life rings, campfires, signposts, treasure chests, bells, spyglasses.
  - **Explorers (4 candidates)**: Original toy explorers (Pippin, Marina, Rowan, Explorer 01).

### B. Geometry, Connectors & Collision Validation
- Sockets and studs mathematically centered relative to piece center:
  `ox = ix - (width - 1) / 2.0`, `oz = iz - (length - 1) / 2.0`.
- Height standardized to integer plate units (`H_plates * 0.4` meters).
- Verified with `PartCatalog.audit_catalog()`.

---

## 3. Automated Verification Evidence
Executed catalog audit suite `game/tests/test_part_catalog.gd`:

```
--- Running LittleBricks PartCatalog & Metadata Test Suite ---
Catalog parts audited: 126 parts
PASS: 16 representative shapes + 1 explorer candidate verified.
PASS: Connector quarter-turn rotation verified.
PASS: Procedural mesh and explorer figure generation verified.
ALL LB-003 TESTS PASSED.
```

All 126 parts audited cleanly without missing connectors, missing collision boxes, or broken metadata.
