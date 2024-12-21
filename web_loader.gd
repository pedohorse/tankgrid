extends Node

@onready var data_access := get_tree().root.get_node("DataAccess") as BattleDataAccess
@onready var http_request = $HTTPRequest
@onready var loading_label := $CenterContainer/loading_label as RichTextLabel
@onready var container := $CenterContainer as CenterContainer
var battle_log: String
var map: String
var viewer_asset = preload("res://assets/viewer.tscn")

func _ready() -> void:
	var log_id_str: String = JavaScriptBridge.eval("""
		url = new URL(window.location)
		url.searchParams.get("battle_id") || ""
	""")
	print("got battle_id={0}".format([log_id_str]))
	if not log_id_str.is_valid_int():
		loading_label.text = "Not a valid battle ID"
		return
	print("loading battle {0}".format([log_id_str]))
	
	http_request.connect("request_completed", response_received, CONNECT_ONE_SHOT)
	http_request.request("{0}/api/battle/log/{1}".format([data_access.api_host, int(log_id_str)]))


func response_received(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != HTTPClient.RESPONSE_OK:
		print("failed to load scene")
		loading_label.text = "Failed to find the battle log"
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if data['status'] != "ok":
		print("failed to load scene")
		loading_label.text = "Failed to find the battle log"
		return
	battle_log = data['battle_log']
	map = data['map']
	
	print("fetch data done")
	var viewer := viewer_asset.instantiate() as Viewer
	add_child(viewer)
	viewer.initialize_viewer(map, battle_log)
	loading_label.visible = false
