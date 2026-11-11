# LB-059 Evidence: Authoritative Session Policy, Hand Membership, and State Parity

Date: **2026-11-11**  
Task ID: **LB-059**  
Task Name: **Make session policy and accepted state authoritative**  
Owner: **gameplay/core, with verifier**  
Status: **PASS**

---

## 1. Summary of Repairs

### A. Authoritative Command & Event Pipeline
- Replaced the tabletop's previous spawn-before-submit implementation in `main.gd` with a strictly authoritative request/acceptance model:
  - `_on_place_pressed()` transitions state to `PENDING_ACCEPTANCE` and issues `session.request_placement(player_id, hand_slot, gx, gz, layer_plate, rot_step, color, part_id)`.
  - Permanent 3D mesh creation, `placed_pieces_data` recording, and audio/haptic feedback now execute **exclusively** inside `_on_placement_accepted()`.
  - Rejection events (`session.placement_rejected`) leave board geometry, inventory trays, turn state, and event journals completely unchanged.

### B. Hand Membership Enforcement (`PT-05`, `LIVE-08`)
- In `SessionManager.request_placement()`:
  - If game mode is `PASS_AND_PLAY` or `SOLO_CHALLENGE` (Mixed Bags):
    - Validates active player identity (`player_id == get_current_player_id()`).
    - Validates hand slot bounds ($0 \le \text{slot} < 6$).
    - Verifies that the requested part exists in the active player's hand. If a player attempts to place an outside-hand piece, the request is rejected with `OUTSIDE_HAND`.
    - Upon valid placement, automatically consumes the piece from the active hand and refills the slot via `_draw_piece_from_theme()`, emitting `inventory_refilled`.
    - Automatically advances turn to the next player.
  - If game mode is `SOLO_CREATIVE` (Free Build):
    - Permits placing any part from the catalog without hand constraints or turn advancement.

### C. Catalogue Modal Mode Guard
- In `main.gd._populate_catalog_grid()`:
  - In `SOLO_CREATIVE`, selecting a part from the catalogue equips it for building.
  - In `PASS_AND_PLAY` and `SOLO_CHALLENGE`, the catalogue functions as a browse-only reference. Clicking a part displays status feedback: `"In Mixed Bags mode, build using your 6 hand pieces!"`, preventing inventory bypasses.

### D. Color Preservation & Roundtrip Parity (`PT-06`, `LIVE-06`)
- `request_placement` and `submit_placement` in `SessionManager` now accept and record `piece_color`.
- `main.gd._on_placement_accepted` renders using the exact `placement_record["color"]`.
- `SaveManager.serialize_session` serializes placements with `"color_hex"`, and `SaveManager.load_from_file` and `AppRoot.continue_latest_save` reconstruct colors via `Color.from_string(col_hex, Color.WHITE)`.
- Verified roundtrip color consistency across building, explore, return, and save/reload.

---

## 2. Automated Test Evidence

Both `test_gate_a_input_ownership.gd` and `test_journey_recovery_validation.gd` verified:
1. `OUTSIDE_HAND` rejection when requesting an unheld part in Pass & Play.
2. Exact custom color preservation in memory and serialized saves.
3. Clean turn advance from P1 (Alice) to P2 (Bob) only after authoritative acceptance.
4. Mode policy distinction: Free Build allows full catalogue, while Pass & Play enforces 6-piece hands.
