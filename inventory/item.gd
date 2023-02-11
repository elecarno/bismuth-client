extends Node2D

export var item_name = ""
export var item_quantity = 0

onready var texture_rect = get_node("tex")
onready var quantity_label = get_node("quantity")

#func _ready():
#	var rand_val = randi() % 3
#	if rand_val == 0:
#		item_name = "torch"
#	elif rand_val ==1:
#		item_name = "iron_pickaxe"
#	else:
#		item_name = "rock_wall"
#
#	texture_rect.texture = load("res://items/icons/" + item_name + ".png")
#	var stack_size = int(json_data.item_data[item_name]["stacksize"])
#	item_quantity = randi() % stack_size + 1
#
#	if stack_size == 1:
#		quantity_label.visible = false
#	else:
#		quantity_label.text = str(item_quantity)
		
func set_item(name, quantity):
	item_name = name
	item_quantity = quantity
	texture_rect.texture = load("res://items/icons/" + item_name + ".png")
	
	var stack_size = int(json_data.item_data[item_name]["stacksize"])
	if stack_size == 1:
		quantity_label.visible = false
	else:
		quantity_label.visible = true
		quantity_label.text = str(item_quantity)
		
func add_item_quantity(amount):
	item_quantity += amount
	quantity_label.text = str(item_quantity)
	
func remove_item_quantity(amount):
	item_quantity -= amount
	quantity_label.text = str(item_quantity)
#	if item_quantity <= 0:
#		queue_free()
