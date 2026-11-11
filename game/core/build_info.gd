class_name BuildInfo

const VERSION: String = "2.1.0-dev"
const GIT_SHA: String = "source"
const BUILD_DATE: String = ""
const RENDERER: String = "gl_compatibility"

static func get_build_summary() -> String:
	var revision := GIT_SHA if BUILD_DATE.is_empty() else "%s · %s" % [GIT_SHA, BUILD_DATE]
	return "LittleBricks v%s (%s · Godot %s · %s)" % [VERSION, revision, Engine.get_version_info().get("string", ""), RENDERER]
