# Verification Evidence: LB-053 Surface Height & Baseplate Return

- **Task**: LB-053 (Fix surface targeting, automatic surface height, manual override, and baseplate return).
- **Requirements**: PC-01 (10 consecutive independent baseplate placements), PC-02 (Alternating baseplate/brick top targeting), PC-03 (Auto/Manual/Return to Base), PC-07 (Input isolation; UI buttons never place bricks).
- **Tested Engine**: Godot 4.7.2.stable.official.ed1daf0bf
- **Date**: 2026-11-11
- **Verifier**: LittleBricks Gameplay / Coordinator Role

---

## 1. Problem Description & Root Cause

In the original prototype:
- `main.gd::_on_place_pressed()` unconditionally incremented `current_layer_plate += height` after every placement.
- Pointer raycasting intersected a fixed horizontal plane locked at `current_layer_plate`.
- If a user placed a brick on the baseplate and then pointed at an empty area of the board, the raycast still evaluated at height 3 plates, resulting in an immediate `[INVALID] FLOATING` error.
- Height controls were keyboard-only, with no visible Auto/Manual toggle or Return to Base control.

---

## 2. Implemented Architecture & Algorithms

1. **Auto Height Surface Raycaster (`find_target_surface_from_ray`)**:
   - Casts a ray from the camera against:
     1. The baseplate plane ($y = 0.1$, layer 0).
     2. The top faces of all currently placed bricks ($y = 0.1 + \text{top\_layer} \times 0.4$).
   - Finds all valid intersections within the 32x32 board footprint.
   - Selects the closest surface along the ray to the camera (smallest positive $t$).
   - Pointing at uncovered baseplate targets layer 0 automatically.
   - Pointing at a placed brick automatically targets its top connector layer.
2. **Elimination of Forced Stacking**:
   - `_on_place_pressed()` no longer adds piece height unconditionally to `current_layer_plate`.
   - The surface under the cursor immediately re-evaluates. If the player moves the cursor away to baseplate, the preview returns to layer 0.
3. **Manual Height Controls**:
   - `is_auto_height`: Boolean toggle default to `true`.
   - `BtnAutoHeight`: UI button toggles between `Auto Height [ON]` and `Manual Height [ON]` (shortcut `M`).
   - `BtnLayerDown` / `BtnLayerUp`: Step height down/up by 1 plate. Pressing either explicitly locks into Manual mode.
   - `BtnReturnBase`: Resets layer to 0 and clears manual lock, returning to Auto Height (shortcut `B` or `0`).
4. **Input Isolation (PC-07)**:
   - Uses `_unhandled_input(event)` so UI controls (tray buttons, menus, sliders) consume mouse events first.
   - Clicking on GUI elements never commits a brick or repositions the ghost preview.

---

## 3. Test Evidence: `test_surface_height_and_camera.gd`

Command run:
```bash
godot --headless --path game -s tests/test_surface_height_and_camera.gd
```

Output:
```
--- Running LittleBricks Surface Height & Camera Usability Suite (LB-053/LB-055) ---

[Group 1: PC-01 Consecutive Independent Baseplate Placements]
PASS: 10 consecutive independent baseplate placements accepted at layer 0 without floating errors.

[Group 2: PC-02 Alternating Baseplate and Brick Tops]
PASS: Alternating baseplate and brick tops detects exact surface layers (0 -> 3 -> 0).

[Group 3: PC-03 Auto, Manual, Return to Base]
PASS: Manual mode locks, layer increments/decrements, and Return to Base clears lock.

[Group 4: PC-07 UI Input Isolation]
PASS: UI controls and tray selections do not cause accidental placements.
```

---

## 4. Acceptance Status
- **PC-01 (10 Consecutive Baseplate Placements)**: `PASS`
- **PC-02 (Alternating Ground and Tops)**: `PASS`
- **PC-03 (Auto/Manual/Return to Base)**: `PASS`
- **PC-07 (UI Input Isolation)**: `PASS`
- **LB-053 State**: `done`
