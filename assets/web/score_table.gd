extends Tree

@onready var data_access := get_tree().root.get_node("DataAccess") as BattleDataAccess
@onready var popup := $BattlePopup as PopupMenu

# NOTE: not nested arrays cuz godot static typing doesn't support it, and i want it
var _battle_datas: Array[DuelData] = []
var _cur_popupped_battle = null

class DuelData:
	var wins: int
	var losses: int
	var draws: int
	var battles: Array[BattleResult]

class BattleResult:
	var winner: int
	var map_id: int
	var battle_id: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	populate()

func populate():
	data_access.get_battle_statistics(_received_battle_statistics)
	
func _received_battle_statistics(battlestat):
	if battlestat == null:
		print("error getting battles")
		return
		
	var labels = battlestat['program_labels']
	var num_labels = len(labels)
	
	columns = num_labels + 1
	
	set_column_custom_minimum_width(0, 64)
	set_column_expand(0, true)
	
	var root := create_item()
	hide_root = true
	var item := create_item(root)
	item.set_text(0, "X")
	
	var i := 1
	for name in labels:
		item.set_text(i, name)
		set_column_custom_minimum_width(i, 32)
		i += 1
	
	_battle_datas = []
	_battle_datas.resize(num_labels * num_labels)
	for k in range(num_labels*num_labels):
		var res = DuelData.new()
		_battle_datas[k] = res
	
	var items: Array[TreeItem] = []
	i = 0
	for name in labels:
		item = create_item(root)
		item.set_text(0, name)
		items.append(item)
		i += 1
	
	for battle_result in battlestat['battle_results']:
		var i1 = battle_result['l1']
		var i2 = battle_result['l2']
		var battle_id = battle_result['b']
		var map_id = battle_result['m']
		var winner = battle_result['w']
		
		var battle_res = BattleResult.new()
		battle_res.battle_id = battle_id
		battle_res.map_id = map_id
		battle_res.winner = winner
		_battle_datas[i2 * num_labels + i1].battles.append(battle_res)
		if winner == 0:
			_battle_datas[i2 * num_labels + i1].draws += 1
		elif winner == 1:
			_battle_datas[i2 * num_labels + i1].wins += 1
		elif winner == 2:
			_battle_datas[i2 * num_labels + i1].losses += 1
		else:
			print("WRONG BATTLE DATA!")
		
	for y in range(num_labels):
		for x in range(num_labels):
			items[y].set_text(x+1, '{0}/{1}/{2}'.format([
				_battle_datas[x * num_labels + y].wins,  # we show win if LEFT label wins over TOP
				_battle_datas[x * num_labels + y].losses,
				_battle_datas[x * num_labels + y].draws,
			]))
			


func _on_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	var pos := get_global_mouse_position()
	var item = get_item_at_position(mouse_position)
	var col = get_column_at_position(mouse_position)
	if item.get_index() == 0 or col == 0:
		return
	var battles = _battle_datas[(item.get_index() - 1) * (columns - 1) + (col - 1)].battles
	popup.clear()
	_cur_popupped_battle = battles
	for battle in battles:
		var bres = "DRAW!"
		if battle.winner == 1:
			bres = "<-WON!"
		elif battle.winner == 2:
			bres = "<-LOST!"
		popup.add_item("{2} map {0}, battle {1}".format([battle.map_id, battle.battle_id, bres]))
		
	popup.popup(Rect2i(pos.x, pos.y, 128, 128))

func _on_battle_popup_index_pressed(index: int) -> void:
	var battle = _cur_popupped_battle[index]
	JavaScriptBridge.eval('''
	window.open(location.pathname.slice(0, location.pathname.lastIndexOf('/')) + "/battle_loader?battle_id={0}", '_blank').focus();
	'''.format([battle.battle_id]))
