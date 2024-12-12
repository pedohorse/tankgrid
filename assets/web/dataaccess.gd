extends Node
class_name BattleDataAccess

signal logged_in(User)
signal logged_out

@export var _session: String = ""
@export var api_host: String = "http://127.0.0.1:8001"
var _user = null


class User:
	var name: String
	var is_admin: bool

class ProgramMeta:
	var id: int
	var name: String
	var game_version: String

class Error:
	var text: String
	
class BackendNotAvailableError extends Error:
	pass

func _ready() -> void:
	if FileAccess.file_exists("user://session"):
		_session = FileAccess.get_file_as_string("user://session")
		get_user_info(_get_user_after_login)
	
	
func set_session(new_session: String):
	var file := FileAccess.open("user://session", FileAccess.WRITE)
	file.store_string(new_session)
	file.close()
	_session = new_session


func _common_headers() -> PackedStringArray:
	return PackedStringArray(["Authorization: token {0}".format([_session])])


func _get_user_after_login(user, error):
	if user == null:
		# something is very wrong
		logout(null)
		return
	_user = user
	logged_in.emit(_user)


func logged_in_user():
	return _user


func get_user_info(callback):
	if _session == "":
		if callback != null:
			var error = Error.new()
			error.text = "no session"
			callback.call(null, error)
		return
		
	var req = HTTPRequest.new()
	add_child(req)
	req.request(api_host + "/api/user", _common_headers(), HTTPClient.METHOD_GET)
	req.request_completed.connect(
		func(result, response_code, _headers, body):
			if response_code != HTTPClient.RESPONSE_OK or result != HTTPRequest.RESULT_SUCCESS:
				if callback != null:
					var error = BackendNotAvailableError.new()
					error.text = "failed to connect"
					callback.call(null, error)
				return
			var reply: Dictionary = JSON.parse_string(body.get_string_from_utf8())
			if reply.get("status", "fail") != "ok":
				if callback != null:
					var error = Error.new()
					error.text = reply.get("reason", "unknown reason")
					callback.call(null, error)
				return
			
			var user = User.new()
			user.name = reply.get("user", "unknown")
			user.is_admin = reply.get("is_admin", "false") == "true"
			if callback != null:
				callback.call(user, null)
			
			req.queue_free()
	)

func get_programs(callback):
	if _session == "":
		if callback != null:
			callback.call(null)
		return
		
	var req = HTTPRequest.new()
	add_child(req)
	req.request(api_host + "/api/programs", _common_headers(), HTTPClient.METHOD_GET)
	req.request_completed.connect(
		func(result, response_code, _headers, body):
			var prog_metas: Array[ProgramMeta] = []
			if response_code != HTTPClient.RESPONSE_OK or result != HTTPRequest.RESULT_SUCCESS:
				if callback != null:
					callback.call(prog_metas)
				return
			var reply: Dictionary = JSON.parse_string(body.get_string_from_utf8())
			if reply.get("status", "fail") != "ok":
				if callback != null:
					callback.call(prog_metas)
				return
			
			for prog_data in reply.get("programs", []):
				var meta := ProgramMeta.new()
				meta.id = prog_data["id"]
				meta.name = prog_data["name"]
				meta.game_version = prog_data["version"]
				prog_metas.append(meta)
			
			if callback != null:
				callback.call(prog_metas)
			
			req.queue_free()
	)

func get_battle_statistics(callback):		
	var req = HTTPRequest.new()
	add_child(req)
	req.request(api_host + "/api/battle/top", _common_headers(), HTTPClient.METHOD_GET)
	req.request_completed.connect(
		func(result, response_code, _headers, body):
			if response_code != HTTPClient.RESPONSE_OK or result != HTTPRequest.RESULT_SUCCESS:
				if callback != null:
					callback.call(null)
				return
			var reply: Dictionary = JSON.parse_string(body.get_string_from_utf8())
			if reply.get("status", "fail") != "ok":
				if callback != null:
					callback.call(null)
				return
			
			if callback != null:
				# TODO: make a proper struct wrapper for it instead of having an untyped dict
				callback.call(reply.get('battles'))
			
			req.queue_free()
	)

func delete_program(prog_id: int, callback):
	if _session == "":
		if callback != null:
			callback.call(false)
		return
		
	var req = HTTPRequest.new()
	add_child(req)
	req.request(api_host + "/api/program/{0}".format([prog_id]), _common_headers(), HTTPClient.METHOD_DELETE, JSON.stringify(
		{
			"program_id": prog_id
		}
	))
	req.request_completed.connect(
		func(result, response_code, _headers, body):
			if response_code != HTTPClient.RESPONSE_OK or result != HTTPRequest.RESULT_SUCCESS:
				if callback != null:
					callback.call(false)
				return
			var reply: Dictionary = JSON.parse_string(body.get_string_from_utf8())
			if reply.get("status", "fail") != "ok":
				if callback != null:
					callback.call(false)
				return
			
			if callback != null:
				callback.call(true)
			
			req.queue_free()
	)

func upload_program(prog_name: String, code: String, callback):
	if _session == "":
		if callback != null:
			callback.call(null)
		return
		
	var req = HTTPRequest.new()
	add_child(req)
	req.request(api_host + "/api/program", _common_headers(), HTTPClient.METHOD_POST, JSON.stringify(
		{
			"code": code,
			"name": prog_name,
		}
	))
	req.request_completed.connect(
		func(result, response_code, _headers, body):
			if response_code != HTTPClient.RESPONSE_OK or result != HTTPRequest.RESULT_SUCCESS:
				if callback != null:
					callback.call(null)
				return
			var reply: Dictionary = JSON.parse_string(body.get_string_from_utf8())
			if reply.get("status", "fail") != "ok":
				if callback != null:
					callback.call(null)
				return
			
			if callback != null:
				callback.call(int(reply["program_id"]))
			
			req.queue_free()
	)

func register_new_user(username: String, password: String, invite: String, callback):
	var req = HTTPRequest.new()
	add_child(req)
	var login_data = {
		"user": username,
		"pass": password,
		"invite": invite,
	}
	req.request(api_host + "/api/register", _common_headers(), HTTPClient.METHOD_POST, JSON.stringify(login_data))
	req.request_completed.connect(
		func(result, response_code, _headers, body):
			if response_code != HTTPClient.RESPONSE_OK or result != HTTPRequest.RESULT_SUCCESS:
				if callback != null:
					var error := Error.new()
					error.text = "bad server response"
					callback.call(false, error)
				return
			var reply: Dictionary = JSON.parse_string(body.get_string_from_utf8())
			if reply.get("status", "fail") != "ok":
				if callback != null:
					var error = Error.new()
					error.text = reply.get("reason", "unknown error")
					callback.call(false, error)
				return

			login(username, password, callback)

			req.queue_free()
	)

func login(username: String, password: String, callback):
	var req = HTTPRequest.new()
	add_child(req)
	var login_data = {
		"user": username,
		"pass": password,
	}
	req.request(api_host + "/api/login", _common_headers(), HTTPClient.METHOD_POST, JSON.stringify(login_data))
	req.request_completed.connect(
		func(result, response_code, _headers, body):
			if response_code != HTTPClient.RESPONSE_OK or result != HTTPRequest.RESULT_SUCCESS:
				if callback != null:
					var error := Error.new()
					error.text = "bad server response"
					callback.call(false, error)
				return
			var reply: Dictionary = JSON.parse_string(body.get_string_from_utf8())
			if reply.get("status", "fail") != "ok" or not reply.has("session"):
				if callback != null:
					var error = Error.new()
					error.text = reply.get("reason", "unknown error")
					callback.call(false, error)
				return
			
			set_session(reply["session"])
			if callback != null:
				callback.call(true, null)
				
			get_user_info(_get_user_after_login)
			
			req.queue_free()
	)


func logout(callback):
	var req = HTTPRequest.new()
	add_child(req)
	req.request(api_host + "/api/logout", _common_headers(), HTTPClient.METHOD_POST)
	req.request_completed.connect(
		func(result, response_code, _headers, body):
			if response_code != HTTPClient.RESPONSE_OK or result != HTTPRequest.RESULT_SUCCESS:
				if callback != null:
					var error := Error.new()
					error.text = "bad server response"
					callback.call(false, error)
				return
			var reply: Dictionary = JSON.parse_string(body.get_string_from_utf8())
			if reply.get("status", "fail") != "ok":
				if callback != null:
					var error = Error.new()
					error.text = reply.get("reason", "unknown error")
					callback.call(false, error)
				return

			set_session("")
			if callback != null:
				callback.call(true, null)

			logged_out.emit()

			req.queue_free()
	)


func delete_user_forever(callback):
	var req = HTTPRequest.new()
	add_child(req)
	req.request(api_host + "/api/user", _common_headers(), HTTPClient.METHOD_DELETE)
	req.request_completed.connect(
		func(result, response_code, _headers, body):
			if response_code != HTTPClient.RESPONSE_OK or result != HTTPRequest.RESULT_SUCCESS:
				if callback != null:
					var error := Error.new()
					error.text = "bad server response"
					callback.call(false, error)
				return
			var reply: Dictionary = JSON.parse_string(body.get_string_from_utf8())
			if reply.get("status", "fail") != "ok":
				if callback != null:
					var error = Error.new()
					error.text = reply.get("reason", "unknown error")
					callback.call(false, error)
				return

			set_session("")
			if callback != null:
				callback.call(true, null)

			logged_out.emit()

			req.queue_free()
	)


func get_time_to_battle(callback):
	var req = HTTPRequest.new()
	add_child(req)
	req.request(api_host + "/api/time_to_next_battle", _common_headers(), HTTPClient.METHOD_GET)
	req.request_completed.connect(
		func(result, response_code, _headers, body):
			if response_code != HTTPClient.RESPONSE_OK or result != HTTPRequest.RESULT_SUCCESS:
				if callback != null:
					var error = BackendNotAvailableError.new()
					error.text = "failed to connect"
					callback.call(0, error)
				return
			var reply: Dictionary = JSON.parse_string(body.get_string_from_utf8())
			if reply.get("status", "fail") != "ok":
				if callback != null:
					var error = Error.new()
					error.text = reply.get("reason", "unknown reason")
					callback.call(0, error)
				return

			var time_remaining = int(reply.get("time_remaining", -1))
			if callback != null:
				callback.call(time_remaining, null)

			req.queue_free()
	)
