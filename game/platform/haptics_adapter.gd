extends RefCounted
class_name HapticsAdapter

## Platform haptics adapter for LittleBricks (LB-041).
## Safely wraps Input.vibrate_handheld() with enabled preferences and honest fallback.

var is_enabled: bool = true
var is_supported: bool = false

func _init() -> void:
	# Desktop platforms (macOS/Windows/Linux) do not have vibration motors
	var os_name = OS.get_name()
	if os_name == "Android" or os_name == "iOS" or os_name == "Web":
		is_supported = true
	else:
		is_supported = false

## Light tactile pulse for piece pickup / selection (~10ms)
func vibrate_light() -> void:
	if not is_enabled or not is_supported:
		return
	Input.vibrate_handheld(12)

## Signature confirmation pulse on accepted brick placement (~20ms)
func vibrate_placement() -> void:
	if not is_enabled or not is_supported:
		return
	Input.vibrate_handheld(22)

## Discrete error pulse for rejected placement (~30ms)
func vibrate_error() -> void:
	if not is_enabled or not is_supported:
		return
	Input.vibrate_handheld(32)
