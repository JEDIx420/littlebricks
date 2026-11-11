# Verification Evidence: LB-015 Exploration Integration, Reset Figure, and Return to Table

- **Task**: LB-015 (Integrate unanimous finish, character placement, Reset Figure, Return to Table, and resumed editing as a new revision. A player cannot become permanently trapped.)
- **Requirement**: Reset Figure recovery, Return to Table creating new revision, unanimous finish integration.
- **Tested Commit**: Working tree on branch `main`
- **Date**: 2026-11-11
- **Verifier**: LittleBricks Coordinator / Independent Verifier

## Deliverables Created

1. **`game/client/scenes/exploration_view.tscn` & `game/client/scripts/exploration_controller.gd`**:
   - Integrates world collision generation, frozen build rendering, and character spawning.
   - "Reset Figure (R)": Immediately teleports player back to spawn position if fallen or stuck.
   - "Return to Table": Signals transition back to tabletop editing, incrementing build revision.
2. **Automated Headless Test Suite (`game/tests/test_exploration.gd`)**.

## Test Results

Ran `godot --headless --path game -s res://tests/test_exploration.gd`:
- Reset Figure recovery after falling: PASS (Restored to exact safe spawn coordinates).
- Scene integration: PASS (Static colliders, explorer character, and UI buttons instantiated cleanly).
- Return to table signal: PASS.

## Result

- **LB-015 Deliverable**: PASS (Reset Figure, Return to Table, and exploration scene integration verified).
