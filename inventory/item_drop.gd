extends KinematicBody2D

const acceleration = 460
const max_speed = 225
var velocity = Vector2.ZERO
export var item_name = " "
onready var sprite = get_node("sprite")

var player = null
var being_picked_up = false

func _ready():
	if item_name == " ":
		item_name = "torch"
	sprite.texture = load("res://items/icons/" + str(item_name) + ".png")
	
func _physics_process(delta):
	if being_picked_up == true:
		var direction = global_position.direction_to(player.global_position)
		velocity = velocity.move_toward(direction * max_speed, acceleration * delta)
		
		var distance = global_position.distance_to(player.global_position)
		if distance < 15:
			player_inv.add_item(item_name, 1)
			queue_free()
	velocity = move_and_slide(velocity)
			
func pick_up_item(body):
	player = body
	being_picked_up = true
