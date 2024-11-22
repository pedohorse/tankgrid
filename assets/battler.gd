extends Node2D
class_name Battler

signal play_time_changed(int)

@export var tank_object: PackedScene
@export var ammocrate_sprite: Texture2D
@export var tile_size: int = 250

var playback_speed_multiplier: int = 1
var log_end_time: int = -1

class BaseAction:
	var start_time: int
	var end_time: int
	
	func apply_action(_node: Node2D, _time: int):
		push_warning("base method called!")
	
class MoveAction extends BaseAction:
	var from_p: Vector2
	var to_p: Vector2
	var from_r: float
	var to_r: float
	
	func apply_action(node: Node2D, time: int):
		if start_time >= time:
			node.position = from_p
			node.rotation_degrees = from_r
		elif end_time <= time:
			node.position = to_p
			node.rotation_degrees = to_r
		else:
			var t = (time - start_time)*1.0/(end_time - start_time)
			node.position = lerp(from_p, to_p, t)
			node.rotation_degrees = lerp(from_r, to_r, t)

class SpawnAction extends BaseAction:
	var p: Vector2
	var r: float
	
	func apply_action(node: Node2D, time: int):
		node.visible = time >= end_time
		node.position = p
		node.rotation_degrees = r

class DieAction extends BaseAction:
	func apply_action(node: Node2D, time: int):
		node.visible = time < end_time
		if time < start_time:
			node.scale = Vector2.ONE
		elif time >= end_time:
			node.scale = Vector2.ZERO
		else:
			var t = (time - start_time)*1.0/(end_time - start_time)
			node.scale = Vector2.ONE * (1-t)

class PickedAction extends BaseAction:
	func apply_action(node: Node2D, time: int):
		node.visible = time < end_time
		if time < start_time:
			node.scale = Vector2.ONE
		elif time >= end_time:
			node.scale = Vector2.ZERO
		else:
			var t = (time - start_time)*1.0/(end_time - start_time)
			node.scale = Vector2.ONE * (1-t)

class ShootAction extends BaseAction:
	var line_from: Vector2
	var line_to: Vector2
	
	func apply_action(node: Node2D, time: int):
		var maybe_child_trace := node.find_child("bullet_trace", false, false) as Line2D # TODO: this can be optimized
		var maybe_muzzleflash := node.find_child("muzzleflash", false, false) as Node2D
		var t = (time - start_time)*1.0/(end_time - start_time)
		if time < start_time:
			if maybe_child_trace != null:
				maybe_child_trace.visible = false
			if maybe_muzzleflash != null:
				maybe_muzzleflash.visible = false
		elif time >= end_time:
			if maybe_child_trace != null:
				maybe_child_trace.visible = false
			if maybe_muzzleflash != null:
				maybe_muzzleflash.visible = false
		else:
			if maybe_child_trace != null:
				maybe_child_trace.visible = 0.1 < t and t < 0.9

				print(node.position, " ", line_from, " ", node.transform.inverse() * line_from)
				maybe_child_trace.set_point_position(0, node.transform.inverse() * line_from)
				maybe_child_trace.set_point_position(1, node.transform.inverse() * line_to)
			if maybe_muzzleflash != null:
				maybe_muzzleflash.visible = 0.1 < t and t < 0.75


class MapObject:
	var id: int
	var sprite: Node2D
	var actions: Array
	var cur_action: int = 0
	# to keep track of parsed state
	var last_parsed_p: Vector2
	var last_parsed_r: float

var log_lines: Array[PackedStringArray] = []
var next_log_line: int = 0
var log_time: int = -1  # represents what log line we read
var play_log_delay = 50  # log is ahead of play
var play_time: int = log_time - play_log_delay;  # play time is for anim, we can be behind log time
var objects: Dictionary = {}
var next_action_durations: Dictionary = {}
var act_regex := RegEx.create_from_string(r'^\w+(?:\[(?<args>.*)\])?(?:\((?<id>.*)\))?$')
var is_loaded := false

@onready var play_timer: Timer = $BattleTimer as Timer

func initialize_battle(battle_log: String) -> void:
	#var file := FileAccess.open(battle_log_path, FileAccess.READ)
	#while not file.eof_reached():
	#	var next_line := file.get_csv_line("\t")
	#	if len(next_line) != 4:  # skip unknown lines
	#		continue
	#	log_lines.append(next_line)
	for line in battle_log.replace("\r", "").split("\n"):
		var next_line := line.split("\t")
		if len(next_line) != 4:  # skip unknown lines
			continue
		log_lines.append(next_line)
	
	is_loaded = true
	# wind play time to zero
	if play_time < 0:
		progress_play_time(-play_time)

func orientation_to_angle(ori: String) -> float:
	if ori == 'north':
		return 0
	elif ori == 'east':
		return 90
	elif ori == 'south':
		return 180
	elif ori == 'west':
		return -90
	else:
		print("error, unknown orientation: {0}".format([ori]))
	return 0

func _parse_next_line() -> void:
	if log_ended():
		return
		
	var line := log_lines[next_log_line]
	print("next log line: {0}".format([line]))
	next_log_line += 1
	var subject: String = line[0]
	var action: String = line[1]
	# TODO: time and durations
	if action.begins_with('-'):
		var mp := act_regex.search(subject)
		var id := mp.get_string('id')
		next_action_durations[id] = int(line[3])
	elif action.begins_with('spawn['):
	
		var ma := act_regex.search(action)
		var mp := act_regex.search(subject)
		var id := mp.get_string('id')
		
		var args := ma.get_string('args').split(',')
		var x := int(args[0])
		var y := int(args[1])
		var angle := orientation_to_angle(args[2])

		var sprite = null
		if line[0].begins_with('player['):
			sprite = tank_object.instantiate()
			add_child(sprite)
			sprite.set_color(Color.from_hsv(randf(), 0.5+0.5*randf(), 1))
		elif line[0].begins_with('ammocrate'):
			sprite = Sprite2D.new()
			sprite.texture = ammocrate_sprite
			add_child(sprite)
		#sprite.position = Vector2(x*tile_size + tile_size*0.5, y*tile_size + tile_size*0.5)
		#sprite.rotation_degrees = angle
		sprite.visible = false
		
		var obj = MapObject.new()
		obj.id = id
		obj.sprite = sprite
		var objaction := SpawnAction.new()
		objaction.start_time = int(line[2])
		objaction.end_time = objaction.start_time
		objaction.p = Vector2(x*tile_size + tile_size*0.5, y*tile_size + tile_size*0.5)
		objaction.r = angle
		obj.last_parsed_p = objaction.p
		obj.last_parsed_r = objaction.r
		obj.actions.append(objaction)
		objects[id] = obj
	elif action.begins_with('move['):
		var ma := act_regex.search(action)
		var mp := act_regex.search(subject)
		var id := mp.get_string('id')
		
		var args := ma.get_string('args').split(',')
		var x := int(args[0])
		var y := int(args[1])
		
		var obj: MapObject = objects[id]
		#var tween := obj.sprite.create_tween()
		#tween.tween_property(obj.sprite, "position", Vector2(x*tile_size + tile_size*0.5, y*tile_size + tile_size*0.5), 0.25)
		var objaction := MoveAction.new()
		objaction.end_time = int(line[2])
		objaction.start_time = objaction.end_time - next_action_durations[id]
		objaction.from_p = obj.last_parsed_p
		objaction.to_p = Vector2(x*tile_size + tile_size*0.5, y*tile_size + tile_size*0.5)
		objaction.from_r = obj.last_parsed_r
		objaction.to_r = objaction.from_r
		obj.last_parsed_p = objaction.to_p
		obj.actions.append(objaction)
		
	elif action.begins_with('turn['):
		var ma := act_regex.search(action)
		var mp := act_regex.search(subject)
		var id := mp.get_string('id')
		
		var args := ma.get_string('args').split(',')
		var angle := orientation_to_angle(args[0])
		
		var obj: MapObject = objects[id]

		if angle - obj.last_parsed_r > 180:
			angle -= 360
		elif angle - obj.last_parsed_r < -180:
			angle += 360

		var objaction := MoveAction.new()
		objaction.end_time = int(line[2])
		objaction.start_time = objaction.end_time - next_action_durations[id]
		objaction.from_p = obj.last_parsed_p
		objaction.to_p = objaction.from_p
		objaction.from_r = obj.last_parsed_r
		objaction.to_r = angle
		obj.last_parsed_r = fmod(objaction.to_r, 360)
		obj.actions.append(objaction)

	elif action.begins_with('picked'):
		var mp := act_regex.search(subject)
		var id := mp.get_string('id')
		
		var obj: MapObject = objects[id]
		#obj.sprite.queue_free()
		#objects.erase(id)
		var objaction := PickedAction.new()
		objaction.end_time = int(line[2])
		objaction.start_time = objaction.end_time - 5 # NOTE: we add extra anim time
		obj.actions.append(objaction)
	elif action.begins_with('die'):
		var mp := act_regex.search(subject)
		var id := mp.get_string('id')
		
		var obj: MapObject = objects[id]
		#obj.sprite.queue_free()
		#objects.erase(id)
		var objaction := DieAction.new()
		objaction.end_time = int(line[2])
		objaction.start_time = objaction.end_time - 5 # NOTE: we add extra anim time
		obj.actions.append(objaction)
	elif action.begins_with('shoot['):
		var mp := act_regex.search(subject)
		var ma := act_regex.search(action)
		var id := mp.get_string('id')
		
		var args := ma.get_string('args').split(',')
		var obj: MapObject = objects[id]

		var objaction := ShootAction.new()
		objaction.end_time = int(line[2])
		objaction.start_time = objaction.end_time - next_action_durations[id]
		objaction.line_from = Vector2(float(args[0]) + 0.5, float(args[1]) + 0.5) * tile_size
		objaction.line_to = Vector2(float(args[2]) + 0.5, float(args[3]) + 0.5) * tile_size
		obj.actions.append(objaction)
	
	log_time = int(line[2])

func get_next_log_line_time() -> int:
	return int(log_lines[next_log_line][2])

func log_ended() -> bool:
	return len(log_lines) <= next_log_line

func progress_log_time():
	if !is_loaded:
		return
	log_time += 1
	while not log_ended() and get_next_log_line_time() <= log_time:
		_parse_next_line()
	if log_ended() and log_end_time < 0:
		log_end_time = log_time

func progress_play_time(shift: int = 1):
	if !is_loaded:
		return
	play_time += shift
	while play_time + play_log_delay > log_time:
		progress_log_time()
	# now - update all animations
	for obj_id in objects:
		var obj: MapObject = objects[obj_id]
		if len(obj.actions) == 0:
			continue
		if shift > 0:
			for i in range(obj.cur_action, len(obj.actions)):
				var action: BaseAction = obj.actions[i]
				if play_time < action.start_time:
					break
				action.apply_action(obj.sprite, play_time)
				if play_time >= action.end_time:
					obj.cur_action += 1
					if obj.cur_action >= len(obj.actions):
						obj.cur_action = len(obj.actions) - 1
		elif shift < 0:
			for i in range(obj.cur_action, 0, -1):
				# cur_action may point to NEXT action to happen, which was not yet created from the log
				if i == len(obj.actions):
					continue
				var action: BaseAction = obj.actions[i]
				if play_time >= action.end_time:
					break
				action.apply_action(obj.sprite, play_time)
				if play_time < action.start_time:
					obj.cur_action -= 1

	play_time_changed.emit(play_time)

func set_play_time(time: int):
	if !is_loaded:
		return
	if time < 0:
		time = 0
	progress_play_time(time - play_time)

func set_playback_speed(value: float) -> void:
	# not relying on timer since timer won't work well with small numbers
	playback_speed_multiplier = round(value)


func _on_battle_timer_timeout() -> void:
	if playback_speed_multiplier == 0:
		return
	elif playback_speed_multiplier > 0:
		if log_end_time >= 0 and play_time >= log_end_time:
			play_timer.stop()
			return
		progress_play_time(playback_speed_multiplier)
	else:
		if play_time <= 0:
			play_timer.stop()
			return
		progress_play_time(max(playback_speed_multiplier, -play_time))


func _on_playpause_button_pressed() -> void:
	if play_timer.is_stopped():
		play_timer.start()
	else:
		play_timer.stop()


func _on_time_step_button_pressed() -> void:
	progress_play_time()


func _on_time_step_back_pressed() -> void:
	progress_play_time(-1)


func _on_time_meter_value_changed(value: float) -> void:
	set_play_time(int(value))
