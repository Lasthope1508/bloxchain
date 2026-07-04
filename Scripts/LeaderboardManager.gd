## coordinates global and regional leaderboard score submissions and queries
## using the Firebase Firestore REST API.
extends Node

signal leaderboard_loaded(tab: String, scores: Array, mode: String)
signal score_submitted(success: bool)
signal geolocation_resolved

const GAME_CORE_CONFIG_PATH := "res://Resources/Data/bloxchain_game_core_config.tres"

var player_country_code: String = ""
var player_country_name: String = ""
var player_continent_code: String = ""

var _core_config: Resource
var _geo_request: HTTPRequest
var _submit_request: HTTPRequest
var _query_request: HTTPRequest
var _is_submitting: bool = false
var _submit_queue: Array = []

func _ready() -> void:
	if not _load_core_config():
		return

	# Load cached geo data first
	player_country_code = SaveManager.get_country_code()
	player_country_name = SaveManager.get_country_name()
	player_continent_code = SaveManager.get_continent_code()
	
	# Instantiate HTTPRequest nodes
	_geo_request = HTTPRequest.new()
	_geo_request.accept_gzip = false
	add_child(_geo_request)
	_geo_request.request_completed.connect(_on_geo_request_completed)
	
	_submit_request = HTTPRequest.new()
	_submit_request.accept_gzip = false
	add_child(_submit_request)
	_submit_request.request_completed.connect(_on_submit_request_completed)
	
	_query_request = HTTPRequest.new()
	_query_request.accept_gzip = false
	add_child(_query_request)
	_query_request.request_completed.connect(_on_query_request_completed)
	
	# If no cached geolocation, fetch it
	if player_country_code == "":
		resolve_geolocation()
		
	# Auto-submit high scores if they have not been submitted yet
	var best_classic = SaveManager.get_best_score("classic")
	if best_classic > SaveManager.get_last_submitted_score("classic"):
		submit_score(best_classic, "classic")
		
	var best_chaos = SaveManager.get_best_score("chaos")
	if best_chaos > SaveManager.get_last_submitted_score("chaos"):
		submit_score(best_chaos, "chaos")


func resolve_geolocation() -> void:
	if not _require_core_config("resolve geolocation"):
		return
	var geolocation_url := String(_core_config.get("geolocation_url"))
	print("LeaderboardManager: Resolving geolocation from: ", geolocation_url)
	var headers: PackedStringArray = ["User-Agent: GodotGameClient"]
	var err = _geo_request.request(geolocation_url, headers)
	if err != OK:
		push_warning("LeaderboardManager: Failed to start geo request (err %d)" % err)


func submit_score(score: int, mode: String = GameState.start_mode) -> void:
	if score <= 0:
		return
		
	if score <= SaveManager.get_last_submitted_score(mode):
		print("LeaderboardManager: Score %d is not higher than last submitted score (%d) for %s. Skipping." % [score, SaveManager.get_last_submitted_score(mode), mode])
		return
		
	# Check if mode is already queued
	for item in _submit_queue:
		if item["mode"] == mode:
			if score > item["score"]:
				item["score"] = score # Queue the higher score
			return
			
	_submit_queue.append({"score": score, "mode": mode})
	_process_submit_queue()


func _process_submit_queue() -> void:
	if _is_submitting or _submit_queue.is_empty():
		return
		
	var next = _submit_queue.pop_front()
	var score = next["score"]
	var mode = next["mode"]
	
	var username = SaveManager.get_username()
	if username == "":
		username = "Player_%s" % SaveManager.get_device_uuid().substr(0, 5)
		SaveManager.set_username(username)
		
	var device_id = SaveManager.get_device_uuid()
	
	# Create document payload according to Firestore REST API JSON structure
	var document = {
		"fields": {
			"username": {"stringValue": username},
			"score": {"integerValue": str(score)},
			"country_code": {"stringValue": player_country_code},
			"country_name": {"stringValue": player_country_name},
			"continent_code": {"stringValue": player_continent_code},
			"device_id": {"stringValue": device_id},
			"timestamp": {"integerValue": str(int(Time.get_unix_time_from_system()))}
		}
	}
	
	var headers: PackedStringArray = [
		"Content-Type: application/json"
	]
	
	if not _require_core_config("submit score"):
		score_submitted.emit(false)
		return
	var collection: String = _core_config.get_collection(mode)
	if collection.is_empty():
		push_error("LeaderboardManager: missing leaderboard collection for mode %s" % mode)
		score_submitted.emit(false)
		return
	var url: String = _get_firestore_docs_url() + "/" + collection + "/" + device_id + "?key=" + String(_core_config.get("firestore_api_key"))
	
	_is_submitting = true
	_submit_request.set_meta("submitted_score", score)
	_submit_request.set_meta("submitted_mode", mode)
	
	print("LeaderboardManager: Submitting score %d for %s (mode: %s, collection: %s, device: %s)..." % [score, username, mode, collection, device_id])
	var err = _submit_request.request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify(document))
	if err != OK:
		_is_submitting = false
		push_warning("LeaderboardManager: Failed to start score submit request (err %d)" % err)
		score_submitted.emit(false)
		_process_submit_queue()


func fetch_leaderboard(tab: String, mode: String = GameState.start_mode) -> void:
	# Auto-submit any unsubmitted high score first
	var best = SaveManager.get_best_score(mode)
	if _is_submitting:
		print("LeaderboardManager: A score submission is already in progress. Waiting for it...")
		await score_submitted
	elif best > SaveManager.get_last_submitted_score(mode):
		print("LeaderboardManager: Found unsubmitted high score %d for %s. Submitting first..." % [best, mode])
		submit_score(best, mode)
		await score_submitted
		
	if not _require_core_config("fetch leaderboard"):
		leaderboard_loaded.emit(tab, [], mode)
		return

	# tab can be: "world", "continent", "country"
	var query_url := _get_firestore_docs_url() + ":runQuery?key=" + String(_core_config.get("firestore_api_key"))
	var collection: String = _core_config.get_collection(mode)
	if collection.is_empty():
		push_error("LeaderboardManager: missing leaderboard collection for mode %s" % mode)
		leaderboard_loaded.emit(tab, [], mode)
		return
	
	var structured_query = {
		"structuredQuery": {
			"from": [{"collectionId": collection}],
			"orderBy": [{
				"field": {"fieldPath": "score"},
				"direction": _core_config.get_sort_direction(mode)
			}],
			"limit": int(_core_config.get("leaderboard_limit"))
		}
	}
	
	# Add regional filters for continent/country tabs
	if tab == "continent" and player_continent_code != "":
		structured_query["structuredQuery"]["where"] = {
			"fieldFilter": {
				"field": {"fieldPath": "continent_code"},
				"op": "EQUAL",
				"value": {"stringValue": player_continent_code}
			}
		}
	elif tab == "country" and player_country_code != "":
		structured_query["structuredQuery"]["where"] = {
			"fieldFilter": {
				"field": {"fieldPath": "country_code"},
				"op": "EQUAL",
				"value": {"stringValue": player_country_code}
			}
		}
		
	var headers: PackedStringArray = [
		"Content-Type: application/json"
	]
	
	# Save the active tab and mode as metadata in the request
	_query_request.set_meta("active_tab", tab)
	_query_request.set_meta("active_mode", mode)
	
	print("LeaderboardManager: Fetching leaderboard tab: %s (mode: %s, collection: %s)..." % [tab, mode, collection])
	var err = _query_request.request(query_url, headers, HTTPClient.METHOD_POST, JSON.stringify(structured_query))
	if err != OK:
		push_warning("LeaderboardManager: Failed to start query request (err %d)" % err)
		leaderboard_loaded.emit(tab, [], mode)


# Callbacks
func _on_geo_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.get_data()
			if data is Dictionary:
				player_country_code = data.get("country_code", "")
				player_country_name = data.get("country_name", "")
				player_continent_code = data.get("continent_code", "")
				
				# Cache it
				SaveManager.set_country_code(player_country_code)
				SaveManager.set_country_name(player_country_name)
				SaveManager.set_continent_code(player_continent_code)
				
				print("LeaderboardManager: Resolved geolocation to %s (%s, %s)" % [player_country_name, player_country_code, player_continent_code])
				geolocation_resolved.emit()
				return
	
	print("LeaderboardManager: Geolocation request failed. Keeping cached/blank region; no fallback country is invented.")
	geolocation_resolved.emit()


func _on_submit_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	_is_submitting = false
	var submitted_mode = _submit_request.get_meta("submitted_mode") if _submit_request.has_meta("submitted_mode") else "classic"
	if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 201 or response_code == 204):
		print("LeaderboardManager: Score submitted successfully for %s! Response code: %d" % [submitted_mode, response_code])
		var submitted_score = _submit_request.get_meta("submitted_score") if _submit_request.has_meta("submitted_score") else 0
		if submitted_score > SaveManager.get_last_submitted_score(submitted_mode):
			SaveManager.set_last_submitted_score(submitted_score, submitted_mode)
		score_submitted.emit(true)
	else:
		var body_str = body.get_string_from_utf8()
		push_warning("LeaderboardManager: Score submission failed for %s (result %d, response code %d). Body: %s" % [submitted_mode, result, response_code, body_str])
		score_submitted.emit(false)
		
	# Process next queue item
	_process_submit_queue()


func _on_query_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var tab = _query_request.get_meta("active_tab") if _query_request.has_meta("active_tab") else "world"
	var mode = _query_request.get_meta("active_mode") if _query_request.has_meta("active_mode") else "classic"
	var parsed_scores = []
	
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.get_data()
			if data is Array:
				for item in data:
					if item is Dictionary and item.has("document"):
						var doc = item["document"]
						if doc.has("fields"):
							var fields = doc["fields"]
							var username = fields.get("username", {}).get("stringValue", "Anonymous")
							var score = int(fields.get("score", {}).get("integerValue", "0"))
							var country_code = fields.get("country_code", {}).get("stringValue", "")
							var country_name = fields.get("country_name", {}).get("stringValue", "")
							parsed_scores.append({
								"username": username,
								"score": score,
								"country_code": country_code,
								"country_name": country_name
							})
		print("LeaderboardManager: Fetched %d scores for tab %s (%s) successfully!" % [parsed_scores.size(), tab, mode])
	else:
		var body_str = body.get_string_from_utf8()
		push_warning("LeaderboardManager: Query failed (result %d, response code %d). Body: %s" % [result, response_code, body_str])
	leaderboard_loaded.emit(tab, parsed_scores, mode)


func _load_core_config() -> bool:
	_core_config = load(GAME_CORE_CONFIG_PATH)
	if _core_config == null:
		push_error("LeaderboardManager: missing GameCoreConfig at %s" % GAME_CORE_CONFIG_PATH)
		return false
	if _core_config.has_method("validate_config"):
		var errors: Array = _core_config.validate_config()
		if not errors.is_empty():
			push_error("LeaderboardManager: invalid GameCoreConfig: %s" % ", ".join(errors))
			return false
	return true


func _require_core_config(action: String) -> bool:
	if _core_config != null:
		return true
	push_error("LeaderboardManager: cannot %s without GameCoreConfig" % action)
	return false


func _get_firestore_docs_url() -> String:
	return "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents" % String(_core_config.get("firebase_project_id"))
