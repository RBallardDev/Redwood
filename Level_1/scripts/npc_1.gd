extends Area2D

@export var target_x: float = 1200.0  # Target x-coordinate for NPC1
@export var walk_speed: float = 60.0  # Walking speed

var is_walking = true  # Whether NPC1 is currently walking


# State tracking
var picked_up = false  # Tracks if the rope has been picked up
@onready var shilo_node = get_parent().get_node("Shilo")  # Reference to Shilo node in the parent scene
@onready var label_node = $Label  # Reference the Label node
var player_in_range = false  # Tracks if Shilo is in range


func _ready():
	# Find Shilo in the scene
	shilo_node = get_parent().get_node("Shilo")  # Adjust this path if necessary
	if not shilo_node:
		print("Error: Shilo node not found!")

	# Start walking animation
	$AnimatedSprite2D.play("walk")  # Use your walking animation name
	
	label_node.visible = false

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
			
			

func _on_area_entered(area: Node) -> void:
	if area.name == "Shilo":  # Ensure this works for Shilo specifically
		print("Shilo entered NPC2's area!")
		player_in_range = true
		label_node.visible = true  # Show the label
		label_node.text = "Press E to talk"

func _on_area_exited(area: Node) -> void:
	if area.name == "Shilo":
		print("Shilo left NPC2's area!")
		player_in_range = false
		label_node.visible = false  # Hide the label

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player_in_range:
		handle_dialogue()

func handle_dialogue():
	if not picked_up:  # If the rope hasn't been picked up
		print("NPC 1: Somthings off")
		label_node.text = "Something feels off
		 about the forest."
	else:  # If the rope has been picked up
		print("NPC 1: im not sure what but its something")
		label_node.text = "Im not sure what,
		 but its something bad."
