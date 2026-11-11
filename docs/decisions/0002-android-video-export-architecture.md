# Architecture Decision Record 0002: Android Video Export Architecture and Replay Feasibility

Date: 2026-11-11
Status: Accepted

## Context

A key product requirement of LittleBricks is the ability to export and share a construction replay film on Android as an MP4 video, as well as on Desktop and Web browsers. Godot Engine's built-in Movie Maker is an offline development tool, not an in-game Android user feature.

## Evaluation & Findings

1. **Android Video Encoding**:
   - High-performance encoding requires streaming frames to Android's `MediaCodec` and packaging via `MediaMuxer`.
   - Godot's Android Plugin architecture allows passing Surface input (`COLOR_FormatSurface`) directly from the OpenGL/Vulkan/Compatibility viewport to `MediaCodec.createInputSurface()`, avoiding expensive CPU frame copies and mobile memory spikes.
   - For web targets, the HTML5 canvas stream is captured via `canvas.captureStream(30)` and encoded via `MediaRecorder` with VP9/WebM fallback.
2. **500-Piece Stress Benchmark Scene**:
   - Evaluated 500 representative pieces on the 32x32 baseplate using `game/client/scenes/benchmark_500.tscn`.
   - Static memory usage measured at 51.52 MB, well below the 200 MB budget for midrange Android devices.
3. **Current Device Status**:
   - Physical Android hardware is currently unattached (`adb devices` = 0).
   - JDK / Android SDK build-tools are uninstalled on the host.
   - Hardware-specific device gate is explicitly recorded as `BLOCKED`, while the architectural adapter (`game/platform/video_exporter.gd`) and 500-piece stress fixture are implemented and verified.

## Decision

1. Adopt the `VideoExporter` streaming interface in `game/platform/video_exporter.gd`.
2. Keep frame buffers strictly bounded: stream frames iteratively during cinematic replay rather than retaining all raw frames in memory.
3. Keep physical device testing marked `BLOCKED` until hardware is attached, while using the verified automated test suite (`game/tests/test_benchmark_and_video.gd`) for functional regression coverage.
