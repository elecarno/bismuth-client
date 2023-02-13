extends Node2D

var rng = RandomNumberGenerator.new()

var seed_array = [3161026589, 2668139190, 4134715227, 4204663500, 1099556929, 3154986942]

export var chunk_width = 16
export var chunk_height = 16
export var map_width = 512
export var map_height = 512
onready var floortilemap = get_node("floor_tiles")
onready var proptilemap = get_node("y_sort/prop_tiles")
onready var walltilemap = get_node("y_sort/wall_tiles")
onready var y_sort = get_node("y_sort")
onready var player = get_node("y_sort/player")
onready var chunk_parent_obj = preload("res://tilemap/chunk_parent.tscn")

export var map = [{"x": -1, "y": -1, "ftiles": [],"ptiles": [],"wtiles": []}]
var loaded = [] # this fills up and doesn't get cleared but it all still works somehow?
var previous_chunk = Vector2(0, 0)
var current_chunk = Vector2(0, 0)

var walls = {}
var ores = {}

var foliage = {}

var temperature = {}
var moisture = {}
var altitude = {}
var biome = {}

var objects = {}
var props = {}

var open_simplex_noise = OpenSimplexNoise.new()

onready var floortiles = json_data.gen_data["floortiles"]
onready var walltiles = json_data.gen_data["walltiles"]
onready var proptiles = json_data.gen_data["proptiles"]
onready var biome_wall_data = json_data.gen_data["biome_wall_data"]
onready var biome_prop_data = json_data.gen_data["biome_prop_data"]

func generate_map(per, oct, seed_arr):
	if seed_arr == 0:
		rng.randomize()
		var rand_s = randi()
		open_simplex_noise.seed = rand_s
		print(rand_s)
	else:
		open_simplex_noise.seed = seed_arr
	open_simplex_noise.period = per
	open_simplex_noise.octaves = oct
	var grid_name = {}
	for x in map_width:
		for y in map_height:
			var rand := 2*(abs(open_simplex_noise.get_noise_2d(x, y)))
			grid_name[Vector2(x, y)] = rand
	return grid_name
	
func _ready():
	var factor = chunk_width*chunk_height
	current_chunk = Vector2(floor(player.position.x/factor), floor(player.position.y/factor))
	previous_chunk = Vector2(floor(player.position.x/factor), floor(player.position.y/factor))
	walls = generate_map(30, 5, seed_array[0])
	ores = generate_map(15, 5, seed_array[1])
	foliage = generate_map(25, 5, seed_array[2])
	temperature = generate_map(250, 5, seed_array[3])
	moisture = generate_map(250, 5, seed_array[4])
	altitude = generate_map(150, 5, seed_array[5])
	load_surrounding_chunks(current_chunk.x, current_chunk.y)

	
func _physics_process(_delta):
	var factor = chunk_width*chunk_height
	current_chunk = Vector2(floor(player.position.x/factor), floor(player.position.y/factor))
	if previous_chunk != current_chunk:
		unload_surrounding_chunks(previous_chunk.x, previous_chunk.y)
		load_surrounding_chunks(current_chunk.x, current_chunk.y)
		previous_chunk = current_chunk

func generate_chunk(chunk_x, chunk_y):
	#var chunk_parent = chunk_parent_obj.instance()
	#chunk_parent.set("chunk_pos", Vector2(chunk_x, chunk_y))
	#chunk_parent.set_name(str(chunk_x) + ", " + str(chunk_y))
	#y_sort.add_child(chunk_parent)
	
	var chunk = {
		"x": chunk_x,
		"y": chunk_y,
		"ftiles": [],
		"ptiles": [],
		"wtiles": [],
	}
	
	for x in chunk_width:
		for y in chunk_height:
			var pos = Vector2(x, y)
			pos.x += chunk_x*chunk_width
			pos.y += chunk_y*chunk_height
			
			var wall = walls[pos]
			var ore = ores[pos]
			var fol = foliage[pos]
			var alt = altitude[pos]
			var moist = moisture[pos]
			var temp = temperature[pos]
			
			biome[pos] = "mineral"
			floortilemap.set_cellv(pos, floortiles["mineral"])
			
			if alt < 0.05: # water / cave rivers
				biome[pos] = "water"
				floortilemap.set_cellv(pos, floortiles["water"])
				
			# mud caves
			elif between(alt, 0.05, 0.15):
				biome[pos] = "mud"
				floortilemap.set_cellv(pos, floortiles["mud"])
			
			# rich caves layer
			elif between(alt, 0.15, 0.4):
				biome[pos] = "rich"
				floortilemap.set_cellv(pos, floortiles["rich"])
					
			# other
			elif between(alt, 0.4, 1):
				# icy caves
				if between(moist, 0, 0.4) and between(temp, 0, 0.1):
					biome[pos] = "icy"
					floortilemap.set_cellv(pos, floortiles["icy"])
				# temperate caves
				elif between(moist, 0, 0.4) and between(temp, 0.1, 0.5):
					biome[pos] = "temperate"
					floortilemap.set_cellv(pos, floortiles["temperate"])
				# sand caves
				elif between(moist, 0, 0.4) and between(temp, 0.5, 0.7):
					biome[pos] = "sandy"
					floortilemap.set_cellv(pos, floortiles["sand"])
				# volcanic caves
				elif between(moist, 0, 0.4) and between(temp, 0.7, 1):
					biome[pos] = "volcanic"
					floortilemap.set_cellv(pos, floortiles["volcanic"])
				# rich caves
				elif between(moist, 0.4, 0.9) and between(temp, 0.4, 1):
					biome[pos] = "rich"
					floortilemap.set_cellv(pos, floortiles["rich"])
				# bismuth caves
				elif between(moist, 0.9, 1) and between(temp, 0.8, 1):
					biome[pos] = "bismuth"
					floortilemap.set_cellv(pos, floortiles["bismuth"])
				# crystal caves
				elif between(moist, 0.9, 1) and between(temp, 0.4, 0.8):
					biome[pos] = "crystal"
					floortilemap.set_cellv(pos, floortiles["crystal"])
				# coal caves
				elif between(moist, 0.4, 0.6) and between(temp, 0.2, 0.4):
					biome[pos] = "coal"
					floortilemap.set_cellv(pos, floortiles["coal"])
				# metallic caves
				elif between(moist, 0.6, 0.8) and between(temp, 0.2, 0.4):
					biome[pos] = "metallic"
					floortilemap.set_cellv(pos, floortiles["metallic"])
				# gold caves
				elif between(moist, 0.8, 1) and between(temp, 0.2, 0.4):
					biome[pos] = "gold"
					floortilemap.set_cellv(pos, floortiles["gold"])
				# radioactive caves
				elif between(moist, 0.4, 0.7) and between(temp, 0, 0.2):
					biome[pos] = "radioactive"
					floortilemap.set_cellv(pos, floortiles["radioactive"])
				# mineral caves
				elif between(moist, 1, 1) and between(temp, 0, 0.2):
					biome[pos] = "mineral"
					floortilemap.set_cellv(pos, floortiles["mineral"])
					
			else: # default to temperate
				biome[pos] = "temperate"
				floortilemap.set_cellv(pos, floortiles["temperate"])
				
			if wall < 0.3:
				var walltiledata = biome_wall_data[biome[pos]]
				if walltiledata != null and len(walltiledata) > 0:
					walltilemap.set_cellv(pos, walltiles[walltiledata[0]])
				
				if ore < 0.3:
					if walltiledata != null and len(walltiledata) > 2:
						walltilemap.set_cellv(pos, walltiles[walltiledata[2]])
			if wall < 0.1:
				var walltiledata = biome_wall_data[biome[pos]]
				if walltiledata != null and len(walltiledata) > 1:
					walltilemap.set_cellv(pos, walltiles[walltiledata[1]])
					
			if fol < 0.7:
				var biomefoldata = biome_prop_data[biome[pos]]
				rng.randomize()
				var rand = rand_range(0, 1)
				var running_total = 0
				for i in biomefoldata:
					running_total = running_total + biomefoldata[i]
					if rand <= running_total and proptilemap.get_cell(pos.x, pos.y) == -1 and walltilemap.get_cell(pos.x, pos.y) == -1:
						proptilemap.set_cellv(pos, proptiles[i])
					
			chunk["ftiles"].append(floortilemap.get_cell(pos.x, pos.y))
			chunk["wtiles"].append(walltilemap.get_cell(pos.x, pos.y))
	
	for x in chunk_width:
		for y in chunk_height:
			var pos = Vector2(x, y)
			pos.x += chunk_x*chunk_width
			pos.y += chunk_y*chunk_height
			chunk["ptiles"].append(proptilemap.get_cell(pos.x, pos.y))
	
	if !loaded.has(Vector2(chunk_x, chunk_y)):
		loaded.append(Vector2(chunk_x, chunk_y))
	
	if !check_chunk_generation(chunk_x, chunk_y):
		map.append(chunk)
		#print("chunk added to dict")

func get_random(dict):
	var a = dict.keys()
	if a.size() != 0:
		a = a[randi() % a.size()]
		return a
	else:
		return "0"

func load_chunk(chunk_x, chunk_y):
	#var chunk_parent = chunk_parent_obj.instance()
	#chunk_parent.set("chunk_pos", Vector2(chunk_x, chunk_y))
	#chunk_parent.set_name(str(chunk_x) + ", " + str(chunk_y))
	#y_sort.add_child(chunk_parent)
	
	var chunk_to_load
	for i in range(0, len(map)):
		if map[i]["x"] == chunk_x and map[i]["y"] == chunk_y:
			chunk_to_load = map[i]
			loaded.append(Vector2(chunk_x, chunk_y))
	
	var pos_array = []
	for x in chunk_width:
		for y in chunk_height:
			var pos = Vector2(x, y)
			pos.x += chunk_x*chunk_width
			pos.y += chunk_y*chunk_height
			pos_array.append(pos)
			
	for i in range(0, chunk_width*chunk_height):
		floortilemap.set_cellv(pos_array[i], chunk_to_load["ftiles"][i])
		walltilemap.set_cellv(pos_array[i], chunk_to_load["wtiles"][i])
		proptilemap.set_cellv(pos_array[i], chunk_to_load["ptiles"][i])

func load_surrounding_chunks(chunk_x, chunk_y):
	for x in range(-1, 2):
		for y in range(-1, 2):
			if !check_chunk_generation(chunk_x+x, chunk_y+y) and !loaded.has(Vector2(chunk_x+x, chunk_y+y)):
				generate_chunk(chunk_x+x, chunk_y+y)
			else:
				load_chunk(chunk_x+x, chunk_y+y)

func check_chunk_generation(chunk_x, chunk_y):
	for i in range(0, len(map)):
		if map[i]["x"] == chunk_x and map[i]["y"] == chunk_y:
			#print("chunk already generated: " + str(map[i]["x"]) + ", " + str(map[i]["y"]))
			return true

func unload_chunk(chunk_x, chunk_y):
	loaded.erase(Vector2(chunk_x, chunk_y))
	for x in chunk_width:
		for y in chunk_height:
			var pos = Vector2(x, y)
			pos.x += chunk_x*chunk_width
			pos.y += chunk_y*chunk_height
			floortilemap.set_cellv(pos, -1)
			walltilemap.set_cellv(pos, -1)
			proptilemap.set_cellv(pos, -1)

func unload_surrounding_chunks(chunk_x, chunk_y):
	var nodes = y_sort.get_children()
	for i in range(0, len(nodes)):
		if nodes[i].get("chunk_pos"):
			y_sort.get_node(nodes[i].name).queue_free()
	
	for x in range(-1, 2):
		for y in range(-1, 2):
			unload_chunk(chunk_x+x, chunk_y+y)

func between(val, start, end):
	if start <= val and val < end:
		return true

func random_tile(data, biome):
	var current_biome = data[biome]
	var rand_num = rand_range(0, 1)
	var running_total = 0
	for tile in current_biome:
		running_total = running_total + current_biome[tile]
		if rand_num <= running_total:
			return tile
