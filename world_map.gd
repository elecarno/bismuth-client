extends Node2D

var rng = RandomNumberGenerator.new()

var seed_array = [3161026589, 2668139190, 4134715227, 4204663500, 1099556929, 3154986942]

export var map_width = 512
export var map_height = 512
onready var floortilemap = get_node("floor_tiles")
onready var proptilemap = get_node("y_sort/prop_tiles")
onready var walltilemap = get_node("y_sort/wall_tiles")
onready var y_sort = get_node("y_sort")

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

var floortiles = {"water": 0, "mud": 1, "volcanic": 2, "sand": 3, "rich": 4, "bismuth": 5,
"temperate": 6, "coal": 7, "metallic": 8, "gold": 9, "icy": 10, "radioactive": 11,
"mineral": 12, "crystal": 13}

var walltiles = {"air": -1, "rock": 0, "granite": 1, "iron_ore": 2}
var biome_wall_data = { # [main, secondary, ore 1, ore 2, etc]
	"water": ["air"],
	"mud": ["air"],
	"volcanic": ["air"],
	"sandy": ["air"],
	"temperate": ["rock", "granite", "iron_ore"],
	"icy": ["air"],
	"rich": ["air"],
	"bismuth": ["air"],
	"crystal": ["air"],
	"coal": ["air"],
	"metallic": ["air"],
	"gold": ["air"],
	"radioactive": ["air"],
	"mineral": ["air"],
}

var objecttiles = {"vine_eye": preload("res://objects/vine_eye.tscn")}
var biome_object_data = {
	"water": {},
	"mud": {},
	"volcanic": {},
	"sandy": {},
	"temperate": {},
	"icy": {},
	"rich": {"vine_eye": 0.01},
	"bismuth": {},
	"crystal": {},
	"coal": {},
	"metallic": {},
	"gold": {},
	"radioactive": {},
	"mineral": {},
}

var proptiles = {"red_shroom": 0, "yellow_shroom": 1, "stalagmite": 2, "cave_grass": 3, 
"glow_bell": 5}
var biome_prop_data = {
	"water": {},
	"mud": {},
	"volcanic": {"stalagmite": 0.05},
	"sandy": {},
	"temperate": {"stalagmite": 0.05},
	"icy": {},
	"rich": {"red_shroom": 0.025, "yellow_shroom": 0.015, "cave_grass": 0.03, "glow_bell": 0.022},
	"bismuth": {},
	"crystal": {},
	"coal": {},
	"metallic": {},
	"gold": {},
	"radioactive": {},
	"mineral": {},
}

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
	walls = generate_map(30, 5, seed_array[0])
	ores = generate_map(15, 5, seed_array[1])
	foliage = generate_map(25, 5, seed_array[2])
	temperature = generate_map(250, 5, seed_array[3])
	moisture = generate_map(250, 5, seed_array[4])
	altitude = generate_map(150, 5, seed_array[5])
	generate_chunk()

func generate_chunk():
	for x in map_width:
		for y in map_height:
			var pos = Vector2(x, y)
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
				
#			if wall < 0.3: # genertic walls
#				walltilemap.set_cellv(pos, 0)
				
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
#
#			if fol < 0.7:
#				var biomefoldata = biome_prop_data[biome[pos]]
#				rng.randomize()
#				var rand = rand_range(0, 1)
#				var running_total = 0
#				for i in biomefoldata:
#					running_total = running_total + biomefoldata[i]
#					if rand <= running_total and proptilemap.get_cell(pos.x, pos.y) == -1 and walltilemap.get_cell(pos.x, pos.y) == -1:
#						proptilemap.set_cellv(pos, proptiles[i])
					
#			if fol < 0.7:
#				var biomeobjdata = biome_object_data[biome[pos]]
#				rng.randomize()
#				var rand = rand_range(0, 1)
#				var running_total = 0
#				var i = get_random(biomeobjdata)
#				if i != "0":
#					running_total = running_total + biomeobjdata[i]
#					if rand <= running_total:
#						proptilemap.set_cellv(pos, -1)
#						var instance = objecttiles[i].instance()
#						instance.position = proptilemap.map_to_world(pos) + Vector2(8, 8)
#						y_sort.add_child(instance)

func get_random(dict):
	var a = dict.keys()
	if a.size() != 0:
		a = a[randi() % a.size()]
		return a
	else:
		return "0"

func between(val, start, end):
	if start <= val and val < end:
		return true
		
func _input(event):
	if event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()
