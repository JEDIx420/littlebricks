# LB-058 Evidence: Input Ownership, Stale Candidate Clearance, and Gate A Verification

Date: **2026-11-11**  
Task ID: **LB-058**  
Task Name: **Restore pointer placement and exclusive input ownership**  
Owner: **gameplay/input, with verifier**  
Status: **PASS (Gate A Verified)**

---

## 1. Summary of Repairs

### A. Root Cause Resolution for Frozen Center Pointer (`LIVE-01`, `LIVE-02`)
- **Root Cause**: `game/client/scenes/app_root.tscn:8-14` contained `ViewContainer` (`anchors_preset = 15`) defaulting to `mouse_filter = 0` (`STOP`). Because it spanned 100% of the viewport and was rendered above the 3D table, it swallowed all mouse motion and click events before `_unhandled_input` in `main.gd` could receive them.
- **Fix**: Updated `app_root.tscn` to set `mouse_filter = 2` (`MOUSE_FILTER_IGNORE`) on `ViewContainer`.

### B. Input State Machine & Exclusive Ownership
Implemented an explicit input owner state machine in `main.gd`:
- `IDLE`: No piece held (e.g., after pressing Escape/Cancel). Ghost preview is hidden, and `BtnPlace` is disabled.
- `HOLDING`: Piece selected and held. Candidate moves with pointer.
  - On valid surface: `has_valid_target_surface = true`, `ghost_preview.visible = true`, `btn_place.disabled = false`.
  - Over uncovered world (off-board): `has_valid_target_surface = false`, `is_current_placement_valid = false`, `ghost_preview.visible = false`, `btn_place.disabled = true`. Status indicates `"Pointer outside building area"`.
  - Over UI controls: Candidate preserved at last valid world position with pinned preview visible, allowing mouse to leave the board onto the "Place" button to commit without raycasting UI coordinates (`PT-03`).
- `CAMERA_GESTURE`: Left-drag in Camera Mode, right-drag orbit, middle-drag pan, or touch pinch-zoom. All placement is strictly locked out. Mouse motion and button events are consumed via `get_viewport().set_input_as_handled()`, preventing any ghost movement or accidental placements (`PT-02`).
- `MODAL`: Catalog modal or Settings modal open. All world interaction is blocked.
- `PENDING_ACCEPTANCE`: Command dispatched to `SessionManager`, awaiting authoritative event. Prevents double-commit.

### C. Place Action Decoupling
- Removed `MOUSE_BUTTON_LEFT` from the `place` action in `game/project.godot`. `place` now exclusively maps to `KEY_ENTER` and `KEY_KP_ENTER`.
- Left-clicks in the 3D world are handled safely in `main.gd._unhandled_input`:
  - Guarded against `camera_rig.is_camera_mode`, `is_orbiting`, `is_panning`, and `current_input_state == IDLE`.
  - Resolves the raycast at the exact screen position of that click (`event.position`). If off-board, invalidates candidate and does not place. If on-board and valid, commits placement.

### D. Obvious Cancellation (Escape / Cancel Button)
- Added `BtnCancel` ("Cancel (Esc)") in `main.tscn` directly below `BtnPlace`.
- Mapped `KEY_ESCAPE` and `ui_cancel` to `_on_cancel_held_piece()`, transitioning from `HOLDING` to `IDLE`, hiding the ghost, and freeing the pointer.
- Re-selecting any piece from the inventory tray or catalogue restores `HOLDING` state.

### E. Modal Wheel Zoom Isolation (`LIVE-04`)
- Converted `camera_controller.gd` from `_input(event)` to `_unhandled_input(event)`.
- UI controls (`ScrollContainer` in bottom tray, `CatalogModal`, settings sliders) consume wheel events first, preventing camera zoom while scrolling through the catalogue or inventory.

---

## 2. Gate A Verification Matrix

The test suite `game/tests/test_gate_a_input_ownership.gd` was executed via headless Godot, covering all mandatory integrated checks:

| Gate Check | Description | Required Interaction & Assertion | Result |
| --- | --- | --- | --- |
| **PT-01** | Real pointer targeting & 10 separated placements | Placed 10 distinct pieces at separated baseplate coordinates: `(2,2)`, `(8,2)`, `(14,2)`, `(20,2)`, `(26,2)`, `(2,20)`, `(8,20)`, `(14,20)`, `(20,20)`, `(26,20)`. Stacked 1x4 on 2x4 at layer 3. Verified `return_to_base()` returns to layer 0 and restores Auto Height. | **PASS** |
| **PT-02** | Camera & UI exclusive ownership | Activated Camera Mode (`is_camera_mode = true`). Performed left-drag orbit and mouse motion across the viewport. Asserted zero placements added and zero turn changes. | **PASS** |
| **PT-03** | Stale target clearance & toolbar preservation | Aimed at valid ground, then moved ray off-board (uncovered world). Verified candidate invalidated, ghost hidden, and `BtnPlace` disabled. Verified Enter/Place commits zero pieces when off-board. Moved onto UI toolbar and verified displayed candidate preserved and committed. | **PASS** |
| **Cancel** | Escape & Cancel button | Invoked `_on_cancel_held_piece()`. Verified transition to `IDLE`, ghost hidden, `BtnPlace` disabled. Re-selected piece from tray and verified `HOLDING` restored. | **PASS** |
| **PT-05** | Pass & Play hand policy | Started 2-player Pass & Play. Attempted to place outside-hand part (`brick_1x1`). Verified rejection with code `OUTSIDE_HAND`, zero board changes, and turn retained on active player. | **PASS** |
| **PT-06** | Color preservation across save | Placed permitted piece with custom color `(0.7, 0.1, 0.9)`. Verified session records exact color and `SaveManager` serializes/deserializes matching hex color without degradation. | **PASS** |

Execution Command:
```bash
godot --headless --path game -s tests/test_gate_a_input_ownership.gd
```
Output:
```
--- Running LittleBricks Gate A Input Ownership & Authority Suite ---

[PT-01: Real Pointer & Separated Placements]
PASS: 10 separated placements successfully committed across baseplate.
PASS: Narrow part stacking and Return to Base verified.

[PT-02: Camera / UI Ownership]
PASS: Camera gestures do not commit placements or corrupt state.

[PT-03: Stale Target Clearance & Toolbar Candidate Preservation]
PASS: Off-board misses clear candidate; toolbar preserves candidate.

[Cancel / Escape Action]
PASS: Cancel and piece re-selection verified.

[PT-05 & PT-06: Pass & Play Hand Enforcement & Color Parity]
pp_session placement_rejected caught: OUTSIDE_HAND - Selected part 'brick_1x1' is not in active hand
Alice placement record: { "placement_id": "pl_1", "sequence": 1, "player_id": "p_1", "part_id": "brick_2x2", "grid_x": 4, "grid_z": 4, "layer_plate": 0, "rotation_step": 0, "color": (0.7, 0.1, 0.9, 1.0) }
custom_color was: (0.7, 0.1, 0.9, 1.0)
PASS: Outside-hand rejection, turn advance, and color roundtrip verified.

ALL GATE A INTEGRATED CHECKS PASSED SUCCESSFULLY.
```
