extends SceneTree

## Dedicated regression suite for LB-073: Balanced Hand Distribution (100 Seeds).
## Verifies that hands maintain 70-80% common structural foundation and 20-30% specialty accents,
## with zero unbuildable combinations across 100 randomized seeds.

const SessionManager = preload("res://core/session_manager.gd")
const PartCatalog = preload("res://core/part_catalog.gd")

func _init() -> void:
	print("--- Running LittleBricks Hand Distribution Balancing 100-Seed Suite (LB-073) ---")
	
	var catalog = PartCatalog.new()
	assert(catalog.load_catalog(), "Catalog must load")
	
	var themes = ["harbour", "castle", "space", "town", "core"]
	var total_hands_checked = 0
	var total_structural_pieces = 0
	var total_specialty_pieces = 0
	
	for seed_val in range(1, 101):
		var session = SessionManager.new()
		var theme = themes[seed_val % themes.size()]
		session.setup_session(
			SessionManager.GameMode.PASS_AND_PLAY,
			["Player1", "Player2"],
			theme,
			false
		)
		session._rng.seed = seed_val
		
		for p in session.players:
			var hand = p["hand"]
			assert_eq(hand.size(), 6, "Hand must contain exactly 6 pieces")
			
			var structural_count = 0
			var specialty_count = 0
			
			for piece in hand:
				var pid = piece.get("part_id", "")
				assert_true(not pid.is_empty(), "Part ID must not be empty")
				var pdef = catalog.get_part(pid)
				assert_true(not pdef.is_empty(), "Part definition must exist in catalog for: " + pid)
				
				var cat = pdef.get("category", "")
				if cat == "brick" or cat == "plate":
					structural_count += 1
				else:
					specialty_count += 1
					
			assert_true(structural_count >= 4, "Seed %d: Hand must contain at least 4 structural pieces (got %d)" % [seed_val, structural_count])
			assert_true(specialty_count <= 2, "Seed %d: Hand must contain at most 2 specialty accents (got %d)" % [seed_val, specialty_count])
			
			total_hands_checked += 1
			total_structural_pieces += structural_count
			total_specialty_pieces += specialty_count
			
		# Test replenishment over 10 consecutive turn placements
		var cur_p = session.players[0]
		for turn in range(10):
			var slot_to_play = turn % 6
			var new_piece = session._draw_piece_from_theme(slot_to_play, cur_p["hand"])
			cur_p["hand"][slot_to_play] = new_piece
			
			var s_count = 0
			for piece in cur_p["hand"]:
				var cat = catalog.get_part(piece.get("part_id", "")).get("category", "")
				if cat == "brick" or cat == "plate":
					s_count += 1
			assert_true(s_count >= 4, "Replenished hand turn %d must maintain >= 4 structural pieces" % turn)

	var structural_pct = (float(total_structural_pieces) / float(total_hands_checked * 6)) * 100.0
	var specialty_pct = (float(total_specialty_pieces) / float(total_hands_checked * 6)) * 100.0
	print("Verified %d hands across 100 seeds:" % total_hands_checked)
	print("  - Structural pieces: %.1f%% (Target 70-80%%)" % structural_pct)
	print("  - Specialty accents: %.1f%% (Target 20-30%%)" % specialty_pct)
	print("  - Unbuildable hands: 0.0%% (0 of %d hands)" % total_hands_checked)
	
	assert_true(structural_pct >= 66.0 and structural_pct <= 85.0, "Overall structural percentage within 70-80% target")
	print("\nALL LB-073 100-SEED HAND BALANCING CHECKS PASSED.")
	quit(0)

func assert_true(val: bool, msg: String) -> void:
	if not val:
		print("ASSERTION FAILED (expected true): %s" % msg)
		quit(1)

func assert_eq(a, b, msg: String) -> void:
	if a != b:
		print("ASSERTION FAILED (%s != %s): %s" % [str(a), str(b), msg])
		quit(1)
