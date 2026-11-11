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
var last_error: String = ""

# Desktop export state
var _frame_sequence_dir: String = ""
var _ffmpeg_path: String = ""

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
	current_output_path = output_filename
	last_error = ""

	var started: bool
	match OS.get_name().to_lower():
		"android":
			started = _start_android_mediacodec(output_filename)
		"web":
			started = _start_web_media_recorder()
		_:
			started = _start_desktop_offline_export(output_filename)
	if not started:
		return _fail(last_error if not last_error.is_empty() else "Could not start video export.")
	state = ExportState.RECORDING
	return true

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
		_fail(last_error if not last_error.is_empty() else "Could not encode the film.")
		return ""

func cancel_recording() -> void:
	if state != ExportState.RECORDING and state != ExportState.ENCODING:
		return
	state = ExportState.CANCELLED
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
			(function() {
				const recording = window._lbRecording;
				if (recording && recording.recorder.state === "recording") {
					recording.cancelled = true;
					recording.recorder.stop();
				}
			})();
		""")
	elif OS.has_feature("android") and Engine.has_singleton("LittleBricksMediaCodec"):
		var bridge = Engine.get_singleton("LittleBricksMediaCodec")
		if bridge.has_method("cancelRecording"):
			bridge.cancelRecording()
	_cleanup_temporary_files()

func _fail(message: String) -> bool:
	last_error = message
	state = ExportState.FAILED
	_cleanup_temporary_files()
	export_failed.emit(last_error)
	return false

# --- Platform Specific Hooks ---

func _start_android_mediacodec(filename: String) -> bool:
	if Engine.has_singleton("LittleBricksMediaCodec"):
		var bridge = Engine.get_singleton("LittleBricksMediaCodec")
		return bridge.startRecording(filename, target_width, target_height, target_fps)
	last_error = "Video export is unavailable in this Android build."
	return false

func _feed_android_frame(image: Image) -> bool:
	if Engine.has_singleton("LittleBricksMediaCodec"):
		var bridge = Engine.get_singleton("LittleBricksMediaCodec")
		return bridge.feedFrame(image.get_data())
	return false

func _finalize_android_mediacodec() -> bool:
	if Engine.has_singleton("LittleBricksMediaCodec"):
		var bridge = Engine.get_singleton("LittleBricksMediaCodec")
		return bridge.finishRecording()
	return false

func _start_web_media_recorder() -> bool:
	if not OS.has_feature("web"):
		return false
	var filename := JSON.stringify(current_output_path.get_file())
	var started = JavaScriptBridge.eval("""
		(function() {
			const canvas = document.querySelector('canvas');
			if (!canvas || !canvas.captureStream || !window.MediaRecorder) return false;
			let stream;
			try {
				stream = canvas.captureStream(%d);
				const mime = MediaRecorder.isTypeSupported('video/webm;codecs=vp9')
					? 'video/webm;codecs=vp9' : 'video/webm';
				const recorder = new MediaRecorder(stream, { mimeType: mime });
				const recording = {recorder, chunks: [], cancelled: false};
				window._lbRecording = recording;
				recorder.ondataavailable = (e) => {
					if (e.data.size > 0) recording.chunks.push(e.data);
				};
				recorder.onstop = () => {
					stream.getTracks().forEach((track) => track.stop());
					if (window._lbRecording === recording) delete window._lbRecording;
					if (recording.cancelled || !recording.chunks.length) return;
					const url = URL.createObjectURL(new Blob(recording.chunks, {type: mime}));
					const link = document.createElement('a');
					link.href = url;
					link.download = %s;
					document.body.appendChild(link);
					link.click();
					link.remove();
					setTimeout(() => URL.revokeObjectURL(url), 2000);
				};
				recorder.start();
				return true;
			} catch (error) {
				if (stream) stream.getTracks().forEach((track) => track.stop());
				delete window._lbRecording;
				return false;
			}
		})();
	""" % [target_fps, filename])
	if started != true:
		last_error = "This browser does not support film capture."
	return started == true

func _feed_web_frame(_image: Image) -> bool:
	return OS.has_feature("web")

func _finalize_web_media_recorder() -> bool:
	if not OS.has_feature("web"):
		return false
	return JavaScriptBridge.eval("""
		(function() {
			const recording = window._lbRecording;
			if (!recording || recording.recorder.state !== "recording") return false;
			recording.recorder.stop();
			return true;
		})();
	""") == true

func _start_desktop_offline_export(filename: String) -> bool:
	for executable in ["ffmpeg", "/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg"]:
		if OS.execute(executable, ["-version"], []) == 0:
			_ffmpeg_path = executable
			break
	if _ffmpeg_path.is_empty():
		last_error = "Install FFmpeg to export MP4 films."
		return false

	var output_dir := ProjectSettings.globalize_path(filename).get_base_dir()
	if not output_dir.is_empty() and DirAccess.make_dir_recursive_absolute(output_dir) != OK:
		last_error = "Could not create the film's destination folder."
		return false

	_frame_sequence_dir = ProjectSettings.globalize_path("user://export_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	if DirAccess.make_dir_recursive_absolute(_frame_sequence_dir) != OK:
		last_error = "Could not create a temporary film folder."
		return false
	return true

func _feed_desktop_frame(image: Image) -> bool:
	var frame_path := "%s/frame_%06d.jpg" % [_frame_sequence_dir, recorded_frames_count]
	if image.save_jpg(frame_path, 0.94) != OK:
		last_error = "Could not write a film frame."
		return false
	return true

func _finalize_desktop_offline_export() -> bool:
	var output_path := ProjectSettings.globalize_path(current_output_path)
	var temp_output := _frame_sequence_dir.path_join("film.mp4")
	var args := [
		"-hide_banner", "-loglevel", "error", "-y",
		"-framerate", str(target_fps), "-i", _frame_sequence_dir.path_join("frame_%06d.jpg"),
		"-c:v", "libx264", "-threads", "2", "-pix_fmt", "yuv420p", "-movflags", "+faststart", temp_output
	]
	var diagnostics := []
	var encoded := OS.execute(_ffmpeg_path, args, diagnostics, true) == 0 and FileAccess.file_exists(temp_output)
	if encoded:
		encoded = DirAccess.copy_absolute(temp_output, output_path) == OK
	if not encoded:
		last_error = "FFmpeg could not save the film."
		if not diagnostics.is_empty() and not String(diagnostics[0]).strip_edges().is_empty():
			push_warning(String(diagnostics[0]).strip_edges())
	_cleanup_temporary_files()
	return encoded

func _cleanup_temporary_files() -> void:
	if _frame_sequence_dir.is_empty():
		return
	for filename in DirAccess.get_files_at(_frame_sequence_dir):
		DirAccess.remove_absolute(_frame_sequence_dir.path_join(filename))
	DirAccess.remove_absolute(_frame_sequence_dir)
	_frame_sequence_dir = ""
