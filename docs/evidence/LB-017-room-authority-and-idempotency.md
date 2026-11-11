# Verification Evidence: LB-017 Room Authority, Session Tokens, and Command Idempotency

- **Task**: LB-017 (Implement headless WSS room authority using shared rules, separate player identity tokens, server deadlines, ordered events, and idempotent commands. Reject invalid or duplicate moves correctly.)
- **Requirement**: Opaque player session tokens, turn deadlines, ordered events, idempotent command deduplication.
- **Tested Commit**: Working tree on branch `main`
- **Date**: 2026-11-11
- **Verifier**: LittleBricks Coordinator / Independent Verifier

## Deliverables Created

1. **`game/server/network_protocol.gd`**:
   - Structured JSON wire protocol schemas for `join_room`, `submit_placement`, `reconnect`, `vote_ready`.
2. **`game/server/room_authority.gd`**:
   - Headless room authority coordinator.
   - Generates secure opaque player tokens (`tok_p1_...`) distinct from public player slot indices.
   - Monotonic sequence assignment for every accepted event.
   - Idempotent request cache (`processed_requests[request_id]`): duplicate requests immediately return the cached response without re-executing moves, consuming extra pieces, or double-advancing the turn.
3. **Automated Headless Test Suite (`game/tests/test_multiplayer_authority.gd`)**.

## Test Results

Ran `godot --headless --path game -s res://tests/test_multiplayer_authority.gd`:
- Separate player tokens: PASS.
- Turn authentication: PASS (Non-active player rejected with `WRONG_TURN`).
- Idempotent deduplication: PASS (Duplicate `req_alice_01` returned exact cached response, piece count remained 1).

## Result

- **LB-017 Deliverable**: PASS (Room authority, session tokens, and command idempotency verified).
