# LB-068 Baseline, Catalogue & Camera Audit Report

**Date:** 2026-11-11  
**Git Baseline:** `0e8a0d3` (latest remote `main`)  
**Previous Campaign Commit:** `41e45b7`  
**Engine:** Godot Engine v4.7.2.stable.official.ed1daf0bf  
**Renderer:** GL Compatibility (`gl_compatibility`)  
**Web Server:** `http://localhost:8080/index.html` (Cross-Origin Isolated)

---

## 1. Baseline Summary & Visual Shortcomings

While the previous LB-057–LB-067 campaign repaired core input routing (Gate A mouse raycast placement), hand authority, session state, and 26 automated regression test suites, a live playthrough in the web browser revealed severe aesthetic and interaction deficiencies:

1. **Floating Environment:**
   - The building area consists of a green stud baseplate sitting on an unadorned beige slab floating in a generic procedural sky.
   - There are no walls, floor, windows, room lighting, furniture, or table edges. The scene lacks a sense of physical scale, warmth, or craft-table atmosphere.

2. **Camera Controls Incompleteness:**
   - While orbiting around the table center works, intuitive lateral panning (translating the camera target across the tabletop plane) is not readily discoverable or usable.
   - The current `Camera Mode` button toggles between orbit and normal mode, but has confusing label cycling (`Camera: Pan (C)`) and deactivates unexpectedly.
   - Players cannot smoothly pan left/right while holding a piece to inspect build corners.

3. **Cluttered Dark HUD:**
   - Top panel is a heavy dark container with technical labels.
   - Right side features 13 stacked dark rectangular buttons dominating the viewport.
   - Bottom inventory tray presents flat rectangular buttons with text labels instead of tactile 3D parts.

4. **Procedural Placeholder Bricks:**
   - While procedural mesh generation (`PartMeshBuilder`) replaced flat cubes with basic wedges and cylinders, distinctive physical parts (curved slopes, ship wheels, glass panes, hollow arches, fences, and flowers) lack authentic physical modeling and bevelled edges.

---

## 2. Asset Sourcing & Provenance Audit

| Source | Role in LittleBricks | License | Verification Status |
| :--- | :--- | :--- | :---: |
| **Kenney Brick Kit** | 290+ authentic brick, plate, slope, and corner models in GLB format. Scale factor `12.5x` exactly maps 0.08m unit to 1.0 stud grid and 0.40/1.20 plate/brick height. | **CC0 1.0** (Public Domain) | Verified & Downloaded (4.6 MB zip, SHA-256 audited) |
| **Kenney Furniture Kit** | Authentic room furniture: solid timber tables, chairs, bookcases, lamps, rugs, potted plants, and window frames in GLB format. | **CC0 1.0** (Public Domain) | Verified & Downloaded (5.1 MB zip, SHA-256 audited) |
| **LDraw Official Library** | Specialty physical parts (curved slopes, ship steering wheel, window glazing) downloaded with recursive DAT closures and author attribution. | **CC BY 4.0 / CC0** | Verified (`https://library.ldraw.org/library/official/parts/<id>.zip`) |
| **ambientCG** | Wood, plaster, and cloth PBR textures for realistic tabletop surfaces. | **CC0 1.0** | Verified |

---

## 3. Active Plan of Execution (LB-068–LB-074)

- **LB-069:** Complete camera controls overhaul: orbit, lateral pan, zoom, input ownership while holding a brick, explicit on-screen mode selector (`Build`, `Orbit`, `Pan`), and `Frame Plate` (`F`).
- **LB-070:** Build one cozy, bounded 3D room + wooden family table with visible margins, natural window daylight, floor, walls, and furniture.
- **LB-071:** Completely redesign HUD and inventory: on-table shallow trays with 3D thumbnail previews, minimal card top bar, and contextual placement cluster.
- **LB-072:** Import and bundle approved CC0 Kenney Brick Kit + Furniture Kit + vetted LDraw models with machine-readable `provenance.json`.
- **LB-073:** Rebalance mixed bags and hand distributions (high structural brick frequency, curated specialty accents).
- **LB-074:** Independent playtest verification across desktop and touch viewports, automated test matrix, screenshots, web packaging, and remote push.
