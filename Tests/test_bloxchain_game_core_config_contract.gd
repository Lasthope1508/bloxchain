extends SceneTree

const CONFIG_PATH := "res://Resources/Data/bloxchain_game_core_config.tres"
const LEADERBOARD_MANAGER_PATH := "res://Scripts/LeaderboardManager.gd"
const EXPORT_PRESETS_PATH := "res://export_presets.cfg"

func _init() -> void:
	var passed := true
	var config := load(CONFIG_PATH)
	var leaderboard_source := FileAccess.get_file_as_string(LEADERBOARD_MANAGER_PATH)
	var export_presets := FileAccess.get_file_as_string(EXPORT_PRESETS_PATH)

	passed = passed and _assert_true(config != null, "BloxChain GameCoreConfig should load")
	if config != null:
		passed = passed and _assert_equal(config.get("game_id"), "bloxchain", "GameCoreConfig game id")
		passed = passed and _assert_equal(config.get("display_name"), "BloxChain", "GameCoreConfig display name")
		passed = passed and _assert_equal(config.get_collection("classic"), "leaderboard", "classic collection")
		passed = passed and _assert_equal(config.get_collection("chaos"), "leaderboard_chaos", "chaos collection")
		passed = passed and _assert_equal(config.get_sort_direction("classic"), "DESCENDING", "classic sort")
		passed = passed and _assert_true(config.validate_config().is_empty(), "GameCoreConfig should validate")

	passed = passed and _assert_true(leaderboard_source.contains("GAME_CORE_CONFIG_PATH"), "LeaderboardManager should load GameCoreConfig")
	passed = passed and _assert_true(leaderboard_source.contains("get_collection(mode)"), "LeaderboardManager should read collection from GameCoreConfig")
	passed = passed and _assert_true(leaderboard_source.contains("get_sort_direction(mode)"), "LeaderboardManager should read sort direction from GameCoreConfig")
	passed = passed and _assert_true(leaderboard_source.contains("leaderboard_limit"), "LeaderboardManager should read limit from GameCoreConfig")
	passed = passed and _assert_true(not leaderboard_source.contains("const FIRESTORE_API_KEY"), "LeaderboardManager should not hardcode API key const")
	passed = passed and _assert_true(not leaderboard_source.contains("const FIRESTORE_DOCS_URL"), "LeaderboardManager should not hardcode Firestore URL const")
	passed = passed and _assert_true(not leaderboard_source.contains("const GEOLOCATION_URL"), "LeaderboardManager should not hardcode geolocation URL const")
	passed = passed and _assert_true(not leaderboard_source.contains("leaderboard_chaos\" if mode"), "LeaderboardManager should not branch hardcoded collections")
	passed = passed and _assert_true(not leaderboard_source.contains("Saved fallback: Vietnam"), "LeaderboardManager should not invent geolocation fallback")

	passed = passed and _assert_true(export_presets.contains(CONFIG_PATH), "Export presets should include BloxChain GameCoreConfig")
	passed = passed and _assert_true(export_presets.contains("res://shared/ShinokuteGameCore/addons/shinokute_game_core/core/game_core_config.gd"), "Export presets should include shared GameCoreConfig script")

	if passed:
		print("test_bloxchain_game_core_config_contract: PASS")
		quit(0)
	else:
		print("test_bloxchain_game_core_config_contract: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		return false
	return true

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s expected=%s actual=%s" % [message, str(expected), str(actual)])
		return false
	return true
