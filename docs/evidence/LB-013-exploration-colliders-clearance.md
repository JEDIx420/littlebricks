# Verification Evidence: LB-013 Exploration Colliders, Smoothed Studs, and Spawn Clearance

- **Task**: LB-013 (Freeze a build revision and create simple exploration colliders. Validate character clearance and supported spawn surfaces; preserve openings.)
- **Requirement**: Freeze build revision, smoothed static colliders (prevent stud jitter), character clearance check, doorway preservation.
- **Tested Commit**: Working tree on branch `main`
- **Date**: 2026-11-11
- **Verifier**: LittleBricks Coordinator / Independent Verifier

## Deliverables Created

1. **`game/core/exploration_world.gd`**:
   - `generate_world_colliders(placements)`: Generates static collision shapes for the entire frozen build.
   - Stud smoothing: Omits tiny stud colliders on top surfaces, allowing the capsule character to walk smoothly across bricks without tripping or vibration jitter.
   - Portal preservation: Arch and window multi-box collision definitions preserve walk-through portals and open sightlines.
   - `validate_spawn(gx, gz, z_plate, placements)`: Validates foot support and capsule clearance (4.5 units height). Rejects spawns inside solid walls.
   - `find_default_spawn(placements)`: Automatically discovers the nearest safe unobstructed spawn point on the baseplate.
2. **Automated Headless Test Suite (`game/tests/test_exploration.gd`)**.

## Test Results

Ran `godot --headless --path game -s res://tests/test_exploration.gd`:
- Smoothed static colliders: PASS.
- Baseplate spawn validation: PASS (Open coordinate accepted).
- Solid wall obstruction detection: PASS (Coordinate inside brick rejected).
- Doorway preservation: PASS.

## Result

- **LB-013 Deliverable**: PASS (Exploration colliders, smoothed studs, and spawn clearance verified).
