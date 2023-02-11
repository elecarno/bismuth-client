extends CanvasLayer

onready var inventory_node = get_node("inventory")
onready var global_pos_label = get_node("global_pos")
onready var chunk_pos_label = get_node("chunk_pos")
onready var player = get_parent().get_node("y_sort/player")
onready var floortilemap = get_parent().get_node("floor_tiles")
var holding_item = null

func _input(event):
	if event.is_action_pressed("inventory"):
		inventory_node.visible = !inventory_node.visible
		inventory_node.initialise_inventory()
		
	if event.is_action_pressed("scroll_up"):
		player_inv.active_item_scroll_down()
	elif event.is_action_pressed("scroll_down"):
		player_inv.active_item_scroll_up()
		
func _physics_process(delta):
	var current_chunk = Vector2(floor(player.position.x/256), floor(player.position.y/256))
	var tilepos = floortilemap.world_to_map(player.position)
	global_pos_label.text = "pos: " + str(round(player.position.x)) + ", " + str(round(player.position.y)) + " | tile: " + str(round(player.position.x/16)) + ", " + str(round(player.position.y/16))
	chunk_pos_label.text = "chunk: " + str(current_chunk.x) + ", " + str(current_chunk.y) + " | chunk tile: " + str(tilepos.x) + ", " + str(tilepos.y)
