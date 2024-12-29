extends Area2D

# State tracking
var picked_up = false  # Tracks if the rope has been picked up
@onready var shilo_node = get_parent().get_node("Shilo")  # Reference to Shilo node in the parent scene
@onready var label_node = $Label  # Reference the Label node
var player_in_range = false  # Tracks if Shilo is in range

func _ready():
	# Ensure the interaction label is hidden initially
	label_node.visible = false
	print("NPC2 is ready. Label hidden by default.")

func _process(delta: float) -> void:
	# Flip NPC to face Shilo
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
		print("NPC 2: Hey Shilo! Can you get the supplies from the car? It’s over there.")
		label_node.text = "Get the supplies!"
	else:  # If the rope has been picked up
		print("NPC 2: Thanks! With that, the camp site can be set up. Head over to the small tent when you’re ready.")
		label_node.text = "Camp setup complete!"
