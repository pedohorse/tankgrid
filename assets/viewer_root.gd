extends Node2D

@onready var map := $map as Map

var _dragging := false
var _drag_start_pos := Vector2()

func center_map() -> void:
	var rect := map.bound_rect()
	position = get_viewport_rect().get_center() - (rect.size * scale) / 2

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if  event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.is_pressed() and not _dragging:
				_dragging = true
				_drag_start_pos = event.position
			elif not event.is_pressed():
				_dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scale *= 1.05
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scale *= 0.95
	elif event is InputEventMouseMotion and _dragging:
		var offset = event.position - _drag_start_pos
		_drag_start_pos = event.position
		translate(offset)
