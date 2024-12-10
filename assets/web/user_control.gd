extends VBoxContainer

@onready var data_access := get_tree().root.get_node("DataAccess") as BattleDataAccess
@onready var program_list := $ProgramList as Container
@onready var control_container := $ControlContainer as Container
@onready var name_input := $ControlContainer/NewName as LineEdit

var _file_access = null
var entry_list := preload("res://assets/web/program_list_entry.tscn")

func _ready() -> void:
	program_list.visible = false
	control_container.visible = false
	data_access.logged_in.connect(_on_login)
	data_access.logged_out.connect(_on_logout)

func repopulate() -> void:
	clear()
	data_access.get_programs(_programs_received)

func _programs_received(programs: Array[BattleDataAccess.ProgramMeta]):
	for program in programs:
		var entry := entry_list.instantiate()
		(entry.get_node('LabelId') as Label).text = "id:{0}".format([program.id])
		(entry.get_node('LabelName') as Label).text = program.name
		(entry.get_node('LabelVer') as Label).text = program.game_version
		(entry.get_node('DeleteBtn') as Button).pressed.connect(
			func():
				_confirm_delete(program.id)
		)
		
		program_list.add_child(entry)

func _confirm_delete(id: int):
	var dialog := AcceptDialog.new()
	dialog.dialog_text = "are you sure?"
	dialog.title = "sure sure?"
	dialog.add_cancel_button("cancel!")
	get_tree().root.add_child(dialog)
	dialog.popup_centered()
	dialog.close_requested.connect(dialog.queue_free)
	dialog.confirmed.connect(
		func():
			data_access.delete_program(id, _on_program_deleted)
	)

func _on_program_deleted(success: bool):
	print("program delete status: {0}".format([success]))
	if success:
		repopulate()
		
func _on_program_added(new_id):
	print("program added status: {0}".format([new_id]))
	if new_id != null:
		repopulate()

func clear() -> void:
	for child in program_list.get_children():
		child.queue_free()


func _on_login(_user: BattleDataAccess.User) -> void:
	repopulate()
	program_list.visible = true
	control_container.visible = true
	
	
func _on_logout() -> void:
	clear()
	program_list.visible = false


func _on_add_button_pressed() -> void:
	var prog_name := name_input.text
	name_input.text = ""
	prog_name = prog_name.lstrip(" ").rstrip(" ")
	if prog_name == "":
		print("name must not be empty")
		return
	_file_access = FileAccessWeb.new()
	_file_access.loaded.connect(
		func(_file_name: String, _file_type: String, base64_data: String):
			var code := Marshalls.base64_to_utf8(base64_data)
			data_access.upload_program(prog_name, code, _on_program_added)
			_file_access = null
	)
	_file_access.error.connect(
		func():
			_file_access = null
	)
	_file_access.open(".py")
	
	
