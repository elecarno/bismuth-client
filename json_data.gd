extends Node

export var wtile_to_item2 = {0: "rock_wall", 1: "granite_wall", 2: "iron_ore"}
export var ptile_to_item2 = {0: "red_shroom", 1: "yellow_shroom", 2: "stalagmite", 3: "cave_grass", 4: "glow_bell"}

export var wtile_to_item = {}
export var ptile_to_item = {}
onready var item_data = {}
var gen_data = {}

func _ready():
	item_data = load_data("res://items/itemdata.json")
	gen_data = load_data("res://gendata.json")
	
	for i in item_data:
		if item_data[i]["type"] == "wall":
			wtile_to_item[item_data[i]["tileid"]] = i
		if item_data[i]["type"] == "prop":
			ptile_to_item[item_data[i]["tileid"]] = i
		if item_data[i].has("harvesttype"):
			if item_data[i]["harvesttype"] == "wall":
				wtile_to_item[item_data[i]["harvestid"]] = i
			if item_data[i]["harvesttype"] == "prop":
				ptile_to_item[item_data[i]["harvestid"]] = i
#
#	print(wtile_to_item)
#	print(wtile_to_item2)
#	print(ptile_to_item)
#	print(ptile_to_item2)
	
func load_data(file_path):
	var json_data
	var file_data = File.new()
	
	file_data.open(file_path, File.READ)
	json_data = JSON.parse(file_data.get_as_text())
	file_data.close()
	return json_data.result
