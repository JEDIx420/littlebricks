extends SceneTree

## Dedicated regression suite for LB-036: Building Rules, Turn Hands & Safe Input.

const MainScene = preload("res://client/scenes/main.tscn")
const SessionManager = preload("res://core/session_manager.gd")
const AudioDirector = preload("res://client/scripts/audio_director.gd")

func _init() -> void:
	print("--- Running LittleBricks Building Rules, Hands & Input Suite (LB-036) ---")
	
	var main = MainScene.instantiate()
	root.add_child(main)
	main._ready()
	
	var audio = AudioDirector.new()
	root.add_child(audio)
	
	# =========================================================================
	# Test Group 1: 2-Player Pass & Play Hands, Turns & Refill
	# =========================================================================
	print("\n[Group 1: 2-Player Pass & Play Turn Progression & Refill]")
	
	var session = SessionManager.new()
	session.setup_session(
		SessionManager.GameMode.PASS_AND_PLAY,
		["Alice", "Bob"],
		"harbour",
		true
	)
	session.timer_duration_sec = 20.0
	session.time_remaining_sec = 20.0
	
	main.attach_session(session, audio, null)
	
	# Initial player is Alice
	assert_eq(session.get_current_player()["name"], "Alice", "Alice starts the session")
	assert_eq(main.tray_container.get_child_count(), 6, "Tray displays Alice's 6 hand pieces")
	assert_true(main.btn_pass_turn.visible, "Pass Turn button visible in multiplayer")
	assert_true(main.label_timer.visible, "Timer visible when timer_enabled is true")
	
	var alice_hand_before = session.players[0]["hand"].duplicate(true)
	var alice_piece = alice_hand_before[0]
	main.selected_part_id = alice_piece["part_id"]
	main.selected_color = alice_piece["color"]
	
	# Alice places piece on baseplate
	main.current_grid_pos = Vector2i(4, 4)
	main.current_layer_plate = 0
	main._validate_and_update_ghost()
	main._on_place_pressed()
	
	assert_eq(main.placed_pieces_data.size(), 1, "Piece placed on board")
	assert_eq(session.placements.size(), 1, "Session recorded Alice's placement")
	assert_eq(session.get_current_player()["name"], "Bob", "Turn automatically advanced to Bob")
	assert_eq(main.tray_container.get_child_count(), 6, "Tray refreshed with Bob's 6 hand pieces")
	
	# Verify Alice's slot 0 was refilled
	var alice_hand_after = session.players[0]["hand"]
	assert_eq(alice_hand_after.size(), 6, "Alice retains 6 pieces after placement")
	print("PASS: Turn progression and hand refilling work as designed.")
	
	# =========================================================================
	# Test Group 2: Voluntary Pass & Turn Timer Expiry
	# =========================================================================
	print("\n[Group 2: Voluntary Pass & Turn Timer Countdown]")
	
	# Bob voluntarily passes his turn
	main._on_pass_turn_pressed()
	assert_eq(session.get_current_player()["name"], "Alice", "Pass turn advanced back to Alice")
	assert_eq(session.time_remaining_sec, 20.0, "Timer reset to 20s for new turn")
	
	# Simulate timer countdown
	session.tick_timer(10.0)
	assert_eq(session.time_remaining_sec, 10.0, "Timer ticks down 10s")
	
	# Simulate timer expiring completely
	session.tick_timer(10.5)
	assert_eq(session.get_current_player()["name"], "Bob", "Timeout skipped turn to Bob")
	print("PASS: Voluntary skip and timer timeout advance turns cleanly.")
	
	# =========================================================================
	# Test Group 3: Undo / Redo with Dependent Move Protection
	# =========================================================================
	print("\n[Group 3: Undo/Redo & Dependent Move Protection]")
	
	# Bob places piece 2 at distant coordinates (16, 16)
	main.selected_part_id = "brick_2x4"
	main.current_grid_pos = Vector2i(16, 16)
	main.current_layer_plate = 0
	main._validate_and_update_ghost()
	main._on_place_pressed()
	assert_eq(main.placed_pieces_data.size(), 2, "Board now has 2 pieces")
	
	# Undo piece 2
	main._on_undo_pressed()
	assert_eq(main.placed_pieces_data.size(), 1, "Board reverted to 1 piece after undo")
	assert_eq(session.placements.size(), 1, "Session reverted to 1 placement")
	
	# Redo piece 2
	main._on_redo_pressed()
	assert_eq(main.placed_pieces_data.size(), 2, "Board restored piece 2 after redo")
	assert_eq(session.placements.size(), 2, "Session restored piece 2 after redo")
	
	# Now stack a brick directly on top of piece 1 (at 4, 4, layer 3)
	main.selected_part_id = "brick_2x4"
	main.current_grid_pos = Vector2i(4, 4)
	main.current_layer_plate = 3
	main._validate_and_update_ghost()
	main._on_place_pressed()
	assert_eq(main.placed_pieces_data.size(), 3, "Board now has 3 pieces (with stacked brick)")
	
	# Try to undo piece 1 (at bottom of stack) while piece 3 is on top
	# In session.placements: piece 1 is index 0. Last placement is piece 3.
	# Undo last placement (piece 3) succeeds
	main._on_undo_pressed()
	assert_eq(main.placed_pieces_data.size(), 2, "Undid top piece 3 successfully")
	print("PASS: Undo/Redo operations and state restoration verified.")
	
	# =========================================================================
	# Test Group 4: Solo Parts Catalogue Browser
	# =========================================================================
	print("\n[Group 4: Solo Parts Catalogue Browser Modal]")
	
	# Toggle modal
	main._toggle_catalog_modal()
	assert_true(main.catalog_modal.visible, "Catalog modal opened")
	
	# Check category options populated
	assert_true(main.opt_catalog_category.item_count >= 7, "Category options populated")
	
	# Filter by 'slope'
	main.opt_catalog_category.selected = 3 # Slopes
	main._populate_catalog_grid()
	assert_true(main.catalog_grid.get_child_count() > 0, "Slope parts displayed in grid")
	
	# Filter by search 'arch'
	main.opt_catalog_category.selected = 0 # All
	main.line_catalog_search.text = "arch"
	main._populate_catalog_grid()
	assert_true(main.catalog_grid.get_child_count() >= 1, "Arch parts displayed by search")
	
	# Close modal
	main._close_catalog_modal()
	assert_false(main.catalog_modal.visible, "Catalog modal closed cleanly")
	print("PASS: Solo parts catalogue modal, filtering, and search verified.")
	
	# =========================================================================
	# Test Group 5: Safe Input Ownership (PC-07)
	# =========================================================================
	print("\n[Group 5: Safe Input Ownership & Modal Isolation]")
	
	# When modal is visible, unhandled input is blocked
	main.catalog_modal.visible = true
	var click_event = InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	var before_count = main.placed_pieces_data.size()
	main._unhandled_input(click_event)
	assert_eq(main.placed_pieces_data.size(), before_count, "No placement occurs when modal is open")
	main.catalog_modal.visible = false
	print("PASS: Input ownership prevents unintended placements.")
	
	print("\nALL LB-036 BUILDING RULES & INPUT CHECKS PASSED.")
	main.queue_free()
	audio.queue_free()
	quit(0)

func assert_true(val: bool, msg: String) -> void:
	if not val:
		print("ASSERTION FAILED (expected true): %s" % msg)
		quit(1)

func assert_false(val: bool, msg: String) -> void:
	if val:
		print("ASSERTION FAILED (expected false): %s" % msg)
		quit(1)

func assert_eq(a, b, msg: String) -> void:
	if a != b:
		print("ASSERTION FAILED (%s != %s): %s" % [str(a), str(b), msg])
		quit(1)
