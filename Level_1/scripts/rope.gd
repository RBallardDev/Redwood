extends RigidBody2D

# Indicates whether the rope has been picked up
var is_picked_up = false

# Reference to Shilo's node for potential interactions
@onready var shilo_node = null

func _ready():
	# Get a reference to Shilo in the current scene
	shilo_node = get_parent().get_node("Shilo")
	if shilo_node:
		print("Shilo reference found.")
	else:
		print("Shilo reference not found.")

	# Set the body to "static" mode
	self.body_mode = "static"
