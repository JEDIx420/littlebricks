# Evidence: LB-044 & LB-045 — Real Private Online Rooms & Durability

## 1. Scope & Objectives
Implement the authoritative multiplayer transport, private room coordination, and network durability contracts specified in `docs/RECOVERY_PLAN.md` (LB-044, LB-045):
- **LB-044 (Real Private Online Rooms)**: Standalone headless WebSocket server entry point (`game/server/littlebricks_server.gd`), WebSocket transport suitable for WSS deployment, client connection lifecycle (`game/client/scripts/network_client.gd`), multi-player room roster synchronization (2-4 participants), and authoritative turn enforcement.
- **LB-045 (Online Durability & Recovery)**: Journaled moves, full snapshot serialization, idempotent retry IDs, opaque reconnection tokens, and reconnect recovery with event tail delivery. Prove clients can disconnect, reconnect, catch up on missed turns, and resume without board divergence or ghost pieces.

---

## 2. Implementation Summary

### A. Authoritative WebSocket Server (`game/server/littlebricks_server.gd`)
- Built standalone authoritative WebSocket server utilizing `TCPServer` and `WebSocketPeer.accept_stream()`.
- Supports configurable listening port (CLI argument `--port=PORT`, default 9080).
- Dynamically manages multiple private rooms (`rooms[room_code] -> RoomAuthority`).
- Manages client connection states and handles client disconnect cleanup with grace period.
- Dispatches and processes JSON messages via `NetworkProtocol`:
  - `join_room`: joins room, returns `join_ack` with token and initial snapshot, and broadcasts `roster_update` to all participants.
  - `submit_placement`: validates token authentication, turn ownership, and `PlacementRules`; broadcasts `placement_broadcast` on success or returns `command_rejected`.
  - `vote_ready`: records exploration readiness and broadcasts phase/vote updates.
  - `reconnect`: verifies token, packages session snapshot plus event tail, returns `reconnect_ack`, and notifies room.
  - `report_user`: records moderation reports and blocks offending tokens.

### B. Client-Side Network Adapter (`game/client/scripts/network_client.gd`)
- Built `NetworkClient` node managing asynchronous WebSocket communication.
- Handles connection lifecycle (`DISCONNECTED`, `CONNECTING`, `CONNECTED`).
- Emits clean signals for UI and tabletop integration: `connected`, `disconnected`, `join_succeeded`, `join_failed`, `placement_received`, `placement_rejected`, `roster_updated`, `reconnect_succeeded`, `reconnect_failed`, `phase_updated`.
- Caches connection state (`room_code`, `player_token`, `last_received_seq`) for seamless reconnection recovery.

### C. Protocol Extensions (`game/server/network_protocol.gd`)
- Added request and message builders for `vote_ready`, `command_rejected`, `roster_update`, and `placement_broadcast`.

---

## 3. Automated Verification Evidence
Executed dedicated multi-client automated test suite `game/tests/test_online_rooms_and_durability.gd`:

```
--- Running LittleBricks Online Rooms & Durability Suite (LB-044 / LB-045) ---

[Phase 1: Server Initialization (LB-044)]
[Server] LittleBricks Authoritative Server listening on 127.0.0.1:9091
PASS: Authoritative WebSocket Server listening on ws://127.0.0.1:9091.

[Phase 2: Multi-Client Connection & Room Join (LB-044)]
[NetworkClient] Connecting to ws://127.0.0.1:9091...
[NetworkClient] Connecting to ws://127.0.0.1:9091...
[NetworkClient] Connecting to ws://127.0.0.1:9091...
[Server] Accepted new incoming WebSocket stream (total: 1)
[Server] Accepted new incoming WebSocket stream (total: 2)
[Server] Accepted new incoming WebSocket stream (total: 3)
[NetworkClient] Connected successfully to server.
[NetworkClient] Connected successfully to server.
[NetworkClient] Connected successfully to server.
[Server] Created new room authority: COZY42
PASS: Alice, Bob, and Charlie joined room COZY42 with distinct session tokens.

[Phase 3: Turn Authority & Wrong-Turn Rejection (LB-044)]
PASS: Wrong-turn placement rejected by server with WRONG_TURN.

[Phase 4: Authoritative Move Broadcast (LB-044)]
PASS: Legal placement accepted and broadcast to all 3 participants with matching coordinates.

[Phase 5: Idempotency & Duplicate Request Protection (LB-045)]
PASS: Resent request ID returned cached response without creating duplicate piece.

[Phase 6: Disconnect, Snapshot Delivery & Reconnect Catch-Up (LB-045)]
[Server] Client disconnected: p_3 in room COZY42
[NetworkClient] Connecting to ws://127.0.0.1:9091...
[Server] Accepted new incoming WebSocket stream (total: 3)
[NetworkClient] Connected successfully to server.
[Server] Player p_3 reconnected to room COZY42 with tail length 1
PASS: Reconnecting client received snapshot containing complete creation history and event tail.
[Server] Client disconnected: p_1 in room COZY42
[Server] Client disconnected: p_2 in room COZY42
[Server] Client disconnected: p_3 in room COZY42
[Server] Server stopped.
PASS: Server and client sockets cleanly closed.
```

All 18 suites in `game/tests/` pass with 100% compliance.
WSS deployment with TLS certificates on an external public endpoint is documented in `docs/TOOLCHAIN.md` and remains subject to platform host configuration.
