# Google Play Store Declarations & Compliance Guide (LB-030)

This document provides official metadata, safety declarations, content ratings, and user-generated content (UGC) compliance procedures for releasing LittleBricks on the Google Play Store.

---

## 1. Store Listing Metadata

- **App Title**: LittleBricks: Cooperative Brick Building
- **Short Description** (<= 80 chars):
  Cozy cooperative brick building with friends, exploration, and replay films!
- **Category**: Games > Casual / Puzzle / Simulation
- **Default Language**: English (United States) (en-US)

### Full Description
```
Welcome to LittleBricks, the cozy, open-source cooperative brick building game!

Whether playing solo or taking turns with family and friends, LittleBricks brings the joyful tactile magic of interlocking bricks to your screen.

FEATURES:
• ONE-BRICK TURNS: Take turns placing one brick at a time on a shared 32×32 tabletop.
• COOPERATIVE PACING: Balanced themed bags guarantee you always have structural bricks when you need them.
• COZY THEMES: Build coastal wharves with the "Cozy Coastal Harbour" theme, or woodland lodges with the "Rustic Forest Cabin" theme.
• EXPLORE YOUR CREATIONS: When your masterpiece is finished, shrink down to miniature toy scale! Walk through doors, peek through windows, and explore your build in 1st or 3rd person POV.
• CONSTRUCTION FILMS: Relive your building journey! Watch animated stop-motion replays that skip human pauses, bounce bricks into place, and finish with a cinematic 360° reveal. Export and share your builds with friends.
• LOCAL & ONLINE MODES: Play offline in Solo Creative mode, pass the device around in Pass-and-Play mode, or host private 2–4 player online rooms with simple room codes.
• ACCESSIBLE & FAMILY-FRIENDLY: Full support for high-contrast visual cues, reduced-motion options, and relaxed timer-free play. No ads, no tracking, and no paywalls.
```

---

## 2. Graphic Asset Requirements

| Asset | Dimensions | Format | Notes |
| --- | --- | --- | --- |
| **App Icon** | 512 × 512 px | PNG (32-bit) | Clean logo on vibrant background (`game/icon.svg`). |
| **Feature Graphic** | 1024 × 500 px | JPEG or PNG (24-bit) | Warm isometric render of harbour and cabin builds with toy explorer. |
| **Phone Screenshots** | Min 1080 × 1920 px (16:9) | PNG / JPEG | At least 4 screenshots: Tabletop Building, Ghost Placement, Toy Explorer POV, Replay Film Reveal. |
| **Tablet Screenshots** | 7" & 10" Aspect Ratios | PNG / JPEG | Showing tablet-optimized layout and camera views. |

---

## 3. Google Play Data Safety Declaration

LittleBricks is designed with privacy-by-design principles:

| Question | LittleBricks Declaration | Rationale |
| --- | --- | --- |
| **Does your app collect or share user data?** | **No data collected** | The app collects zero personal data, device identifiers, or analytics. |
| **Is data encrypted in transit?** | **Yes** | Online multiplayer uses secure WebSockets (WSS/TLS). |
| **Can users request data deletion?** | **Yes / Not applicable** | No user accounts or persistent profiles exist; game saves are stored strictly locally on the user's device (`user://saves/`). |
| **Does the app contain advertising or tracking SDKs?** | **No** | Zero ad networks, tracking SDKs, or third-party analytics libraries. |
| **Is this app intended for children?** | **Yes (Families Policy Compliant)** | Designed for all ages with no behavioral tracking or data collection. |

---

## 4. Content Rating & Audience (IARC Questionnaire)

- **IARC Rating**: Everyone / PEGI 3 / USK 0
- **Violence**: None (no combat, no blood, no depictions of violence).
- **Fear / Horror**: None.
- **Sexuality / Nudity**: None.
- **Simulated Gambling**: None.
- **Language**: Clean (no profanity).
- **Controlled Substances**: None.
- **User Interactions**: "Users Interact" marked due to optional online private multiplayer rooms.

---

## 5. User-Generated Content (UGC) Policy & Moderation Flow

Google Play Families and UGC policies require robust protection against offensive content:

1. **Private Rooms Only**:
   - There is no public room browser or unmoderated public lobby.
   - Rooms are joined exclusively via random, unguessable 6-character room codes (`NetworkProtocol.generate_room_code()`).
2. **In-Session Reporting & Blocking**:
   - Any player can flag an abusive room member via the in-game player list.
   - Calling `RoomAuthority.report_user(reporting_token, target_token, reason)` immediately logs the incident and evicts/blocks the offending token from reconnecting.
3. **No Unmoderated Text Chat**:
   - Multiplayer communication is non-textual and turn-based (placing bricks on a shared lattice).
   - Character name strings are sanitized against length and basic format rules.

---

## 6. Permissions Declarations

In `game/export_presets.cfg`, two standard permissions are declared:

- `android.permission.INTERNET`: Required for WebSocket connections to user-hosted or dedicated online multiplayer rooms.
- `android.permission.VIBRATE`: Required for optional tactile haptic pulses on accepted brick placement.
- **Excluded Permissions**:
  - `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE`: Not requested; uses standard scoped internal storage (`user://`).
  - `CAMERA`, `RECORD_AUDIO`, `ACCESS_FINE_LOCATION`: Not requested.
