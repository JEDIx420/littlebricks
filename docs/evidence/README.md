# Verification evidence

No game implementation or device test has been completed in the initial documentation bootstrap.

For each meaningful gate, add a compact Markdown report named with the task ID and a descriptive suffix. Record:

- Task, requirement, tested commit, and any working-tree changes.
- Engine/tool versions, OS, physical device or emulator, browser where applicable.
- Exact commands or reproducible interaction steps.
- Expected behavior, observed outcome, and `passed` / `failed` / `blocked` / `not_run`.
- Links to relevant logs, screenshots, profiler captures, replay files, or exported clips.
- Findings, fixes, rerun results, and verifier identity/role.

Keep sensitive data out of evidence. Keep large binaries/recordings out of Git and link durable release/artifact locations with hashes where appropriate. A screenshot alone does not prove timing, input usability, recovery, or video compatibility. Do not mark a blocked check as passing.

The coordinator links reports from [STATUS](../STATUS.md); detailed gates are in [VALIDATION](../VALIDATION.md).
