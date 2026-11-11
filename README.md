# LittleBricks

**Build together, one brick at a time. Then step inside.**

LittleBricks is an open-source tabletop brick game being built with Godot for browsers, Android and desktop. The intended experience combines solo building, local pass-and-play and private online turns, then miniature exploration and a shareable construction film.

## Current status

**Development prototype — recovery work is planned.** The browser placement scene runs locally, and useful gameplay modules exist. Full game flow, reliable stud alignment/height/camera controls, actual online networking and real video output still need integration or repair. Earlier “all milestones complete” release claims have been superseded by the [independent review](docs/evidence/2026-11-11-independent-review.md).

The latest plan also adds inviting opening screens, cozy music, satisfying brick clicks, supported haptics, finished-build lighting and a much larger verified parts library. [STATUS](docs/STATUS.md) is the progress source of truth. No public play URL or complete release is verified here yet.

## Continue with Antigravity

Open the repository root and use the `littlebricks-build` skill. Read [AGENTS.md](AGENTS.md), [STATUS](docs/STATUS.md) and the [active recovery plan](docs/RECOVERY_PLAN.md). Start at **LB-033**, then prioritize **LB-054, LB-053 and LB-055** using their dependencies. The coordinator should implement, inspect, independently verify, repair and continue through the full scope.

[Antigravity setup and launch prompt](docs/ANTIGRAVITY.md) · [Skills and plugins](docs/TOOLCHAIN.md)

## Project documents

| Document | Purpose |
| --- | --- |
| [Recovery plan](docs/RECOVERY_PLAN.md) | 24 next tasks, LB-033–LB-056, ownership, dependencies and acceptance |
| [Placement and catalogue](docs/PLACEMENT_AND_CATALOG.md) | Baseplate return, exact stud alignment, camera controls, regression fixtures and staged library growth |
| [Player experience](docs/EXPERIENCE_DESIGN.md) | Welcome → mode → setup, onboarding, connected flows and finished-build presentation |
| [Audio and visuals](docs/AUDIO_VISUAL_SPEC.md) | Music, brick sounds, supported haptics, lighting, quality profiles and film audio |
| [Original project plan](docs/PROJECT_PLAN.md) | M0–M7 requirements that remain binding |
| [Game design](docs/GAME_DESIGN.md) / [Architecture](docs/ARCHITECTURE.md) | Gameplay and system contracts |
| [Validation](docs/VALIDATION.md) / [Assets](docs/ASSETS.md) | Evidence requirements and content provenance |
| [Build instructions](docs/BUILD.md) | Existing development/export entry points; revalidate the toolchain before using release claims |

## Technical direction

Godot with GDScript and Compatibility rendering; shared deterministic rules; an authoritative WebSocket room service; versioned saves, parts and construction events. LDraw/Nova is optional authoring tooling. The web export is part of the plan; generated bundles must be served over HTTP(S) and tested in an actual browser. Native and browser support are verified separately.

The catalogue will grow in audited waves to at least **120 distinct buildable shapes**, with 150 as a stretch target. Solo Free Build exposes the supported library; turn-based modes retain six-piece hands drawn from enabled theme packs. Counts are targets until verified.

Project-authored code and documentation use the [MIT licence](LICENSE); assets and dependencies retain their recorded licences. See [Contributing](CONTRIBUTING.md) and [Attribution](ATTRIBUTION.md). LittleBricks uses its own branding and original character designs and is not affiliated with the LEGO Group.
