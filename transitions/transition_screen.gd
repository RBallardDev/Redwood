extends Node2D

# Path to the next level (Level 2)
@export var next_level: String


func _on_continue_pressed():
	# Change to the next level
	get_tree().change_scene_to_file("res://transitions/main.tscn")
