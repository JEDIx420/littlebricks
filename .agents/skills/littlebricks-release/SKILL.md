---
name: littlebricks-release
description: Prepare a LittleBricks release candidate and finish release-readiness work. Use for Android AAB and desktop/web/server packaging, clean-checkout reproducibility, credits and store materials, final verification, or an explicitly authorized publication/deployment.
---

# Prepare a LittleBricks release

Read [AGENTS.md](../../../AGENTS.md), [STATUS](../../../docs/STATUS.md), M7 in [PROJECT_PLAN](../../../docs/PROJECT_PLAN.md), [VALIDATION](../../../docs/VALIDATION.md), and [ASSETS](../../../docs/ASSETS.md). Confirm the actual commit, completed scope, blockers and publication authorization.

## Build a concrete candidate

1. Reproduce the documented setup from a clean checkout with pinned engine/export templates and dependencies.
2. Build the required Android, desktop, browser and server artifacts using the actual project commands. Record versions, hashes and artifact locations.
3. Keep signing keys and credentials in authorized local/secret storage. If unavailable, complete development builds and other preparation while identifying the exact signed-artifact blocker.
4. Run full solo, local-turn and private-online journeys: build, finish, explore, save/reopen, replay/export and share. Exercise recovery and update/install behavior.
5. Independently verify the declared support/performance matrix and known limits. Obtain a verifier report; don't convert unrun tests into passes.
6. Generate notices/credits from the asset/dependency records and confirm that the intended distributed content matches them.

## Prepare store and operational material

Read current official Google Play requirements at submission time. Confirm target SDK, developer-account/testing requirements, content rating, actual intended audience, privacy/Data safety inputs and appropriate shared-content controls. Prepare accurate screenshots, description, support contact, release notes and known limitations from the real build.

Document how to run, back up, restore and update the multiplayer server. Keep offline play useful independently. Prepare rollback/version compatibility checks before an authorized deployment.

## Publish within actual authority

Complete all reviewable preparation before requesting a missing credential or final publication action. Reuse explicit authorization already in the session. Do not assume that a request to initialize the repository authorized a Play Store submission, spending, or a production deployment.

If publication is authorized and the necessary access is available, execute it and verify the resulting version/status/URL. Otherwise report the prepared candidate and precise remaining action. Never call a submitted or pending build approved, or a release candidate publicly released.

Update STATUS and the evidence index with the exact release state, artifacts and open dependencies. Store approval and uninterrupted agent runtime cannot be guaranteed by this skill.
