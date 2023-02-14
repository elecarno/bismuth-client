extends KinematicBody2D

var max_speed = 100
var acceleration = 500
var motion = Vector2.ZERO

onready var highlight = get_parent().get_parent().get_node("highlight")
onready var highlight_wall = get_parent().get_parent().get_node("highlight_wall")
onready var y_sort = get_parent()
onready var anim = get_node("anim")
onready var sprite = get_node("sprite")

const slot_class = preload("res://inventory/slot.gd")
onready var item_drop_obj = preload("res://inventory/item_drop.tscn")

onready var world = get_parent().get_parent()

onready var floortilemap = get_parent().get_parent().get_node("floor_tiles")
onready var proptilemap = get_parent().get_node("prop_tiles")
onready var walltilemap = get_parent().get_node("wall_tiles")

var tilepos = Vector2(0, 0)
var current_chunk = Vector2(0, 0)

func _physics_process(delta):
	handle_interaction()
	
	if position.x < 276:
		position.x = 278
		return
		
	if position.y < 276:
		position.y = 278
		return
		
	if Input.is_action_pressed("down"):
		anim.play("walk_down")
	if Input.is_action_just_released("down"):
		anim.stop()
		sprite.frame = 2
		
	if Input.is_action_pressed("up"):
		anim.play("walk_up")
	if Input.is_action_just_released("up"):
		anim.stop()
		sprite.frame = 4
		
	if Input.is_action_pressed("left"):
		anim.play("walk_left")
	if Input.is_action_just_released("left"):
		anim.stop()
		sprite.frame = 7
	
	if Input.is_action_pressed("right"):
		anim.play("walk_right")
	if Input.is_action_just_released("right"):
		anim.stop()
		sprite.frame = 9

	var axis = get_input_axis()
	if axis == Vector2.ZERO:
		apply_friction(acceleration * delta)
	else:
		apply_movement(axis * acceleration * delta)
		
	motion = move_and_slide(motion)
		
	if Input.is_action_just_pressed("sprint"):
		max_speed = 200
		acceleration = 750
	if Input.is_action_just_released("sprint"):
		max_speed = 100
		acceleration = 500

func handle_interaction():
	var mousepos = get_global_mouse_position()
	var factor = 16*16
	
	current_chunk = Vector2(floor(mousepos.x/factor), floor(mousepos.y/factor))
	tilepos = walltilemap.world_to_map(mousepos)
	
	if walltilemap.get_cellv(tilepos) != -1:
		highlight.visible = false
		highlight_wall.visible = true
	else:
		highlight.visible = true
		highlight_wall.visible = false
		
	var hotbar_itemdata = {}
	if player_inv.hotbar.has(player_inv.active_item_slot):
		hotbar_itemdata = json_data.item_data[player_inv.hotbar[player_inv.active_item_slot][0]]
		
	# breaking tiles
	if Input.is_action_pressed("lmb"):
		if hotbar_itemdata.has("type"):
			if walltilemap.get_cellv(tilepos) != -1:
				if hotbar_itemdata["type"] == "walltool":
					break_tile(walltilemap, "wtiles", json_data.wtile_to_item)
			if proptilemap.get_cellv(tilepos) != -1:
				if hotbar_itemdata["type"] == "proptool":
					break_tile(proptilemap, "ptiles", json_data.ptile_to_item)

	# placing tiles
	if Input.is_action_pressed("rmb"):
		if hotbar_itemdata.has("tileid"):
			if hotbar_itemdata["type"] == "wall":
				place_tile(hotbar_itemdata, walltilemap, "wtiles")
			elif hotbar_itemdata["type"] == "prop":
				place_tile(hotbar_itemdata, proptilemap, "ptiles")
				
	var hpos = walltilemap.map_to_world(tilepos) + Vector2(8, 8)
	highlight.position = hpos
	highlight_wall.position = hpos

func break_tile(tilemap, assign, tile_to_item):
	var item_key
	for key in tile_to_item:
		if key == tilemap.get_cellv(tilepos):
			item_key = key
	var item_drop = item_drop_obj.instance()
	item_drop.position = tilepos * Vector2(16, 16) + Vector2(8, 8)
	item_drop.set("item_name", tile_to_item[item_key])
	item_drop.name = tile_to_item[item_key]
	tilemap.set_cellv(tilepos, -1)
	save_chunk(current_chunk.x, current_chunk.y, tilepos, assign, -1)
	y_sort.add_child(item_drop)
	
func place_tile(itemdata, tilemap, assign):
	if walltilemap.get_cellv(tilepos) == -1 and proptilemap.get_cellv(tilepos) == -1:
		tilemap.set_cellv(tilepos, itemdata["tileid"])
		save_chunk(current_chunk.x, current_chunk.y, tilepos, assign, itemdata["tileid"])
		var slot = get_tree().root.get_node("/root/world/ui/hotbar/hotbar_inv/hotbar_slot_" + str(player_inv.active_item_slot + 1))
		slot.use_item()

func save_chunk(chunk_x, chunk_y, tilepos, tilemap, assign):
	var chunk_width = world.get("chunk_width")
	var chunk_height = world.get("chunk_height")
	var map = world.get("map")
	
	var array_index = 0
	
	var pos_array = []
	for x in chunk_width:
		for y in chunk_height:
			var pos = Vector2(x, y)
			pos.x += chunk_x*chunk_width
			pos.y += chunk_y*chunk_height
			pos_array.append(pos)
			
	for i in range(0, len(pos_array)):
		if pos_array[i] == tilepos:
			array_index = i
			
	for i in range(0, len(map)):
		if map[i]["x"] == chunk_x and map[i]["y"] == chunk_y:
			map[i][tilemap][array_index] = assign
			world.set("map", map)
			print("assigned tile " + str(array_index) + " in [\"" + str(tilemap) + "\"] chunk (" + str(chunk_x) + ", " + str(chunk_y) + ") to " + str(assign))

func get_input_axis():
	var axis = Vector2.ZERO
	axis.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	axis.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	return axis.normalized()

func apply_friction(amount):
	if motion.length() > amount:
		motion -= motion.normalized() * amount
	else:
		motion = Vector2.ZERO
	
func apply_movement(accel):
	motion += accel
	motion = motion.clamped(max_speed)

func _on_pickup_zone_body_entered(body):
	body.pick_up_item(self)
