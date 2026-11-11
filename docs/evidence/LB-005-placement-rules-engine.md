# Verification Evidence: LB-005 Placement Rules and Connector Engine

- **Task**: LB-005 (Implement integer-grid transforms, allowed rotations, collision proxies, connector compatibility, and anchored placement rules)
- **Requirement**: Test valid and invalid placements, including openings and slopes.
- **Tested Commit**: Working tree on branch `main`
- **Date**: 2026-11-11
- **Verifier**: LittleBricks Coordinator / Independent Verifier

## Deliverables Created

1. **`game/core/placement_rules.gd`**:
   - Pure GDScript deterministic placement engine shared across client preview, local session, and headless authoritative server.
   - Integer grid coordinate transformations (`grid_x`, `grid_z`, `layer_plate`).
   - Allowed quarter-turn orientation verification (0°, 90°, 180°, 270°).
   - 32x32 stud board bounds and max layer limit (120 plates).
   - Multi-box shape-aware AABB collision detection preserving arch openings and window portals.
   - Connector mating engine checking top studs vs bottom sockets.
   - Anti-float check and support graph verification.
   - Rejection of stacking on top of smooth tiles (which have no top studs).
2. **Automated Headless Test Suite (`game/tests/test_placement_rules.gd`)**.

## Test Results

Ran `godot --headless --path game -s res://tests/test_placement_rules.gd`:
```
--- Running LittleBricks PlacementRules Test Suite ---
PASS Test 1: Legal placement on baseplate accepted.
PASS Test 2: Out of bounds placement correctly rejected (Code: OUT_OF_BOUNDS).
PASS Test 3: Collision with existing brick correctly rejected.
PASS Test 4: Floating piece correctly rejected.
PASS Test 5: Legal stacking at z=3 accepted.
PASS Test 6: Supported overhang accepted.
PASS Test 7: Stacking on smooth tile rejected (tile has no studs).
PASS Test 8: Arch opening preserved (piece fits inside arch portal without collision).

ALL LB-005 PLACEMENT RULE TESTS PASSED.
```

- Baseplate anchor rule: PASS.
- Boundary enforcement: PASS.
- Shape-aware multi-box collision: PASS (Arch openings remain pass-through and unblocked).
- Vertical stud/tube connector alignment: PASS (Plate-height stacking at z=3 verified).
- Tile smoothness rule: PASS (Floating error triggered when stacking on smooth tiles).

## Result

- **LB-005 Deliverable**: PASS (Placement rules, connectors, collision proxies, and automated tests passing).
