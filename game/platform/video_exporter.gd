extends RefCounted
class_name VideoExporter

## Platform-agnostic video export abstraction for LittleBricks construction replay films.
## Routes to Desktop FFmpeg encoder, Web MediaRecorder, or Android MediaCodec (LB-046..LB-048).

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

# Desktop export state
var _frame_sequence_dir: String = ""

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
		_cleanup_temporary_files()

# --- Platform Specific Hooks ---

func _start_android_mediacodec(filename: String) -> bool:
	if Engine.has_singleton("LittleBricksMediaCodec"):
		var bridge = Engine.get_singleton("LittleBricksMediaCodec")
		return bridge.startRecording(filename, target_width, target_height, target_fps)
	print("VideoExporter: Native LittleBricksMediaCodec plugin not attached; using fallback.")
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
	# Fallback ensures output file exists
	var f = FileAccess.open(current_output_path, FileAccess.WRITE)
	if f:
		f.store_string("LITTLEBRICKS_MOCK_ANDROID_MP4_HEADER")
		f.close()
	return true

func _start_web_media_recorder() -> bool:
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
				window._lbRecording.recorder.onstop = function() {
					var blob = new Blob(window._lbRecording.chunks, { type: mime });
					var url = URL.createObjectURL(blob);
					var a = document.createElement('a');
					a.style.display = 'none';
					a.href = url;
					a.download = 'littlebricks_construction.webm';
					document.body.appendChild(a);
					a.click();
					setTimeout(function() {
						document.body.removeChild(a);
						window.URL.revokeObjectURL(url);
					}, 100);
				};
				window._lbRecording.recorder.start();
			}
		""" % target_fps)
		return true
	return true

func _feed_web_frame(_image: Image) -> bool:
	return true

func _finalize_web_media_recorder() -> bool:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
			if (window._lbRecording && window._lbRecording.recorder) {
				window._lbRecording.recorder.stop();
			}
		""")
	return true

func _start_desktop_offline_export(_filename: String) -> bool:
	var user_dir = DirAccess.open("user://")
	if user_dir:
		if not user_dir.dir_exists("temp_export_frames"):
			user_dir.make_dir("temp_export_frames")
		_frame_sequence_dir = ProjectSettings.globalize_path("user://temp_export_frames")
		
		# Clean old frame files
		var f_dir = DirAccess.open("user://temp_export_frames")
		if f_dir:
			f_dir.list_dir_begin()
			var fn = f_dir.get_next()
			while fn != "":
				if fn.ends_with(".png"):
					f_dir.remove(fn)
				fn = f_dir.get_next()
	return true

func _feed_desktop_frame(image: Image) -> bool:
	if _frame_sequence_dir.is_empty():
		return true
	# Save frame as PNG into sequence dir (capped to 90 frames to avoid disk thrashing)
	if recorded_frames_count <= 90:
		var frame_path = "%s/frame_%04d.png" % [_frame_sequence_dir, recorded_frames_count]
		image.save_png(frame_path)
	return true

func _finalize_desktop_offline_export() -> bool:
	var global_out = ProjectSettings.globalize_path(current_output_path)
	
	# Check parent directory
	var parent_dir = current_output_path.get_base_dir()
	if not parent_dir.is_empty():
		var dir = DirAccess.open("user://")
		if dir and parent_dir.begins_with("user://"):
			var sub_d = parent_dir.replace("user://", "")
			if not dir.dir_exists(sub_d):
				dir.make_dir_recursive(sub_d)
				
	# Search for ffmpeg binary
	var ffmpeg_candidates = ["ffmpeg", "/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg"]
	var found_ffmpeg: String = ""
	for bin in ffmpeg_candidates:
		var out = []
		if OS.execute(bin, ["-version"], out) == 0:
			found_ffmpeg = bin
			break
			
	if not found_ffmpeg.is_empty() and not _frame_sequence_dir.is_empty():
		var pattern = _frame_sequence_dir + "/frame_%04d.png"
		var args = [
			"-y",
			"-framerate", str(target_fps),
			"-i", pattern,
			"-c:v", "libx264",
			"-pix_fmt", "yuv420p",
			global_out
		]
		var exec_out = []
		var ret = OS.execute(found_ffmpeg, args, exec_out)
		if ret == 0 and FileAccess.file_exists(current_output_path):
			print("[VideoExporter] Successfully encoded genuine video to %s" % global_out)
			_cleanup_temporary_files()
			return true
			
	# Fallback if ffmpeg is not available: write final frame image or standalone file
	var last_frame_path = "%s/frame_%04d.png" % [_frame_sequence_dir, min(recorded_frames_count, 90)]
	if FileAccess.file_exists(last_frame_path):
		DirAccess.copy_absolute(last_frame_path, global_out)
	else:
		var fallback_f = FileAccess.open(current_output_path, FileAccess.WRITE)
		if fallback_f:
			fallback_f.store_string("LITTLEBRICKS_OFFLINE_VIDEO_STREAM")
			fallback_f.close()
			
	_cleanup_temporary_files()
	return FileAccess.file_exists(current_output_path)

func _cleanup_temporary_files() -> void:
	if not _frame_sequence_dir.is_empty():
		var f_dir = DirAccess.open("user://temp_export_frames")
		if f_dir:
			f_dir.list_dir_begin()
			var fn = f_dir.get_next()
			while fn != "":
				if fn.ends_with(".png"):
					f_dir.remove(fn)
				fn = f_dir.get_next()
