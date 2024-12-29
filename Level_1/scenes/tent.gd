extends Area2D

@onready var collision_shape = $CollisionShape2D  # Reference to collision shape
@onready var dimming_layer = get_parent().get_node("DimmingLayer")  # Adjust to your scene tree
@onready var npc2_node = get_parent().get_node("npc2")  # Reference to NPC2 node
#@onready var label_node = $CanvasLayer/Label  # Optional: Add a label for interaction text

# State variables
var player_in_range = false  # Tracks if Shilo is in range

func _ready():
	dimming_layer.visible = false  # Ensure the dimming layer starts hidden
	#label_node.visible = false  # Hide label initially (if used)
	print("Tent is ready and waiting for interaction.")

func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact") and npc2_node.picked_up:
		go_to_next_level()

func _on_area_entered(area: Node) -> void:
	if area.name == "Shilo":  # Check if the area entered is Shilo
		print("Shilo entered the Tent's area!")
		if npc2_node.picked_up:  # Check if the rope is picked up
			player_in_range = true
			dimming_layer.visible = true  # Show the dimming layer
			#label_node.visible = true  # Show interaction prompt
			#label_node.text = "Press E to enter the tent"

func _on_area_exited(area: Node) -> void:
	if area.name == "Shilo":
		print("Shilo left the Tent's area!")
		player_in_range = false
		dimming_layer.visible = false  # Hide the dimming layer
		#label_node.visible = false  # Hide the label

func go_to_next_level():
	print("Transitioning to the next level...")
	get_tree().change_scene_to_file("res://main.tscn")  # Replace with the correct path
