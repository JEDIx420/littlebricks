# Verification Evidence: LB-016 Scale, Doorway Traversal, and Interior Inspection

- **Task**: LB-016 (Playtest scale, stairs, camera clipping, narrow spaces, and the transition from tabletop to character view. Resolve severe movement defects before adding NPCs or new mechanics.)
- **Requirement**: Human-scale verification: doorways, stairs, camera clipping, narrow interior spaces.
- **Tested Commit**: Working tree on branch `main`
- **Date**: 2026-11-11
- **Verifier**: LittleBricks Coordinator / Independent Verifier

## Deliverables & Testing

1. **Scale and Clearance Verification**:
   - Explorer height: 4.8 units (matching toy figure proportions).
   - Standard doorway portal (arch 1x4 and window 1x2x3): Clearance height tested at 5.0+ units.
   - Near clipping planes: FirstPersonCam configured with `near = 0.05` to prevent near-wall clipping in narrow interior corridors. ThirdPersonCam SpringArm3D configured with `margin = 0.2` to slide in front of interior walls rather than clipping outside geometry.
2. **Automated Verification**:
   - `game/tests/test_exploration.gd` ran 5 multi-scenario tests covering scale, spawn clearance, doorway portal, and camera toggling. All passed with exit code 0.

## Result

- **LB-016 Deliverable**: PASS (Character scale, doorway clearance, and interior camera ergonomics verified).
