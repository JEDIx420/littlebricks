# Skills, plugins, and tools

Checked against upstream documentation on **2026-11-11**. Availability depends on the installed Antigravity version, account, OS, and granted access. Repository configuration is not evidence that a tool is installed or connected.

## Capability discovery comes first

During M0, inventory the available agent skills, plugins, MCP servers, orchestration commands, Godot version/export templates, browser tools, Blender, Java/Android SDK, and physical devices. Verify relevant capabilities with a harmless operation and record observed versions and gaps in [STATUS](STATUS.md).

Use installed, task-relevant capabilities before adding dependencies. Read the exact upstream setup instructions and inspect the configured tool schema. Pin selected packages to a reviewed version/commit and record their licences. Keep local credentials/configuration outside the committed project. Do not paste fabricated MCP settings, tool names, model IDs, or access tokens into the repo.

## Repository skills

| Skill | Use it for |
| --- | --- |
| [littlebricks-build](../.agents/skills/littlebricks-build/SKILL.md) | Own the complete implementation loop, task selection, worker coordination, integration, and resume checkpoints |
| [littlebricks-assets](../.agents/skills/littlebricks-assets/SKILL.md) | Select licensed content, normalize geometry, define connectors/colliders, and validate packs |
| [littlebricks-verify](../.agents/skills/littlebricks-verify/SKILL.md) | Independently test rules, gameplay, visuals, device behavior, multiplayer, and evidence |
| [littlebricks-release](../.agents/skills/littlebricks-release/SKILL.md) | Prepare reproducible builds, release notes, exports, store declarations, and remaining publication actions |

They are project-local Antigravity skills. Optional `agents/openai.yaml` files provide UI metadata for compatible OpenAI tooling; Antigravity's skill contract is `SKILL.md`. The bootstrap does not install personal/global skills or third-party plugins on the user's computer.

## Relevant integrations

| Capability | Candidate / primary source | Concrete use | Fallback |
| --- | --- | --- | --- |
| Repository operations | [GitHub's official MCP server](https://github.com/github/github-mcp-server), existing GitHub connector, or authenticated `git`/`gh` | Read exact diffs, branches, issues and commits; publish authorized changes | Native git/CLI; preserve pending local work if remote access is unavailable |
| Godot interaction | [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp), community MCP integration | Launch/run a project and collect debug output; inspect actual available scene tools | Godot editor, CLI and scripted import/tests |
| Browser inspection | Antigravity's [browser capability](https://antigravity.google/docs/browser) or an already approved browser-testing integration | Test the real web export, interactions, console errors and captures | Manual browser inspection plus automated browser tests once implemented |
| Android tooling | [Android platform tools](https://developer.android.com/tools/releases/platform-tools), SDK and device profiler | Install builds, collect logs, exercise lifecycle/reconnect, profile and verify exported clips | Emulator for partial coverage; explicitly leave physical-device gates open |
| Asset preparation | Blender plus [community MCP for Blender](https://github.com/ahujasid/mcp-for-blender), if useful | Normalize mesh scale/pivots, prepare original art and optimize export | Blender UI or a pinned offline Python pipeline |
| Development skills | [obra/superpowers](https://github.com/obra/superpowers), if already installed or deliberately selected | Relevant debugging, implementation, review and verification techniques | Repository delivery loop and official engine docs |
| LDraw authoring | [anteloc/ldraw-nova](https://github.com/anteloc/ldraw-nova) | Optional theme/starter-model experiments and LDraw/GLB authoring | Curated Kenney/original assets and direct tooling |

Godot MCP and MCP for Blender are community integrations, not official engine services. Treat them as optional development tools. Review their execution surface, pin their code and check compatibility before use. Do not enable a broad plugin bundle just to complete a small task, and do not copy external instructions that conflict with the user's scope or project rules.

For Superpowers, inspect the installed revision and its actual skill names. Use relevant debugging/review practices; do not start a second competing backlog, redo settled product discovery, or impose an unnecessary approval loop. Missing optional skills must not prevent implementation.

## Orchestration selection

See [ANTIGRAVITY](ANTIGRAVITY.md) for the supported setup. Use one coordinator and one main orchestration mode. Prefer discovered `/teamwork` for a full milestone delivery session; use `/swarm` as an alternative when its shared coordination model is useful, and `/boost` for bounded difficult investigations. If unavailable, ordinary subagents or sequential execution must preserve the same task/evidence loop.

Tool discovery and actual smoke tests decide what can be used. Documentation about a paid command does not establish that the user's account has it. Never change billing, permissions or global agent settings just to imitate a desired orchestration feature.

## Authoritative technical references

- [Godot stable documentation](https://docs.godotengine.org/en/stable/)
- [Godot web export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
- [Godot WebSockets](https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html)
- [Godot Android plugins](https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html)
- [Android MediaCodec](https://developer.android.com/reference/android/media/MediaCodec) and [MediaMuxer](https://developer.android.com/reference/android/media/MediaMuxer)
- [Antigravity customization discovery](https://antigravity.google/docs/customization-discovery/), [skills](https://antigravity.google/docs/skills), [subagents](https://antigravity.google/docs/subagents), and [plugins](https://antigravity.google/docs/plugins)

Pin actual development dependencies during M0; the bootstrap deliberately makes no claims about installed binaries. Keep the normal game offline-capable without agent tooling, MCP services, Python authoring tools, or paid AI keys on players' devices.
