extends Node2D

const slot_class = preload("res://inventory/slot.gd")
onready var hotbar = get_node("hotbar_inv")
onready var slots = hotbar.get_children()
onready var active_item_label = get_node("active_item")

func _ready():
	player_inv.connect("active_item_updated", self, "update_active_item_label")
	for i in range(slots.size()):
		player_inv.connect("active_item_updated", slots[i], "refresh_style")
		slots[i].connect("gui_input", self, "slot_gui_input", [slots[i]])
		slots[i].slot_index = i
		slots[i].slot_type = slot_class.slot_type_enum.HOTBAR
	initialise_hotbar()
	update_active_item_label()
		
func update_active_item_label():
	if slots[player_inv.active_item_slot].item != null:
		var display_name = slots[player_inv.active_item_slot].item.item_name.capitalize()
		active_item_label.text = display_name
	else:
		active_item_label.text = ""
		
func initialise_hotbar():
	for i in range(slots.size()):
		if player_inv.hotbar.has(i):
			slots[i].initialise_item(player_inv.hotbar[i][0], player_inv.hotbar[i][1])
			
func slot_gui_input(event: InputEvent, slot: slot_class):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT && event.pressed:
			# currently holding an item
			if find_parent("ui").holding_item != null:
				if !slot.item:
					left_click_empty_slot(slot)
				else: 
					if find_parent("ui").holding_item.item_name != slot.item.item_name:
						left_click_different_item(event, slot)
					else:
						left_click_same_item(slot)
			elif slot.item:
				left_click_not_holding(slot)
			update_active_item_label()
				
func left_click_empty_slot(slot: slot_class):
	slot.put_into_slot(find_parent("ui").holding_item)
	player_inv.add_item_to_empty_slot(find_parent("ui").holding_item, slot, true)
	find_parent("ui").holding_item = null
	
func left_click_different_item(event: InputEvent, slot: slot_class):
	player_inv.remove_item(slot, true)
	player_inv.add_item_to_empty_slot(find_parent("ui").holding_item, slot, true)
	var temp_item = slot.item
	slot.pick_from_slot()
	temp_item.global_position = event.global_position
	slot.put_into_slot(find_parent("ui").holding_item)
	find_parent("ui").holding_item = temp_item

func left_click_same_item(slot: slot_class):
	var stack_size = int(json_data.item_data[slot.item.item_name]["stacksize"])
	var able_to_add = stack_size - slot.item.item_quantity
	if able_to_add >= find_parent("ui").holding_item.item_quantity:
		player_inv.add_item_quantity(slot, find_parent("ui").holding_item.item_quantity, true)
		slot.item.add_item_quantity(find_parent("ui").holding_item.item_quantity)
		find_parent("ui").holding_item.queue_free()
		find_parent("ui").holding_item = null
	else:
		player_inv.add_item_quantity(slot, able_to_add, true)
		slot.item.add_item_quantity(able_to_add)
		find_parent("ui").holding_item.remove_item_quantity(able_to_add)
		
func left_click_not_holding(slot: slot_class):
	player_inv.remove_item(slot, true)
	find_parent("ui").holding_item = slot.item
	slot.pick_from_slot()
	find_parent("ui").holding_item.global_position = get_global_mouse_position()
