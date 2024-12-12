extends VBoxContainer

@onready var login_container := $LoginContainer as Container
@onready var user_info_container := $UserInfoContainer as Container
@onready var loading_container := $LoadingContainer as Container
@onready var data_access := get_tree().root.get_node("DataAccess") as BattleDataAccess

@onready var login_lineedit := $LoginContainer/login as LineEdit
@onready var password_lineedit := $LoginContainer/password as LineEdit
@onready var password2_lineedit := $LoginContainer/password2 as LineEdit
@onready var invite_lineedit := $LoginContainer/invite as LineEdit
@onready var error_label := $error_label as Label

@onready var user_label := $UserInfoContainer/UserLabel as Label

var _error_tween = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	login_container.visible = false
	user_info_container.visible = false
	loading_container.visible = false
	recheck_user_info()

func _show_loading_stuff():
	login_container.visible = false
	user_info_container.visible = false
	loading_container.visible = true

func recheck_user_info():
	_show_loading_stuff()
	data_access.get_user_info(_user_info_received)

func _user_info_received(user: BattleDataAccess.User, error):
	login_container.visible = false
	user_info_container.visible = false
	loading_container.visible = false
	if user == null:
		if error is BattleDataAccess.BackendNotAvailableError:
			login_container.visible = false
			_show_error("server is down", 60)
		else:
			login_container.visible = true
	else:
		user_info_container.visible = true
		user_label.text = user.name
		if user.is_admin:
			user_label.text += "(admin)"

func _login_attempt_completed(success: bool, error):
	# TODO: write error if needed
	print("tried to login: {0}".format([success]))
	if error != null and is_instance_of(error, DataAccess.Error):
		_show_error(error.text)
	recheck_user_info()

func _logout_attempt_completed(success: bool, error):
	# TODO: write error if needed
	print("tried to logout: {0}".format([success]))
	if error != null and is_instance_of(error, DataAccess.Error):
		_show_error(error.text)
	recheck_user_info()

func _show_error(text: String, timeout: float = 5):
	error_label.text = text
	error_label.visible = true
	error_label.modulate.a = 1
	if _error_tween != null:
		_error_tween.kill()
	_error_tween = create_tween()
	_error_tween.tween_property(error_label, "modulate:a", 0, timeout/2).set_delay(timeout/2)
	_error_tween.tween_callback(error_label.hide)

func _on_login_btn_pressed() -> void:
	_show_loading_stuff()
	var login := login_lineedit.text
	var password := password_lineedit.text
	login_lineedit.text = ""
	password_lineedit.text = ""
	password2_lineedit.text = ""
	password2_lineedit.hide()
	data_access.login(login, password, _login_attempt_completed)


func _on_logout_btn_pressed() -> void:
	_show_loading_stuff()
	data_access.logout(_logout_attempt_completed)


func _on_register_btn_pressed() -> void:
	var login := login_lineedit.text
	var password := password_lineedit.text
	if len(password) < 10:
		# TODO: properly validate password quality
		_show_error("password must be longer than 10 chars")
		return
	var password2 := password2_lineedit.text
	if password2 != password:
		password2_lineedit.show()
		invite_lineedit.show()
		_show_error("passwords do not match")
		return
	var invite := invite_lineedit.text
	password_lineedit.text = ""
	password2_lineedit.text = ""
	password2_lineedit.hide()
	invite_lineedit.text = ""
	invite_lineedit.hide()
	data_access.register_new_user(login, password, invite, _login_attempt_completed)


func _on_delete_user_btn_pressed() -> void:
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.dialog_text = "Delete your user?\nAll your programs will be deleted too\nYou will not be able to reuse this user name\nThis action is irreversible!"
	confirm_dialog.title = "are you sure sure??"
	confirm_dialog.add_cancel_button("cancel!")
	get_tree().root.add_child(confirm_dialog)
	confirm_dialog.popup_centered()
	confirm_dialog.close_requested.connect(confirm_dialog.queue_free)
	confirm_dialog.confirmed.connect(
		func():
			data_access.delete_user_forever(
				_logout_attempt_completed
			)
	)
