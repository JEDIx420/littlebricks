extends SceneTree

const AppScene = preload("res://client/scenes/app_root.tscn")
const Server = preload("res://server/littlebricks_server.gd")
const ENDPOINT := "ws://127.0.0.1:9097"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	create_timer(15).timeout.connect(func():
		push_error("Private room integration test timed out")
		quit(1)
	)
	var server := Server.new()
	root.add_child(server)
	assert(server.start(9097, "127.0.0.1") == OK)
	var host := _new_builder("Jay")
	var host_setup := host.current_view as SetupScreen
	host_setup.btn_create_room.pressed.emit()
	assert(await _until(func(): return not host_setup.get_node("%LobbyCode").text.is_empty()))
	var invite: String = host_setup.get_node("%LobbyCode").text
	assert(invite.length() == 6 and server.rooms.has(invite))
	assert(host_setup.get_node("%BtnCopyCode").is_visible_in_tree())

	var friend := _new_builder("Riley")
	var friend_setup := friend.current_view as SetupScreen
	var invalid := "AAAAAA" if invite != "AAAAAA" else "BBBBBB"
	_join(friend_setup, invalid)
	assert(await _until(func(): return "Room code not found" in friend_setup.get_node("%OnlineStatus").text))
	assert(not server.rooms.has(invalid))
	_join(friend_setup, invite.to_lower())
	assert(await _until(func(): return host.room_roster.size() == 2 and friend.room_roster.size() == 2))

	var third := _new_builder("Sam")
	var third_setup := third.current_view as SetupScreen
	_join(third_setup, invite)
	assert(await _until(func(): return host.room_roster.size() == 3 and third.room_roster.size() == 3))
	for setup in [host_setup, friend_setup, third_setup]:
		setup.get_node("%BtnOnlineReady").pressed.emit()

	assert(await _until(func(): return host.active_session != null and friend.active_session != null and third.active_session != null))
	assert(host.active_session.players.size() == 3)
	assert(host.room_connection.player_id == "p_1")
	assert(friend.room_connection.player_id == "p_2")
	assert(third.room_connection.player_id == "p_3")
	assert(friend.current_view.btn_place.disabled)
	_place(host, 8, 8)
	assert(await _until(func(): return third.active_session.placements.size() == 1))
	assert(friend.active_session.get_current_player_id() == "p_2")
	_place(friend, 16, 16)
	assert(await _until(func(): return host.active_session.placements.size() == 2))
	assert(third.active_session.get_current_player_id() == "p_3")
	_place(third, 24, 24)
	assert(await _until(func(): return host.active_session.placements.size() == 3 and friend.active_session.placements.size() == 3))
	for app in [host, friend, third]:
		assert(app.active_session.get_current_player_id() == "p_1")
		assert(app.current_view.placed_bricks_container.get_child_count() == 3)
		app.current_view.btn_finish.pressed.emit()
	assert(await _until(func(): return host.active_session.phase == SessionManager.SessionPhase.EXPLORATION and third.active_session.phase == SessionManager.SessionPhase.EXPLORATION))
	for app in [host, friend, third]:
		app._close_room_connection()
		app.queue_free()
	server.stop()
	server.queue_free()
	await process_frame
	print("PASS: Invite lobby, unknown-code retry, three synchronized turns and shared exploration")
	quit()

func _new_builder(player_name: String) -> AppRoot:
	var app := AppScene.instantiate() as AppRoot
	root.add_child(app)
	app.navigate_to_setup("online")
	var setup := app.current_view as SetupScreen
	setup.line_online_name.text = player_name
	setup.get_node("%LineOnlineEndpoint").text = ENDPOINT
	return app

func _join(setup: SetupScreen, code: String) -> void:
	setup.line_online_code.text = code
	setup.btn_join_room.pressed.emit()

func _place(app: AppRoot, x: int, z: int) -> void:
	var table = app.current_view
	table.current_grid_pos = Vector2i(x, z)
	table.current_layer_plate = 0
	table._pointer_missed_board = false
	table._validate_and_update_ghost()
	assert(table.is_current_placement_valid)
	table.btn_place.pressed.emit()

func _until(condition: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 2500
	while not condition.call():
		if Time.get_ticks_msec() > deadline:
			return false
		await process_frame
	return true
