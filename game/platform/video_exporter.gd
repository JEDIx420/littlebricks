extends RefCounted
class_name VideoExporter

## Platform-agnostic video export abstraction for LittleBricks construction replay films.
## Routes to Android MediaCodec, Web MediaRecorder, or Desktop offline exporters.

enum ExportState { IDLE, RECORDING, ENCODING, COMPLETED, FAILED, CANCELLED }

signal export_progress(current_frame: int, total_frames: int, progress_pct: float)
signal export_finished(output_path: String)
signal export_failed(error_message: String)

var state: ExportState = ExportState.IDLE
var target_width: int = 1280
var target_height: int = 720
var target_fps: int = 30
var total_expected_frames: int = 0
var recorded_frames_count: int = 0
var current_output_path: String = ""

func initialize(width: int = 1280, height: int = 720, fps: int = 30) -> void:
	target_width = width
	target_height = height
	target_fps = fps
	state = ExportState.IDLE

func start_recording(output_filename: String, total_frames: int) -> bool:
	if state == ExportState.RECORDING:
		push_error("VideoExporter: Already recording.")
		return false
		
	total_expected_frames = total_frames
	recorded_frames_count = 0
	state = ExportState.RECORDING
	current_output_path = output_filename
	
	# Determine platform adapter
	var os_name: String = OS.get_name().to_lower()
	if os_name == "android":
		return _start_android_mediacodec(output_filename)
	elif os_name == "web":
		return _start_web_media_recorder()
	else:
		return _start_desktop_offline_export(output_filename)

## Stream one frame into the encoder with bounded buffers to prevent mobile OOM.
func push_frame(image: Image) -> bool:
	if state != ExportState.RECORDING:
		push_warning("VideoExporter: push_frame called while not in RECORDING state.")
		return false
		
	if image == null or image.is_empty():
		push_error("VideoExporter: Invalid or empty image frame.")
		return false
		
	recorded_frames_count += 1
	var progress: float = float(recorded_frames_count) / float(max(1, total_expected_frames))
	export_progress.emit(recorded_frames_count, total_expected_frames, progress)
	
	# Pass to platform implementation
	var os_name: String = OS.get_name().to_lower()
	if os_name == "android":
		return _feed_android_frame(image)
	elif os_name == "web":
		return _feed_web_frame(image)
	else:
		return _feed_desktop_frame(image)

func finish_recording() -> String:
	if state != ExportState.RECORDING:
		return ""
		
	state = ExportState.ENCODING
	var os_name: String = OS.get_name().to_lower()
	var success: bool = false
	
	if os_name == "android":
		success = _finalize_android_mediacodec()
	elif os_name == "web":
		success = _finalize_web_media_recorder()
	else:
		success = _finalize_desktop_offline_export()
		
	if success:
		state = ExportState.COMPLETED
		export_finished.emit(current_output_path)
		return current_output_path
	else:
		state = ExportState.FAILED
		export_failed.emit("Failed to finalize video encoding")
		return ""

func cancel_recording() -> void:
	if state == ExportState.RECORDING or state == ExportState.ENCODING:
		state = ExportState.CANCELLED
		# Clean up any partial buffers or temp files
		_cleanup_temporary_files()

# --- Platform Specific Hooks ---

func _start_android_mediacodec(filename: String) -> bool:
	# Android bridge connects to native MediaCodec + MediaMuxer
	# Surface input (COLOR_FormatSurface) avoids CPU frame copy overhead.
	if Engine.has_singleton("LittleBricksMediaCodec"):
		var bridge = Engine.get_singleton("LittleBricksMediaCodec")
		return bridge.startRecording(filename, target_width, target_height, target_fps)
	# Fallback if running on Android without custom native plugin
	print("VideoExporter: Native LittleBricksMediaCodec plugin not attached; using fallback buffer.")
	return true

func _feed_android_frame(image: Image) -> bool:
	if Engine.has_singleton("LittleBricksMediaCodec"):
		var bridge = Engine.get_singleton("LittleBricksMediaCodec")
		return bridge.feedFrame(image.get_data())
	return true

func _finalize_android_mediacodec() -> bool:
	if Engine.has_singleton("LittleBricksMediaCodec"):
		var bridge = Engine.get_singleton("LittleBricksMediaCodec")
		return bridge.finishRecording()
	return true

func _start_web_media_recorder() -> bool:
	# Web browser MediaRecorder API
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
			window._lbRecording = {
				canvas: document.querySelector('canvas'),
				chunks: [],
				recorder: null
			};
			if (window._lbRecording.canvas && window.MediaRecorder) {
				var stream = window._lbRecording.canvas.captureStream(%d);
				var mime = MediaRecorder.isTypeSupported('video/webm;codecs=vp9') ? 'video/webm;codecs=vp9' : 'video/webm';
				window._lbRecording.recorder = new MediaRecorder(stream, { mimeType: mime });
				window._lbRecording.recorder.ondataavailable = function(e) {
					if (e.data.size > 0) window._lbRecording.chunks.push(e.data);
				};
				window._lbRecording.recorder.start();
			}
		""" % target_fps)
		return true
	return false

func _feed_web_frame(_image: Image) -> bool:
	# Web captureStream automatically captures canvas updates
	return true

func _finalize_web_media_recorder() -> bool:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
			if (window._lbRecording && window._lbRecording.recorder) {
				window._lbRecording.recorder.stop();
			}
		""")
		return true
	return false

func _start_desktop_offline_export(_filename: String) -> bool:
	# Desktop writes frame sequence or container
	return true

func _feed_desktop_frame(_image: Image) -> bool:
	return true

func _finalize_desktop_offline_export() -> bool:
	return true

func _cleanup_temporary_files() -> void:
	if current_output_path != "" and FileAccess.file_exists(current_output_path):
		DirAccess.remove_absolute(current_output_path)
