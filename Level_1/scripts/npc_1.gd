extends Area2D

@export var target_x: float = 1200.0  # Target x-coordinate for NPC1
@export var walk_speed: float = 60.0  # Walking speed

var is_walking = true  # Whether NPC1 is currently walking

@onready var shilo_node = null  # Reference to Shilo for position tracking

func _ready():
	# Find Shilo in the scene
	shilo_node = get_parent().get_node("Shilo")  # Adjust this path if necessary
	if not shilo_node:
		print("Error: Shilo node not found!")

	# Start walking animation
	$AnimatedSprite2D.play("walk")  # Use your walking animation name

func _process(delta: float) -> void:
	if is_walking:
		# Move NPC1 horizontally towards the target x-coordinate
		if abs(global_position.x - target_x) > 5.0:  # Keep walking until close to the target
			var direction = sign(target_x - global_position.x)  # Determine direction (-1 or 1)
			global_position.x += direction * walk_speed * delta
			$AnimatedSprite2D.flip_h = direction < 0  # Flip sprite if moving left
		else:
			# Stop walking and switch to idle when close to the target
			is_walking = false
			$AnimatedSprite2D.play("idle")  # Use your idle animation name
	else:
		# Flip NPC to always face Shilo when idle
		if shilo_node:
			$AnimatedSprite2D.flip_h = (shilo_node.global_position.x < global_position.x)
