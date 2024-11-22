extends Node

@onready var main_container: Container = $CenterContainer as Container

var viewer_asset = preload("res://assets/viewer.tscn")

var map_filepath: String
var log_filepath: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	select_stage1()
	
func select_stage1(cur_dir: String = ""):
	var mapfile_dialog := FileDialog.new()
	mapfile_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	mapfile_dialog.access = FileDialog.ACCESS_FILESYSTEM
	mapfile_dialog.title = 'select map file'
	mapfile_dialog.current_dir = cur_dir
	
	add_child(mapfile_dialog)
	
	mapfile_dialog.file_selected.connect(
		func(path: String):
			map_filepath = path
			mapfile_dialog.queue_free()
			select_stage2(mapfile_dialog.current_dir)
	)
	mapfile_dialog.popup(Rect2i(100, 100, 640, 480))
	
func select_stage2(cur_dir: String = ""):
	var logfile_dialog := FileDialog.new()
	logfile_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	logfile_dialog.access = FileDialog.ACCESS_FILESYSTEM
	logfile_dialog.title = 'select log file'
	logfile_dialog.current_dir = cur_dir
	
	add_child(logfile_dialog)
	
	logfile_dialog.file_selected.connect(
		func(path: String):
			log_filepath = path
			logfile_dialog.queue_free()
			select_stage3()
	)
	logfile_dialog.popup(Rect2i(100, 100, 640, 480))
	
func select_stage3():
	var file = FileAccess.open(map_filepath, FileAccess.READ)
	var map = file.get_as_text()
	file.close()
	file = FileAccess.open(log_filepath, FileAccess.READ)
	var log = file.get_as_text()
	file.close()
	
	var battle_viewer: Viewer = viewer_asset.instantiate()
	main_container.add_child(battle_viewer)
	battle_viewer.initialize_viewer(map, log)
