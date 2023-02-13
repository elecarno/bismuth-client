extends Node

signal active_item_updated

const slot_class = preload("res://inventory/slot.gd")
const item_class = preload("res://inventory/item.gd")

const NUM_INV_SLOTS = 30
const NUM_HOTBAR_SLOTS = 10

var inventory = {
	0: ["iron_pickaxe", 1], # slot_index: [item_name, item_quantity]
	1: ["iron_pickaxe", 1],
	2: ["rock_wall", 16],
	3: ["rock_wall", 16],
	4: ["torch", 997]
}

var active_item_slot = 0

var hotbar = {
	0: ["iron_pickaxe", 1], # slot_index: [item_name, item_quantity]
	1: ["rock_wall", 16],
}

func add_item(item_name, item_quantity):
	for item in inventory:
		if inventory[item][0] == item_name:
			var stack_size = int(json_data.item_data[item_name]["stacksize"])
			var able_to_add = stack_size - inventory[item][1]
			if able_to_add >= item_quantity:
				inventory[item][1] += item_quantity
				update_slot_visual(item, inventory[item][0], inventory[item][1])
				return
			else:
				inventory[item][1] += able_to_add
				update_slot_visual(item, inventory[item][0], inventory[item][1])
				item_quantity = item_quantity - able_to_add
			
	# item doesn't exist in inventory yet, so add it to an empty slot
	for i in range(NUM_INV_SLOTS):
		if inventory.has(i) == false:
			inventory[i] = [item_name, item_quantity]
			update_slot_visual(i, inventory[i][0], inventory[i][1])
			return

func remove_item(slot: slot_class, is_hotbar: bool = false):
	if is_hotbar:
		hotbar.erase(slot.slot_index)
		print("removed from " + str(slot.slot_index))
		print(hotbar)
	else:
		inventory.erase(slot.slot_index)

func update_slot_visual(slot_index, item_name, new_quantity):
	var slot = get_tree().root.get_node("/root/world/ui/inventory/inv/slot_" + str(slot_index + 1))
	if slot.item != null:
		slot.item.set_item(item_name, new_quantity)
	else:
		slot.initialise_item(item_name, new_quantity)

func add_item_to_empty_slot(item: item_class, slot: slot_class, is_hotbar: bool = false):
	if is_hotbar:
		hotbar[slot.slot_index] = [item.item_name, item.item_quantity]
	else:
		inventory[slot.slot_index] = [item.item_name, item.item_quantity]

func add_item_quantity(slot: slot_class, quantity_to_add: int, is_hotbar: bool = false):
	if is_hotbar:
		hotbar[slot.slot_index][1] + quantity_to_add
	else:
		inventory[slot.slot_index][1] + quantity_to_add
	
func active_item_scroll_up():
	active_item_slot = (active_item_slot + 1) % NUM_HOTBAR_SLOTS
	emit_signal("active_item_updated")
	
func active_item_scroll_down():
	if active_item_slot == 0:
		active_item_slot = NUM_HOTBAR_SLOTS - 1
	else:
		active_item_slot -= 1
	emit_signal("active_item_updated")
