extends Node2D

@onready var body: Sprite2D = $body as Sprite2D
@onready var tower: Sprite2D = $tower as Sprite2D

func set_color(color: Color):
	body.modulate = color
	tower.modulate = color
