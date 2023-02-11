extends Panel

var default_hotbar_tex = preload("res://inventory/hotbar_panel.png")
var selected_hotbar_tex = preload("res://inventory/hotbar_panel_selected.png")

var default_hotbar_style: StyleBoxTexture = null
var selected_hotbar_style: StyleBoxTexture = null

var item_obj = preload("res://inventory/item.tscn")
var item = null
var slot_index
var slot_type

enum slot_type_enum {
	HOTBAR = 0,
	INVENTORY,
}

onready var inventory_node = find_parent("inventory")
onready var ui = find_parent("ui")

func _ready():
	default_hotbar_style = StyleBoxTexture.new()
	selected_hotbar_style = StyleBoxTexture.new()
	default_hotbar_style.texture = default_hotbar_tex
	selected_hotbar_style.texture = selected_hotbar_tex
	
#	if randi() % 2 == 0:
#		item = item_obj.instance()
#		add_child(item)

func refresh_style():
	if slot_type_enum.HOTBAR == slot_type and player_inv.active_item_slot == slot_index:
		set("custom_styles/panel", selected_hotbar_style)
	elif item == null:
		set("custom_styles/panel", default_hotbar_style)
	else: 
		set("custom_styles/panel", default_hotbar_style)

func pick_from_slot():
	remove_child(item)
	ui.add_child(item)
	item.scale = Vector2(4, 4)
	item = null
	
func remove_from_slot():
	player_inv.remove_item(self, true)
	remove_child(item)
	item = null

func put_into_slot(new_item):
	item = new_item
	item.position = Vector2(0, 0)
	item.scale = Vector2(1, 1)
	ui.remove_child(item)
	add_child(item)
	
func use_item():
	item.remove_item_quantity(1)
	if item.item_quantity <= 0:
		remove_from_slot()
	
func initialise_item(item_name, item_quantity):
	if item == null:
		item = item_obj.instance()
		add_child(item)
		item.set_item(item_name, item_quantity)
	else:
		item.set_item(item_name, item_quantity)
