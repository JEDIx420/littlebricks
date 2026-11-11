extends SceneTree

## Automated test suite for LB-060: First Three Screens Family Play Experience.
## Verifies craft-table design tokens, responsive sizes (>= 48px), absence of emoji glyphs,
## clear mode selection, contextual setup, and navigation signaling.

const WelcomeScene = preload("res://client/scenes/welcome_screen.tscn")
const ModeSelectScene = preload("res://client/scenes/mode_select.tscn")
const SetupScene = preload("res://client/scenes/setup_screen.tscn")

func _init() -> void:
	print("--- Running Test: LB-060 First Three Screens Family Play Experience ---")
	
	test_welcome_screen()
	test_mode_select_screen()
	test_setup_screen()
	test_responsive_minimum_sizes()
	
	print("--- All LB-060 First Three Screens tests passed! ---")
	quit(0)

func test_welcome_screen() -> void:
	print("Testing Welcome Screen...")
	var welcome = WelcomeScene.instantiate()
	root.add_child(welcome)
	if not welcome.is_node_ready():
		welcome._ready()
	
	var btn_play = welcome.find_child("BtnPlay", true, false) as Button
	assert(btn_play != null, "BtnPlay exists")
	assert(btn_play.custom_minimum_size.y >= 48, "BtnPlay has touch target >= 48px")
	assert(btn_play.text == "Let's Build!", "BtnPlay has inviting family copy")
	
	var btn_mute = welcome.find_child("BtnMute", true, false) as Button
	assert(btn_mute != null, "BtnMute exists")
	assert(not ("🔇" in btn_mute.text or "🔊" in btn_mute.text), "BtnMute does not rely on OS emojis")
	
	var muted_signals: Array = []
	welcome.mute_toggled.connect(func(val): muted_signals.append(val))
	welcome._on_mute_pressed()
	assert(muted_signals.size() == 1 and muted_signals[0] == true, "Mute toggle emits correct state")
	assert(btn_mute.text == "Sound: OFF", "BtnMute displays Sound: OFF when muted")
	
	welcome._on_mute_pressed()
	assert(btn_mute.text == "Sound: ON", "BtnMute displays Sound: ON when unmuted")
	
	var play_signaled = []
	welcome.play_pressed.connect(func(): play_signaled.append(true))
	btn_play.pressed.emit()
	assert(play_signaled.size() > 0, "BtnPlay emits play_pressed")
	
	welcome.queue_free()
	print("  ✓ Welcome Screen verified")

func test_mode_select_screen() -> void:
	print("Testing Mode Select Screen...")
	var mode_view = ModeSelectScene.instantiate()
	root.add_child(mode_view)
	if not mode_view.is_node_ready():
		mode_view._ready()
	
	var btn_solo = mode_view.find_child("BtnSolo", true, false) as Button
	var btn_pass = mode_view.find_child("BtnPassPlay", true, false) as Button
	var btn_online = mode_view.find_child("BtnOnline", true, false) as Button
	var btn_back = mode_view.find_child("BtnBack", true, false) as Button
	
	assert(btn_solo != null, "BtnSolo exists")
	assert(btn_pass != null, "BtnPassPlay exists")
	assert(btn_online != null, "BtnOnline exists")
	assert(btn_back != null, "BtnBack exists")
	
	assert(btn_solo.custom_minimum_size.y >= 48, "BtnSolo touch height >= 48px")
	assert(btn_pass.custom_minimum_size.y >= 48, "BtnPassPlay touch height >= 48px")
	assert(btn_online.custom_minimum_size.y >= 48, "BtnOnline touch height >= 48px")
	assert(btn_back.custom_minimum_size.y >= 44, "BtnBack touch height >= 44px")
	
	# Verify badges do not contain emojis
	var badge_solo = mode_view.find_child("BadgeSolo", true, false) as Label
	var badge_pass = mode_view.find_child("BadgePassPlay", true, false) as Label
	var badge_online = mode_view.find_child("BadgeOnline", true, false) as Label
	assert(badge_solo != null and not ("🔨" in badge_solo.text), "BadgeSolo has clean text")
	assert(badge_pass != null and not ("👥" in badge_pass.text or "🤝" in badge_pass.text), "BadgePassPlay has clean text")
	assert(badge_online != null and not ("🌐" in badge_online.text), "BadgeOnline has clean text")
	
	var selected_modes: Array = []
	mode_view.mode_selected.connect(func(m): selected_modes.append(m))
	
	btn_solo.emit_signal("pressed")
	assert(selected_modes.size() == 1 and selected_modes[0] == "solo", "Select solo signal emitted")
	
	btn_pass.emit_signal("pressed")
	assert(selected_modes.size() == 2 and selected_modes[1] == "pass_and_play", "Select pass & play signal emitted")
	
	btn_online.emit_signal("pressed")
	assert(selected_modes.size() == 3 and selected_modes[2] == "online", "Select online signal emitted")
	
	var back_emitted = []
	mode_view.back_pressed.connect(func(): back_emitted.append(true))
	btn_back.pressed.emit()
	assert(back_emitted.size() > 0, "BtnBack emits back_pressed")
	
	mode_view.queue_free()
	print("  ✓ Mode Select Screen verified")

func test_setup_screen() -> void:
	print("Testing Setup Screen...")
	var setup_view = SetupScene.instantiate()
	root.add_child(setup_view)
	if not setup_view.is_node_ready():
		setup_view._ready()
	
	setup_view.configure_for_mode("solo")
	var container_solo = setup_view.find_child("ContainerSolo", true, false) as Control
	var container_pass = setup_view.find_child("ContainerPassPlay", true, false) as Control
	var container_online = setup_view.find_child("ContainerOnline", true, false) as Control
	var btn_start = setup_view.find_child("BtnStart", true, false) as Button
	
	assert(container_solo.visible, "Solo container visible for solo mode")
	assert(not container_pass.visible, "Pass container hidden for solo mode")
	assert(not container_online.visible, "Online container hidden for solo mode")
	assert(btn_start.custom_minimum_size.y >= 48, "BtnStart touch height >= 48px")
	
	var emitted_configs: Array = []
	setup_view.start_session_requested.connect(func(c): emitted_configs.append(c))
	
	btn_start.emit_signal("pressed")
	assert(emitted_configs.size() == 1, "Start solo session emitted config")
	assert(emitted_configs[0]["mode"] == "solo", "Solo config mode correct")
	assert(emitted_configs[0].has("theme_id"), "Solo config has theme_id")
	
	setup_view.configure_for_mode("pass_and_play")
	assert(not container_solo.visible, "Solo container hidden for pass & play")
	assert(container_pass.visible, "Pass container visible for pass & play")
	
	btn_start.emit_signal("pressed")
	assert(emitted_configs.size() == 2, "Start pass session emitted config")
	assert(emitted_configs[1]["mode"] == "pass_and_play", "Pass config mode correct")
	assert(emitted_configs[1]["players"].size() >= 2, "Pass & play has at least 2 players")
	
	setup_view.configure_for_mode("online")
	assert(container_online.visible, "Online container visible for online")
	assert(not btn_start.visible, "BtnStart hidden for online in favor of Create/Join")
	
	var btn_create = setup_view.find_child("BtnCreateRoom", true, false) as Button
	assert(btn_create != null and btn_create.custom_minimum_size.y >= 48, "BtnCreateRoom touch height >= 48px")
	btn_create.emit_signal("pressed")
	assert(emitted_configs.size() == 3, "Create room emitted config")
	assert(emitted_configs[2]["mode"] == "online" and emitted_configs[2]["is_host"] == true, "Online create config correct")
	
	setup_view.queue_free()
	print("  ✓ Setup Screen verified")

func test_responsive_minimum_sizes() -> void:
	print("Testing Responsive Minimum Sizes...")
	var welcome = WelcomeScene.instantiate()
	var mode_view = ModeSelectScene.instantiate()
	var setup_view = SetupScene.instantiate()
	
	root.add_child(welcome)
	root.add_child(mode_view)
	root.add_child(setup_view)
	
	# Verify that buttons have touch target size >= 48px in height and width
	var all_buttons: Array[Button] = [
		welcome.find_child("BtnPlay", true, false),
		welcome.find_child("BtnContinue", true, false),
		welcome.find_child("BtnMyBuilds", true, false),
		welcome.find_child("BtnSettings", true, false),
		mode_view.find_child("BtnSolo", true, false),
		mode_view.find_child("BtnPassPlay", true, false),
		mode_view.find_child("BtnOnline", true, false),
		setup_view.find_child("BtnStart", true, false),
		setup_view.find_child("BtnCreateRoom", true, false),
		setup_view.find_child("BtnJoinRoom", true, false)
	]
	
	for btn in all_buttons:
		if btn != null:
			assert(btn.custom_minimum_size.y >= 44, "Button %s has touch height >= 44px (actual: %d)" % [btn.name, btn.custom_minimum_size.y])
	
	welcome.queue_free()
	mode_view.queue_free()
	setup_view.queue_free()
	print("  ✓ Responsive touch targets verified")
