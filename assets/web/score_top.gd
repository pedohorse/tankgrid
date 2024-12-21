extends VBoxContainer

@onready var entry_template := preload("res://assets/web/top_entry.tscn")
@onready var data_access := get_tree().root.get_node("DataAccess") as BattleDataAccess

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	populate()

func populate():
	data_access.get_battle_top(_received_battle_top)
	
func _received_battle_top(battletop):
	for child in get_children():
		child.queue_free()

	if battletop == null:
		return

	var winners := []
	for label in battletop:
		winners.append([label, battletop[label]])
	winners.sort_custom(func(a, b): return a[1] > b[1])
	
	for label_score in winners:
		var entry = entry_template.instantiate()
		add_child(entry)
		entry.label.text = label_score[0]
		entry.score.text = "%4d" %label_score[1]
