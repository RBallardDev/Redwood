extends CharacterBody2D

signal player_nearby(rock)  # Signal emitted when the player is near the rock

@export var reset_time = 1.0
@onready var reset_timer = $Timer
var player_in_range = false  # Boolean flag to track if the player is in range

func _ready():
	reset_timer.wait_time = reset_time
	reset_timer.one_shot = true
	reset_timer.connect("timeout", Callable(self, "_on_reset_timer_timeout"))
	$PickupArea.connect("body_entered", Callable(self, "_on_body_entered"))
	$PickupArea.connect("body_exited", Callable(self, "_on_body_exited"))

# Detect when the player enters the pickup area
func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true  # Set flag to true when player is near

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false  # Set flag to false when player leaves range

# Called to start the timer when the rock is thrown
func start_reset_timer():
	reset_timer.start()

# Stop the rock's movement when the timer ends
func _on_reset_timer_timeout():
	velocity = Vector2.ZERO
