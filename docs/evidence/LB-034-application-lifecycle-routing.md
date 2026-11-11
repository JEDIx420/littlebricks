# LB-034: Application Lifecycle & Session Routing Evidence

## 1. Overview & Objective
Implement the master application lifecycle controller and screen routing system (`AppRoot`), providing seamless state transitions between Welcome, Mode Select, Table Setup, 3D Tabletop Building, Toy Exploration, and Saved Builds without leaking memory or corrupting active session state.

## 2. Implementation Details
- **Architecture**: `game/client/scenes/app_root.tscn` and `game/client/scripts/app_root.gd` configured as `run/main_scene` in `project.godot`.
- **Subsystem Ownership**:
  - `AudioDirector`: Persistent across all views, handling menu music, building music, theme ambience, and sound effects without restarting streams on scene transitions.
  - `HapticsAdapter`: Provides platform vibration feedback.
  - `SettingsManager`: Persists sound, volume, and accessibility preferences.
  - `SessionManager`: Single source of truth for active player hands, turn rotation, accepted placements, and journaled events.
- **View Transitions**:
  - `navigate_to_welcome()`: Loads `WelcomeScreen`, activates `music_menu`.
  - `navigate_to_mode_select()`: Loads `ModeSelectScreen`.
  - `navigate_to_setup(mode)`: Loads `SetupScreen` configured for the chosen mode.
  - `start_session(config)`: Instantiates `MainTableScene`, initializes `SessionManager`, activates `music_building` and theme ambience.
  - `_on_table_finish_requested()`: Transitions to `ExplorationScene` with full placement geometry.
  - `_on_return_to_table_requested(save_state)`: Smoothly restores tabletop with exact placements intact and revision incremented.
  - `save_and_leave()`: Writes creation atomically to `user://saves/` via `SaveManager` and returns to `WelcomeScreen`.
  - `continue_latest_save()`: Restores the newest save from disk into an active session and opens the tabletop.

## 3. Verification & Evidence
Automated regression suite `game/tests/test_app_lifecycle_and_audio.gd`:
- **Group 1**: Clean startup loading `WelcomeScreen`.
- **Group 3**: Navigation roundtrip: `Welcome -> ModeSelect -> Back -> Welcome -> ModeSelect -> Setup -> Tabletop`.
- **Group 4**: In-game building -> finish consensus -> exploration -> return to table preserves exact piece count and lattice positions.
- **Group 5**: Save & Leave writes disk file; Continue restores active session and tabletop nodes.

All 5 test groups passed 100% with exit code 0.
