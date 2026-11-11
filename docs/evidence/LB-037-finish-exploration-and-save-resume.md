# LB-037: Finish Agreement, Exploration & Save/Resume Evidence

## 1. Overview & Objective
Implement revision-bound unanimous finish agreement, safe original-explorer placement, first- and third-person POV switching, reset figure, return to tabletop with revision tracking, and round-trip disk save/resume.

## 2. Implementation Details
- **Unanimous Finish Agreement**:
  - In multiplayer (Pass & Play / Online), clicking `%BtnFinish` records the player's readiness vote (`session.set_ready_to_explore(cur_id, is_ready)`).
  - Top bar button updates dynamically: `🚶 Ready (1/2)`.
  - Stale agreement invalidation: placing any new brick on the board immediately calls `session._clear_all_readiness()`, clearing votes and resetting the button to `🚶 Explore`.
  - When all players agree (or immediately in Solo mode), phase transitions to `EXPLORATION` and `AppRoot` transitions to `ExplorationScene`.
- **Doorway & Clearance Building**:
  - `ExplorationWorld.generate_world_colliders()` generates smoothed static collision geometry that is smooth over studs but preserves vertical walls, hollow doorways, and arch portals.
  - Clearance validation confirms traversal clearance through arches (`arch_1x4`).
  - Spawns the toy explorer at a safe, unobstructed location on the baseplate.
- **Explorer POV & Controls**:
  - `ToyExplorer` supports seamless switching between 3rd-person follow camera and 1st-person POV with `%BtnTogglePOV` (shortcut `V`).
  - `%BtnResetFig` (shortcut `R`) smoothly teleports character back to safe spawn if obstructed or off-board.
- **Return to Building & Revision Increment**:
  - `%BtnReturnTable` emits `return_to_table(save_state)` back to `AppRoot`.
  - `active_session.return_to_building_new_revision()` increments `build_revision` (e.g. v1 $\to$ v2), sets phase to `BUILDING`, and clears readiness votes.
  - Table is reconstructed with 100% of placed bricks preserved.
- **Save, Leave & Resume**:
  - `save_and_leave()` atomically writes the session JSON to `user://saves/` via `SaveManager`.
  - `continue_latest_save()` seamlessly reads the latest file, reinstates players, theme, placements, and revision, and opens the interactive table.

## 3. Verification & Evidence
Automated regression suite `game/tests/test_finish_exploration_and_recovery.gd`:
- **Group 1**: 2-player unanimous agreement and vote invalidation on new placement.
- **Group 2**: Arch doorway construction, collision generation, and character spawning.
- **Group 3**: Explorer POV mode toggling (1st $\leftrightarrow$ 3rd) and safe figure reset.
- **Group 4**: Return to building increments build revision and preserves all placements.
- **Group 5**: Full journey Save $\to$ Leave $\to$ Continue roundtrip verification.

All 5 test groups passed 100% with exit code 0.
