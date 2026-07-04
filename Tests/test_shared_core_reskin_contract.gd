extends SceneTree

const CORE_DOC_PATH := "res://shared/ShinokuteGameCore/docs/reskin_core_skin_boundary.md"
const CHECKLIST_PATH := "res://docs/release_packaging_checklist.md"
const PROJECT_PATH := "res://project.godot"
const MCP_SCRIPT_PATH := "res://Scripts/mcp_interaction_server.gd"

func _init() -> void:
	var passed := true
	var core_doc := FileAccess.get_file_as_string(CORE_DOC_PATH)
	var checklist := FileAccess.get_file_as_string(CHECKLIST_PATH)
	var project := FileAccess.get_file_as_string(PROJECT_PATH)
	var mcp_script := FileAccess.get_file_as_string(MCP_SCRIPT_PATH)

	passed = passed and _assert_true(not core_doc.is_empty(), "Shared ShinokuteGameCore reskin doctrine should exist")
	passed = passed and _assert_true(core_doc.contains("MUST READ BEFORE RESKIN"), "Core doctrine should be mandatory")
	passed = passed and _assert_true(core_doc.contains("Core = behavior"), "Core doctrine should define core")
	passed = passed and _assert_true(core_doc.contains("Game skin ="), "Core doctrine should define game skin")
	passed = passed and _assert_true(core_doc.contains("Function skin ="), "Core doctrine should define function skin")
	passed = passed and _assert_true(core_doc.contains("No fallback"), "Core doctrine should preserve no-fallback rule")

	passed = passed and _assert_true(checklist.contains("shared/ShinokuteGameCore/docs/reskin_core_skin_boundary.md"), "Release checklist should require core reskin doctrine")
	passed = passed and _assert_true(checklist.contains("Core = behavior"), "Release checklist should repeat core ownership rule")
	passed = passed and _assert_true(checklist.contains("Game skin = game-specific art"), "Release checklist should repeat game skin ownership rule")
	passed = passed and _assert_true(checklist.contains("Function skin = game-specific presentation"), "Release checklist should repeat function skin ownership rule")
	passed = passed and _assert_true(checklist.contains("No fallback"), "Release checklist should repeat no-fallback rule")

	passed = passed and _assert_true(project.contains("McpInteractionServer=\"*res://Scripts/mcp_interaction_server.gd\""), "MCP autoload should point to tracked script")
	passed = passed and _assert_true(not mcp_script.is_empty(), "MCP autoload script should exist in source")

	if passed:
		print("test_shared_core_reskin_contract: PASS")
		quit(0)
	else:
		print("test_shared_core_reskin_contract: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		return false
	return true
