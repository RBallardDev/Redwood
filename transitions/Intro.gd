extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play("Fade in")  # Ensure the AnimationPlayer node exists
	await $AnimationPlayer.animation_finished  # Wait for fade-in to complete
	$AnimationPlayer.play("Fade out")  # Play fade-out animation
	await $AnimationPlayer.animation_finished  # Wait for fade-out to complete

	# Change to Level 1 scene
	get_tree().change_scene_to_file("res://Level_1/scenes/level_1.tscn")  # Corrected the path and syntax
