extends Node2D
class_name Tank

@onready var body: Sprite2D = $body as Sprite2D
@onready var tower: Sprite2D = $tower as Sprite2D
@onready var name_label: Label = $name as Label
@onready var logbox: Container = $logbox as Container

func set_color(color: Color):
	body.modulate = color
	tower.modulate = color

func set_tank_name(name: String):
	name_label.text = name

func push_log_line(line: String):
	var logline = Label.new()
	logline.text = line
	logbox.add_child(logline)
	logbox.move_child(logline, 0)
	var tween = logline.create_tween()
	tween.tween_callback(
		func():
			logline.queue_free()
	).set_delay(10)
