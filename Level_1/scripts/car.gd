extends Area2D

var player_in_range = false
var trunk_open = false

@onready var car_idle_sound = $CarIdleSound
@onready var trunk_open_sound = $TrunkOpenSound
@onready var trunk_close_sound = $TrunkCloseSound
@onready var shilo_node = null  # Reference to Shilo for distance calculation

func _ready() -> void:
	# Find the Shilo instance in the scene
	shilo_node = get_parent().get_node("Shilo")  # Adjust this path if necessary
	if shilo_node:
		print("Shilo found!")
	else:
		print("Error: Shilo not found.")

	# Start the idle sound on loop
	car_idle_sound.play()

	# Adjust volume immediately based on initial distance
	update_idle_sound_volume()

func _process(delta: float) -> void:
	# Continuously adjust idle sound volume based on distance
	update_idle_sound_volume()

	# Handle interaction with the car
	if player_in_range and Input.is_action_just_pressed("interact"):
		if trunk_open:
			await close_trunk()
		else:
			await open_trunk()

func update_idle_sound_volume() -> void:
	if shilo_node:
		# Calculate the distance between the player and the car
		var distance = global_position.distance_to(shilo_node.global_position)

		# Define the max and min distances for volume adjustment
		var max_distance = 1100.0  # Maximum distance where the sound is audible
		var min_distance = 50.0   # Distance where the sound is at full volume

		# Normalize the volume level (0.0 to 1.0)
		var normalized_volume = clamp((max_distance - distance) / (max_distance - min_distance), 0.0, 1.0)

		# Convert normalized volume to decibels (-60 dB for silent to 0 dB for full volume)
		car_idle_sound.volume_db = lerp(-60, 0, normalized_volume)
		#print("Distance:", distance, "Volume (dB):", car_idle_sound.volume_db)

# Triggered when an Area2D enters the car's collision area
func _on_area_entered(area: Node) -> void:
	if area.get_parent() and area.get_parent().name == "Shilo":
		player_in_range = true
		print("Shilo is near the car!")

# Triggered when an Area2D exits the car's collision area
func _on_area_exited(area: Node) -> void:
	if area.get_parent() and area.get_parent().name == "Shilo":
		player_in_range = false
		print("Shilo left the car!")

# Plays the open trunk animation and sound
func open_trunk() -> void:
	print("Opening the trunk...")
	trunk_open = true
	trunk_open_sound.stop()
	trunk_open_sound.play()
	$AnimatedSprite2D.play("trunk_open")
	await get_tree().create_timer(0.8).timeout
	$AnimatedSprite2D.play("trunk_open_idle")
	print("Trunk is fully open and idle.")

# Plays the close trunk animation and sound
func close_trunk() -> void:
	print("Closing the trunk...")
	trunk_open = false
	trunk_close_sound.stop()
	trunk_close_sound.play()
	$AnimatedSprite2D.play("trunk_close")
	await get_tree().create_timer(0.3).timeout
	$AnimatedSprite2D.play("idle")
	print("Trunk is closed and idle.")
