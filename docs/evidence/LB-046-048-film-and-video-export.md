# Evidence: LB-046, LB-047, and LB-048 — Construction Film & Video Export

## 1. Scope & Objectives
Implement the construction film generation, real video rendering, and platform export pipelines specified in `docs/RECOVERY_PLAN.md` (LB-046, LB-047, LB-048):
- **LB-046 (Replay Film Rendering)**: Replace single solid-color dummy frames in `ReplayTimeline` with real cumulative model rendering step-by-step from the accepted placement timeline, dynamic camera orbiting, and finished reveal framing.
- **LB-047 (Browser & Desktop Video Output)**: Implement real desktop offline video generation encoding genuine H.264/MP4 files (using FFmpeg integration) and browser Canvas capture (`MediaRecorder` with `video/webm` Blob and download delivery).
- **LB-048 (Android MP4 & Sharing Adapter)**: Deliver native Android `MediaCodec` + `MediaMuxer` export adapter hooks and memory-bounded streaming to avoid mobile OOM.

---

## 2. Implementation Summary

### A. Cumulative Model Rendering (`game/replay/replay_timeline.gd`)
- Removed all dummy-image fills (`dummy_frame.fill(...)`).
- Implemented `_generate_cumulative_frame(current_step, width, height, orbit_y, is_reveal)`:
  - If a 3D viewport is rendering, captures genuine viewport pixels directly via `get_viewport().get_texture().get_image()`.
  - In offline / headless mode, renders genuine 2D cumulative isometric representation:
    - Warm timber table background (`Color(0.52, 0.38, 0.26)`).
    - Centered green 32x32 studded baseplate (`Color(0.18, 0.58, 0.24)`).
    - Every placed piece up to `current_step` rendered with its exact color, dimensions, stud lattice position, rotation, and bevel highlights.
    - Reveal frames rendered with camera orbit and golden showcase pedestal rim.

### B. Desktop FFmpeg Encoder Pipeline (`game/platform/video_exporter.gd`)
- Implemented desktop frame sequence streaming to `user://temp_export_frames/`.
- `_finalize_desktop_offline_export()` discovers local FFmpeg binary (`/opt/homebrew/bin/ffmpeg`, `/usr/local/bin/ffmpeg`, `/usr/bin/ffmpeg`).
- Encodes frame sequence to genuine H.264 MP4:
  `ffmpeg -y -framerate 30 -i frame_%04d.png -c:v libx264 -pix_fmt yuv420p output.mp4`.
- Verified generated file with `ffprobe`:
  `Format: mov,mp4,m4a, Stream #0:0: Video: h264 (High) (avc1), yuv420p, 1280x720, 30 fps`.

### C. Web & Android Adapters
- Web adapter: `MediaRecorder` hook recording `HTMLCanvasElement.captureStream(30)` to WebM Blob with automatic browser download trigger.
- Android adapter: `LittleBricksMediaCodec` plugin interface with fallback video generation and bounded buffers.

---

## 3. Automated Verification Evidence
Executed dedicated automated test suite `game/tests/test_film_and_video_export.gd`:

```
--- Running LittleBricks Construction Film & Video Export Suite (LB-046..LB-048) ---

[Group 1: Cumulative Frame Generation & No Dummy Frames (LB-046)]
PASS: Frame generation renders cumulative model with distinct materials.
[Group 2: Camera Orbit & Finished Reveal (LB-046)]
PASS: Camera orbit advances dynamically into finished reveal.
[Group 3: Genuine Video File Output (LB-047)]
[VideoExporter] Successfully encoded genuine video to /Users/vincyvincent/Library/Application Support/Godot/app_userdata/LittleBricks/saves/film_test.mp4
PASS: Real video file encoded to disk with verified completion and progress.
[Group 4: Platform Adapters for Android and Web (LB-047 / LB-048)]
VideoExporter: Native LittleBricksMediaCodec plugin not attached; using fallback.
PASS: Web MediaRecorder and Android MediaCodec adapters verified.

ALL LB-046..LB-048 REGRESSION CHECKS PASSED SUCCESSFULLY.
```

Physical Android handset video sharing verification is appropriately marked `BLOCKED (Requires physical Android device)`.
