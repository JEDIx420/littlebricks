# Building LittleBricks with Antigravity

This repository supplies project instructions, reusable skills, specialist agent
definitions, and a persistent delivery plan. It does not start an agent service
or imply that the game is already implemented.

## Start a build

Open the repository root in Antigravity and invoke:

```text
/littlebricks-build
```

If the command is not listed, ask the agent to read
[the build skill](../.agents/skills/littlebricks-build/SKILL.md) and execute it.
For the current campaign, use the complete [next-agent launch prompt](NEXT_AGENT_PROMPT.md). Read [AGENTS.md](../AGENTS.md), [STATUS.md](STATUS.md), [PLAYTEST_REPAIR_PLAN.md](PLAYTEST_REPAIR_PLAN.md), its live/source reviews and [FAMILY_PLAY_EXPERIENCE.md](FAMILY_PLAY_EXPERIENCE.md) before dispatch. Begin LB-057 → LB-058 → LB-059 and prove actual pointer placement through AppRoot. Presentation, audio asset preparation and catalogue audit may proceed in parallel with clear ownership. Original M0–M7 and unmet earlier recovery requirements remain binding.

The RC2/all-recovery-tasks-complete claim is superseded by the actual browser playtest and current source review. Continue from the existing code and preserve useful modules. The active campaign includes LB-057–LB-067: correct input and session policy, deliver the family presentation and audible sound design, replace placeholder shapes, connect gallery/online/explore/replay routes, and verify actual native/browser outcomes. Use one coordinator and one task ledger.

At startup, inspect the actual environment: Godot and export templates, Android
tools/devices, repository state, available skills, custom agents, plugins, and
authenticated MCP tools. Record useful capabilities and concrete gaps in the
status file. Do not assume an integration is installed because a document names
it. Follow [TOOLCHAIN.md](TOOLCHAIN.md) for tool selection.

## Check discovery

The current Antigravity convention is `.agents/` at the workspace root. Root
`AGENTS.md` and `GEMINI.md` also provide project context. Skills live one folder
below `.agents/skills/`; custom agents live directly in `.agents/agents/`.
Antigravity's discovery and skill documentation describes these locations. [1, 2]

In supported App versions, inspect the project's Customizations panel. In the
CLI, `/skills` and `/agents` expose the discovered entries; `/skills reload`
refreshes skill commands after edits. Check paths and name conflicts if something
is missing. Older IDE surfaces may expose different controls; use their available
UI or the explicit-file fallback above. [1, 2]

The repository uses skills rather than legacy workflow files. Antigravity now
deprecates its older workflows and documents migration to skills. [3]

## Choose one coordinator

Use the main agent running `littlebricks-build` as the single owner of delivery
state, integration, and completion reporting. Discover native orchestration in
the current Antigravity version and subscription before selecting it.

| Available capability | Appropriate use |
| --- | --- |
| `/teamwork` | Prefer for a supported long-running implementation campaign with milestone decomposition and independent checks. Supply the repository plan as the scope. |
| `/swarm` | Alternative for a bounded batch of independent tasks with explicit ownership and one verifier. |
| Ordinary custom subagents | Delegate specialists directly when native orchestration is unavailable or unnecessary. |
| `/boost` | Use selectively for a difficult geometry, concurrency, recovery, or encoding problem after collecting a concrete reproduction. |
| One agent only | Execute the same tasks sequentially, with separate implementation and verification passes. |

The commands and their availability are described in the current official
documentation. They are optional execution mechanisms, not dependencies of the
game. Do not invoke all orchestrators together, launch duplicate campaigns, or
assume that a version-specific command exists. [4, 5, 6]

If the native orchestrator requests scoping information, supply the decisions
already recorded in the repository. Resolve routine implementation choices from
the plan and evidence; ask Jay only when a material missing decision or required
permission genuinely blocks progress.

## Specialist responsibilities

| Agent | Primary responsibility |
| --- | --- |
| `littlebricks-gameplay` | Deterministic placement rules, inventories, turns, saves, and touch/desktop building interaction. |
| `littlebricks-worlds` | Audited assets, table presentation, part metadata, toy-scale exploration, cameras, audio, and visual polish. |
| `littlebricks-platform` | Authoritative networking, recovery, Android/web/desktop exports, native video encoding, and reproducible packaging. |
| `littlebricks-verifier` | Independent requirement review, reproductions, targeted automated checks, device evidence, and release-gate assessment. |

Each definition uses documented core tool names and inherits the environment's
model and permission settings. Confirm tool availability at invocation. If a
runtime rejects a tool name, inspect its actual schema and use a supported
configuration; do not widen permissions to bypass the failure. MCP integrations
remain subject to actual installation, authentication, and tool exposure. [7]

The shipped roles declare a small local tool set. Let the coordinator perform
authenticated plugin/MCP work, or delegate it using a verified runtime
configuration that exposes the required tools within existing permissions. These
agent files do not install external integrations or grant account access.

## Dispatch, integrate, verify, continue

Give every worker a self-contained assignment containing the task ID, relevant
requirements, exact files or modules it owns, interface contracts, dependencies,
acceptance criteria, available tools, and required evidence. Do not rely on the
worker having the coordinator's conversation history.

Use isolated worktrees where supported, or disjoint write paths in a shared
checkout. Only the coordinator changes shared status, resolves cross-module
contracts, integrates branches, or publishes the combined result. Keep
`project.godot`, shared schemas, dependency versions, and export settings under a
single declared owner per batch.

For each dependency-ready task:

1. Implement the smallest complete behavior that meets its acceptance criteria.
2. Run meaningful local checks and collect evidence for the exact revision.
3. Have the verifier inspect the implementation and challenge failure cases.
4. Repair material findings; rerun affected checks until they pass or a real
   blocker is isolated.
5. Integrate reviewed changes, update the status and next task, then continue.

Do not stop because one agent produced a plausible demo. Do not turn unavailable
phone tests, browser checks, signing, or store review into a green result. Finish
other independent work while recording precisely what remains unverified.
Avoid repeated tests that address no remaining risk.

## Skills and plugins

Read the relevant repository skill before the task: `littlebricks-build` for
coordination, `littlebricks-assets` for content, `littlebricks-verify` for evidence,
and `littlebricks-release` for packaging. Use available specialist skills and
plugins when they materially help: Godot inspection, authenticated GitHub work,
browser interaction, Blender asset preparation, or Android device tooling.

Plugins can bundle skills, agents, rules, and MCP connections; their presence in
a marketplace does not provide credentials or install them into this machine.
Read their instructions and inspect provenance and permissions before adopting
them. Prefer a working local CLI when an optional plugin is absent. Do not invent
package identifiers, execute unreviewed installation commands, or commit secrets.
See the official plugin documentation and [TOOLCHAIN.md](TOOLCHAIN.md). [8]

## Durable progress and completion

Keep [STATUS.md](STATUS.md) current with task states, owners, commit references,
evidence, blockers, and the exact next action. Before a context limit, session
end, or interruption, leave a checkpoint another agent can resume. On resumption,
inspect the actual checkout and completed evidence before continuing. Instruction
files cannot guarantee unlimited autonomous runtime; they make continuation
explicit and recoverable.

The finish condition is the entire agreed M0-M7 scope with evidence-backed gates,
or a candid release-candidate handoff that names external blockers. Respect
existing authorization for edits, tests, commits, and pushes. Request missing
authorization only when needed for actions such as public deployment, Play Store
submission, purchases, or messages to others. Prepare a concrete reviewable
result before asking, and never repeat an approval already granted.

## Official references

Checked 2026-11-11. Runtime discovery takes precedence over stale command names.

1. [Customization discovery](https://antigravity.google/docs/customization-discovery/)
2. [Agent skills](https://antigravity.google/docs/skills)
3. [Legacy workflows and migration notice](https://antigravity.google/docs/ide/workflows/)
4. [Teamwork](https://antigravity.google/docs/teamwork/)
5. [Swarm](https://antigravity.google/docs/swarm/)
6. [Boost](https://antigravity.google/docs/boost/)
7. [Custom subagents and frontmatter](https://antigravity.google/docs/subagents)
8. [Plugins](https://antigravity.google/docs/plugins)
