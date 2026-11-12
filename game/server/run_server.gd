extends SceneTree

const Server = preload("res://server/littlebricks_server.gd")

func _initialize() -> void:
	var port := 9080
	var bind_address := "127.0.0.1"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--port="):
			port = argument.trim_prefix("--port=").to_int()
		elif argument.begins_with("--bind="):
			bind_address = argument.trim_prefix("--bind=")
	if port < 1 or port > 65535 or bind_address.is_empty():
		push_error("Usage: -- --port=9080 --bind=127.0.0.1")
		quit(1)
		return
	var server := Server.new()
	if server.start(port, bind_address) != OK:
		server.free()
		quit(1)
		return
	root.add_child.call_deferred(server)
