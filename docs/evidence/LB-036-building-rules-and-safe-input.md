# LB-036: Building Rules, Hands & Safe Input Evidence

## 1. Overview & Objective
Replace the fixed demo tray and direct placement array with the session's mixed hand/catalogue policy, turn ownership, refill from themed bags, timer, skip, and cooperative correction rules. Implement safe input ownership so UI clicks and camera drag gestures never place bricks accidentally (PC-07).

## 2. Implementation Details
- **Multiplayer Hand Integration**:
  - `main.gd` connects to `SessionManager`'s `turn_advanced`, `timer_ticked`, `timer_expired`, and `inventory_refilled` signals.
  - Active player banner shows current player name, turn counter, and color badge chip (`%ColorPlayerBadge`).
  - Active player's 6-piece hand is populated dynamically into `TrayContainer`.
  - When a brick is placed, it is submitted to `SessionManager.submit_placement()`, consumed from the player's hand, refilled from the theme bag via `_draw_piece_from_theme`, and turn automatically advances to the next player.
- **Turn Timer & Voluntary Skip**:
  - `_process(delta)` drives `session.tick_timer(delta)` when `session.timer_enabled` is active.
  - `%LabelTimer` updates every tick (`⏱ 20s`), turning warning color when $\le 5$ seconds remain.
  - Timeout triggers `session.skip_turn()`, advancing turn without spending pieces.
  - Voluntary skip button `%BtnPassTurn` allows skipping current turn at any time.
- **Undo / Redo with Dependent Move Protection**:
  - `_on_undo_pressed()` calls `session.undo_last_placement()`:
    - Protects against removing bricks that have dependent pieces stacked on top (`DEPENDENT_MOVE_EXISTS`).
    - Pops last node from `PlacedBricks` and `placed_pieces_data`.
  - `_on_redo_pressed()` calls `session.redo_placement()`:
    - Re-validates move against current board, rebuilds 3D mesh node, and restores piece.
  - Keyboard shortcuts: `Z` (Undo), `Y` (Redo), `P` (Pass Turn).
- **Solo Parts Catalogue Browser**:
  - `%BtnAllParts` opens modal dialogue `%CatalogModal`.
  - Categories dropdown: All, Bricks, Plates, Slopes, Openings, Tiles, Decorations, Characters.
  - Search filter: live text filtering by part name or part ID.
  - Selecting any part immediately sets `selected_part_id`, rebuilds the ghost preview, and updates the tray.
- **Safe Input Ownership (PC-07)**:
  - When `%CatalogModal` is open, all 3D world interaction is blocked.
  - Primary button drag/click does not leak through UI controls or modal overlays.

## 3. Verification & Evidence
Automated regression suite `game/tests/test_building_rules_and_hands.gd`:
- **Group 1**: 2-player Pass & Play turn progression, hand rendering, placement consumption, and hand refill.
- **Group 2**: Voluntary pass and turn timer countdown/timeout.
- **Group 3**: Undo/redo operations with dependent move protection.
- **Group 4**: Solo parts catalogue browser modal, category filtering, and text search.
- **Group 5**: Safe input ownership and modal isolation (PC-07).

All 5 groups passed 100% with exit code 0.
