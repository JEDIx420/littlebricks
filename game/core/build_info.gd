class_name BuildInfo

const VERSION: String = "2.0.0-dev"
const GIT_SHA: String = "4a4dc34"
const BUILD_DATE: String = "2026-11-11"
const ENGINE_VERSION: String = "4.7.2.stable.official"
const RENDERER: String = "gl_compatibility"

static func get_build_summary() -> String:
	return "LittleBricks v%s (%s • %s • %s)" % [VERSION, GIT_SHA, BUILD_DATE, RENDERER]
