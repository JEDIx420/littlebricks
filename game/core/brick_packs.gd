extends RefCounted
## Shared pack labels for setup, the catalogue, and finished-build plans.

const IDS: Array[String] = ["harbour", "cabin", "galaxy", "heroes", "castle"]
const LABELS: Array[String] = ["Coastal Harbour", "Forest Cabin", "Galactic Hangar", "Heroes HQ", "Castle Keep"]
const DISPLAY_NAMES: Dictionary = {
	"harbour": "Sunny Harbour", "cabin": "Forest Cabin", "galaxy": "Galactic Hangar",
	"heroes": "Heroes HQ", "castle": "Castle Keep",
}

static func get_name(pack_id: String) -> String:
	var index := IDS.find(pack_id)
	return LABELS[index] if index >= 0 else "All packs"
