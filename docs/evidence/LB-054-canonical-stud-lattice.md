# Verification Evidence: LB-054 Canonical Stud Lattice & Pivot Contract

- **Task**: LB-054 (Establish one canonical stud lattice and pivot contract; guarantee exact alignment of 1xN on 2xN across all 4 quarter-turns).
- **Requirements**: PC-04 (1x4 on 2x4 Golden Fixture), PC-05 (Odd & Even Parity across parts), PC-06 (Baseplate Boundaries & Corners), shared single transform across visuals, colliders, sockets, saves, and replay.
- **Tested Engine**: Godot 4.7.2.stable.official.ed1daf0bf
- **Date**: 2026-11-11
- **Verifier**: LittleBricks Gameplay / Coordinator Role

---

## 1. Root Cause Analysis

Prior to this fix:
- In `parts_manifest.json`, connector and collision coordinates are centered relative to the piece bounding box (e.g., `brick_2x4` has studs at `x = ±0.5`, while `brick_1x4` has studs at `x = 0.0`).
- The old `TableView.grid_to_world` anchored the 3D center of every part at an integer grid coordinate: `(gx - 15.5) * STUD_SPACING`.
- Consequently:
  - For `brick_1x4` at `gx = 8`: 3D center was placed at world `-7.5` (grid stud 8.0).
  - For `brick_2x4` at `gx = 8`: 3D center was placed at world `-7.5`, causing its two stud rows to land at world `-8.0` (grid stud 7.5) and `-7.0` (grid stud 8.5).
  - A 1x4 thus sat at `x = 8.0`, directly between the 2x4's rows at `7.5` and `8.5`!
  - `PlacementRules` rounded fractional coordinates, creating an irreconcilable visual-to-logic mismatch.

---

## 2. Mathematical Definition of Canonical Lattice

Under the canonical contract established in LB-054:
1. **Grid Anchor**: `(gx, gz)` is strictly the **minimum integer stud coordinate** occupied by the piece footprint:
   $$\text{footprint}(dx, dz, \text{rot}) = \begin{cases} (dz, dx) & \text{if } \text{rot} \in \{1, 3\} \\ (dx, dz) & \text{if } \text{rot} \in \{0, 2\} \end{cases}$$
2. **Geometric Center**:
   $$\text{center\_grid} = \left( gx + \frac{\text{fp}_x - 1}{2}, \; gz + \frac{\text{fp}_z - 1}{2} \right)$$
3. **Absolute Studs & Sockets**:
   For any local connector $(s_x, s_z)$ defined in the catalog relative to the geometric center:
   $$\text{rot\_s} = \text{rotate\_coord}(s_x, s_z, \text{rot})$$
   $$\text{abs\_stud} = \left( \text{round}(\text{center\_grid}_x + \text{rot\_s}_x), \; \text{plate\_height}, \; \text{round}(\text{center\_grid}_z + \text{rot\_s}_y) \right)$$
   Because $\frac{\text{fp}_x - 1}{2}$ is a half-integer when $\text{fp}_x$ is even (matching $s_x \in \{\pm 0.5\}$) and an integer when $\text{fp}_x$ is odd (matching $s_x = 0.0$), $\text{center\_grid} + \text{rot\_s}$ is **always an exact integer**. No rounding loss or half-stud floating points occur.
4. **3D World Position**:
   $$\text{world\_pos} = \left( (\text{center\_grid}_x - 15.5) \cdot \text{STUD\_SPACING}, \; 0.1 + z_{\text{plate}} \cdot \text{PLATE\_HEIGHT}, \; (\text{center\_grid}_z - 15.5) \cdot \text{STUD\_SPACING} \right)$$
5. **3D Rotation**:
   $$\text{rotation\_degrees} = (0.0, \; -(\text{rot} \bmod 4) \times 90^\circ, \; 0.0)$$
   Matches the clockwise rotation of `PartCatalog.rotate_coord`.

---

## 3. Implemented Modules

1. **`game/core/placement_rules.gd`**:
   - Added `get_part_footprint`, `get_part_center_grid`, `grid_to_world`, `get_rotation_degrees`, `world_to_grid`.
   - Updated `get_absolute_bottom_sockets` and `get_absolute_top_studs` to use canonical center offsets.
   - Updated `get_part_aabbs` to use continuous center grid coordinates.
   - Updated `validate_placement` bounds checking to enforce `gx + fp.x <= GRID_SIZE` and `gz + fp.y <= GRID_SIZE`.
2. **`game/client/scripts/table_view.gd`**:
   - Delegated `grid_to_world` and `world_to_grid` to `PlacementRules`, maintaining backward compatibility.
3. **`game/client/scripts/main.gd`**:
   - Raycast pointer targeting now supplies part dimensions and rotation to `TableView.world_to_grid`.
   - Ghost transform and placed pieces use `grid_to_world` and `PlacementRules.get_rotation_degrees`.
4. **`game/replay/replay_timeline.gd`**:
   - Pass part dimensions and rotation to `TableView.grid_to_world` and use `PlacementRules.get_rotation_degrees`.
5. **`game/client/scripts/exploration_controller.gd` & `game/core/exploration_world.gd`**:
   - Updated visual nodes and collision shape generators to use exact part dimensions and rotation.

---

## 4. Test Evidence: `test_canonical_lattice.gd`

Command run:
```bash
godot --headless --path game -s tests/test_canonical_lattice.gd
```

Output:
```
--- Running LittleBricks Canonical Stud Lattice Suite (LB-054) ---

[Group 1: PC-04 Golden Fixture 1x4 on 2x4]
PASS: 2x4 top studs exactly cover x={8, 9}, z={8..11} at plate 3.
PASS: 1x4 cleanly aligns with Row 0 (x=8) at rot=0.
PASS: 1x4 cleanly aligns with Row 1 (x=9) at rot=0.
PASS: 1x4 at gx=10 correctly rejected as FLOATING.
PASS: 1x4 at rot=2 (180°) cleanly aligns with Row 0 and Row 1.
PASS: 1x4 at rot=1 (90°) cleanly aligns with Row 0 (z=8) and Row 1 (z=9).
PASS: 1x4 at rot=3 (270°) cleanly aligns with Row 0 and Row 1.
PASS: Cross-stacking 1x4 across 2x4 connects exactly 2 studs.

[Group 2: PC-05 Odd & Even Parity Check]
PASS: All 11 odd/even parts preserve integer stud addresses and round-trip world coordinates.
PASS: Smooth tile_1x4 top surface correctly rejects stacking as FLOATING.

[Group 3: PC-06 Baseplate Boundaries & Corners]
PASS: All 4 baseplate corners accept 2x4 placement.
PASS: Negative coords, board overflow, and height limits strictly rejected as OUT_OF_BOUNDS.

[Group 4: 3D Rotation Contract Parity]
PASS: PlacementRules.get_rotation_degrees matches clockwise Y rotation.

ALL LB-054 CANONICAL STUD LATTICE REGRESSION CHECKS PASSED.
```

---

## 5. Acceptance Status
- **PC-04 (1x4 on 2x4 Golden Fixture)**: `PASS`
- **PC-05 (Odd/Even Parity Check)**: `PASS`
- **PC-06 (Baseplate Boundaries & Corners)**: `PASS`
- **LB-054 State**: `done`
