extends Node2D
class_name Map

signal map_loaded

@onready var tilemap := $TileMapLayer as TileMapLayer
var is_loaded = false

func bound_rect() -> Rect2:
	var used_rect := tilemap.get_used_rect()
	var tile_size := tilemap.tile_set.tile_size
	return Rect2(used_rect.position * tile_size, used_rect.size * tile_size) * transform
	

func initialize_map(map: String) -> void:
	var json = JSON.new()
	if json.parse(map) != OK:
		print("error parsing map!")
		return
	
	if 'rows' not in json.data:
		print("error: no rows in map")
		return
	var height: int = len(json.data['rows'])
	if height == 0:
		print("error: map is empty")
		return
	var width: int = len(json.data['rows'][0])
	if width == 0:
		print("error: map is empty")
		return
	
	var y: int = -1
	for row in json.data['rows']:
		y += 1	
		if width != len(row):
			print("error: inconsistent width - map is not a square, i cannot do that")
			return
			
		var x: int = -1
		for tile in row:
			x += 1
			if tile == 0:
				tilemap.set_cell(Vector2i(x, y), 0, Vector2i(randi_range(0, 3), randi_range(0, 3)))
			elif tile == 1:
				tilemap.set_cell(Vector2i(x, y), 3, Vector2i(0, 0))
			else:
				print('unknown tile type: {}'.format(tile))

	is_loaded = true
	
	map_loaded.emit()
