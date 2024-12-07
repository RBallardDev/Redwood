extends Area2D

@onready var shilo_node = get_parent().get_node("Shilo")  # Adjust if needed

func _ready():
	if not shilo_node:
		print("Error: Shilo node not found!")

func _process(delta: float) -> void:
	if shilo_node:
		# Flip NPC to face Shilo
		$AnimatedSprite2D.flip_h = (shilo_node.global_position.x < global_position.x)
