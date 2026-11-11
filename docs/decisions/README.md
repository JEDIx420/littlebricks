# Architecture decisions

Use short numbered Markdown records for material changes. Include context, options, decision, consequences, evidence, and date. Record routine implementation details in their module docs rather than creating unnecessary decisions.

## Initial direction - 2026-11-11

- Product: LittleBricks; one-brick cooperative turns plus offline solo, explorer POV, and construction films.
- Engine: Godot 4 + GDScript. Pin the exact stable engine and export templates in M0 after a smoke test.
- Rendering: Compatibility as the first shared Android/desktop/web baseline; measure each target separately.
- Networking: headless Godot authority over WSS, sharing deterministic placement rules with clients.
- Content: curated, versioned, licensed parts; original branding and toy character; LDraw/Nova optional in authoring.
- Persistence: versioned snapshots and explicit accepted events. Crash durability and migration are required implementation work.
- Android video: native encoder/muxer adapter; validate feasibility early. Built-in movie rendering is not a turnkey in-app share feature.
- Licensing: MIT for independently authored code/docs; preserve third-party licences separately.

These are engineering defaults for implementation, not claims of benchmarked performance or a completed product. See [ARCHITECTURE](../ARCHITECTURE.md) for contracts and [VALIDATION](../VALIDATION.md) for evidence gates.
