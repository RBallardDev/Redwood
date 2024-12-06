extends Area2D


@onready var shilo_node = null  # Reference to Shilo for position tracking

func _ready():
	# Find Shilo in the scene
	shilo_node = get_parent().get_node("Shilo")  # Adjust this path if necessary
	if not shilo_node:
		print("Error: Shilo node not found!")

	# Start idle animation
	$AnimatedSprite2D.play("idle")  

func _process(delta: float) -> void:
	
	# Flip NPC to always face Shilo when idle
	if shilo_node:
		$AnimatedSprite2D.flip_h = (shilo_node.global_position.x < global_position.x)
