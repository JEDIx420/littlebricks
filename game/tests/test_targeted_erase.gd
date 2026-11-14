extends SceneTree

const Session = preload("res://core/session_manager.gd")
const Save = preload("res://core/save_manager.gd")

var failed := false

func _init() -> void:
	_verify_history_and_replay()
	_verify_support()
	_verify_mixed_bag()
	_verify_legacy_ids()
	if not failed:
		print("PASS: targeted erase, alternate supports, undo/redo order, save, replay and legacy identities")
	quit(1 if failed else 0)

func _verify_history_and_replay() -> void:
	var session := Session.new()
	session.setup_session(Session.GameMode.SOLO_CREATIVE, ["Jay"])
	var first := _place(session, 3, 3)
	var second := _place(session, 9, 9)
	var third := _place(session, 14, 14)
	_expect(session.erase_placement(second).get("success"), "Erase removes a middle brick by ID")
	_expect(_ids(session) == [first, third], "Erase preserves the other poses")
	_expect(session.event_journal.back()["type"] == "PLACEMENT_ERASED", "Successful erase is journaled")
	var fourth := _place(session, 18, 18)
	_expect(fourth not in [first, second, third], "New placements never reuse a removed ID")
	_expect(session.undo_last_placement().get("undone_placement", {}).get("placement_id") == fourth, "Undo removes the newer addition first")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(Save.serialize_session(session)))
	var restored := Session.new()
	Save.restore_into_session(restored, saved)
	_expect(_ids(restored) == [first, third], "Save preserves board state")
	_expect(restored.undo_last_placement().get("restored_placement", {}).get("placement_id") == second, "Undo restores erased brick after reload")
	_expect(_ids(restored) == [first, second, third], "Restoration retains original board position")
	_expect(restored.redo_placement().get("removed_placement", {}).get("placement_id") == second, "Redo erases the same brick")
	_expect(restored.redo_placement().get("redone_placement", {}).get("placement_id") == fourth, "Redo then replays the later addition")
	_expect(_ids(restored) == [first, third, fourth], "Chronological redo matches the original board")
	restored.undo_last_placement()
	_place(restored, 20, 20)
	_expect(restored.redo_placement().get("code") == "EMPTY", "New edit closes the old redo branch")

func _verify_support() -> void:
	var session := Session.new()
	session.setup_session(Session.GameMode.SOLO_CREATIVE, ["Jay"])
	var base := _place(session, 6, 6)
	var span := _place(session, 6, 6, 3, "plate_1x2")
	var journal_count := session.event_journal.size()
	_expect(session.erase_placement(base).get("code") == "DEPENDENT_MOVE_EXISTS", "A load-bearing brick cannot be erased")
	_expect(_ids(session) == [base, span] and session.event_journal.size() == journal_count, "Blocked erase is atomic")
	var alternate := _place(session, 6, 7)
	_expect(session.erase_placement(base).get("success"), "A bridge with an alternate support can stay")
	var ordered := session.get_replay_placements()
	_expect(ordered.size() == 2 and ordered[0]["placement_id"] == alternate and ordered[1]["placement_id"] == span, "Film constructs surviving support first")

func _verify_mixed_bag() -> void:
	var session := Session.new()
	session.setup_session(Session.GameMode.SOLO_CHALLENGE, ["Jay"])
	var id := _place(session, 0, 0, 0, session.players[0]["hand"][0]["part_id"])
	var hand: Array = session.players[0]["hand"].duplicate(true)
	_expect(session.erase_placement(id).get("success"), "Mixed Bags can erase individual bricks")
	_expect(session.players[0]["hand"] == hand, "Erase does not redraw the bag")
	session.undo_last_placement()
	_expect(session.players[0]["hand"] == hand and _ids(session) == [id], "Undo restores the pose without duplicating inventory")
	session.mode = Session.GameMode.PASS_AND_PLAY
	_expect(session.erase_placement(id).get("code") == "SOLO_ONLY", "Shared builds cannot erase arbitrary bricks")

func _verify_legacy_ids() -> void:
	var session := Session.new()
	session.setup_session(Session.GameMode.SOLO_CREATIVE, ["Jay"])
	_place(session, 3, 3)
	_place(session, 9, 9)
	_place(session, 12, 12)
	var snapshot := Save.serialize_session(session)
	snapshot.erase("edit_history")
	snapshot["placements"][1]["placement_id"] = ""
	snapshot["placements"][2]["placement_id"] = snapshot["placements"][0]["placement_id"]
	var restored := Session.new()
	Save.restore_into_session(restored, snapshot)
	var ids := _ids(restored)
	_expect(ids.size() == 3 and ids[0] != ids[1] and ids[1] != ids[2] and ids[0] != ids[2] and "" not in ids, "Legacy missing and duplicate IDs are migrated")
	var again := Session.new()
	Save.restore_into_session(again, Save.serialize_session(restored))
	_expect(_ids(again) == ids, "Migrated IDs are stable on subsequent reload")
	_expect(again.erase_placement(ids[1]).get("success"), "Migrated IDs are erasable")
	_expect(_place(again, 18, 18) not in ids, "New identity cannot collide with migrated ones")

func _ids(session: Session) -> Array[String]:
	var result: Array[String] = []
	for placement in session.placements:
		result.append(placement["placement_id"])
	return result

func _place(session: Session, x: int, z: int, layer: int = 0, part: String = "brick_1x1") -> String:
	var placed := session.request_placement("p_1", 0, x, z, layer, 0, Color.VIOLET, part)
	_expect(placed, "Fixture placement failed for %s (%d, %d, %d)" % [part, x, z, layer])
	return session.placements.back().get("placement_id", "") if placed else ""

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
