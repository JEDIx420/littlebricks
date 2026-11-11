# Contributing to LittleBricks

Read [AGENTS.md](AGENTS.md) and [the project plan](docs/PROJECT_PLAN.md). The repository is initially a planning and agent bootstrap; implementation work starts at M0.

## Work on a coherent task

Use an existing `LB-###` task or define a bounded task with acceptance checks. Coordinate ownership through [STATUS](docs/STATUS.md). Keep changes focused, preserve other contributors' work, and let one integrator own shared schemas and configuration.

Run the relevant local checks described in [VALIDATION](docs/VALIDATION.md). Include the commands, environment, results, and any unrun device checks in the handoff. Visual/interaction changes need inspection of the running game. A new dependency must have a purpose, a pinned version, and compatible licence terms.

## Review and integration

A change should explain the user-visible problem, resulting behavior, verification, and remaining limitations. An independent reviewer should reproduce important checks. Fix material findings before integrating. Follow repository branch protections and use normal fast-forward/merge operations; do not rewrite shared history.

The coordinator updates STATUS after integration. Large builds and recordings belong in release/artifact storage with stable links; concise reproducible evidence belongs in `docs/evidence/`.

## Assets and licences

Follow [ASSETS](docs/ASSETS.md). Contributions must identify their source and redistribution terms. Project-authored code and docs are MIT-licensed. Third-party art, fonts, audio, libraries, and converted LDraw data retain their original terms; the root licence does not relicense them.

## Reporting issues

Provide the build/commit, platform/device, reproduction steps, expected and actual behavior, and a minimal save/replay when possible. Remove secrets and personal information. Avoid claiming a platform is supported based solely on an export completing.
