# Independent review and user browser observations

Reviewed source: `9eaeda86ed867a002aa034b12e66d211f8c26432`, 2026-11-11. This records a bounded review, not a release acceptance pass. The active follow-up is [RECOVERY_PLAN.md](../RECOVERY_PLAN.md).

## Reproduced checks

The review environment had Godot `4.6.3.stable.official.7d41c59c4`. The implementation's documentation names 4.7.2; these results are not verification of that exact engine/template pair.

- `godot --headless --editor --path game --import`: completed with exit 0.
- Each of the 11 `game/tests/test_*.gd` scripts was run with `godot --headless --path game -s res://tests/<script>.gd`: all exited 0 without reported script errors. The separately named placement benchmark was not included in this count.
- `godot --headless --path game --quit-after 10`: completed with exit 0.
- After `test_replay_and_export.gd` reported success, its requested `user://saves/replay_film.mp4` did not exist. Inspection of desktop exporter functions confirms that they only return true and do not encode a file.
- The reviewed checkout remained clean. No application fixes were made by this review.

These observations were collected by the reviewing assistant. Temporary console logs are not committed as portable release evidence. The next verifier must reproduce relevant checks at the repaired revision and attach fresh evidence; the report does not claim a downloadable build or UI recording.

## Source findings

| Finding | Source at the reviewed revision | Result |
| --- | --- | --- |
| Browser target exists | `game/export_presets.cfg` Web preset; `tools/build_all_releases.sh` web export | PASS for configuration only |
| Launched game lacks integrated mode/session/explore/replay flow | `game/project.godot` starts `main.tscn`; `main.gd` initializes placement only; `main_menu.gd` signals have no application consumer | FAIL for complete game flow |
| Online transport absent | `room_authority.gd` and `network_protocol.gd` are in-process models; no WebSocket listener/client or server entry point | FAIL for online play |
| Room player count and restart durability incomplete | Session setup occurs at second join; third/fourth players are not added to that session; state/deduplication remain in memory | FAIL for four-player durable rooms |
| Real film output absent | `video_exporter.gd` desktop/absent-Android hooks return success; browser has no completed Blob/download callback; `replay_timeline.gd` submits a dummy solid-color frame | FAIL for film delivery |
| Browser UI and physical-device gates | Not independently executed in this review | NOT RUN |

An additional read-only handoff review identified static runner defects: `env_check.py` contains macOS-specific paths/version assumptions and unconditional Desktop/Web READY text; `verify_clean_checkout.sh` checks exported artifacts before its build step; `test_smoke.py` expects `LittleBricks.zip` while the build script writes `LittleBricks-macOS.zip`. These require repair and clean-checkout reproduction in LB-033. They were found by source inspection, not by claiming a successful full build pipeline.

Legacy LB-001..LB-032 evidence files are historical implementation reports. Their existence and PASS labels cannot close the gates above. Preserve them for traceability and supersede inaccurate conclusions with fresh evidence.

## Subsequent user playtest

The user supplied four screenshots of a locally served browser build at `localhost:8080`. The user could place bricks, but reported forced stacking after the first piece, no discoverable free camera movement, a 1x4 offset between 2x4 stud rows, and too little visible part variety. Screenshots show `Plate` values 9, 12 and 14, floating-placement messages, and six tray choices.

This is user-provided evidence of a local browser launch and partial building interaction. Exact build SHA and browser/device versions were not captured, so it is not a formal browser matrix pass. No public game URL is established. Raw screenshots are not committed because unrelated browser content is visible.

Source inspection confirms unconditional layer increment in `main.gd`, rounded connector coordinates versus fractional rendered coordinates in `placement_rules.gd`/the manifest, and missing pan/touch-orbit paths in `camera_controller.gd`. Browser-specific right-drag/trackpad behavior still needs reproduction. [PLACEMENT_AND_CATALOG.md](../PLACEMENT_AND_CATALOG.md) specifies corrective work and PC-01..PC-10 acceptance scenarios.

## Current conclusion

The project contains a browser-capable placement prototype and useful separately tested modules. Full game integration, reliable placement/camera behavior, genuine networking/video export, sensory polish, a larger verified catalogue and release verification remain open. Physical-device and store-access limitations do not explain the missing application code.
