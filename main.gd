extends Node2D

# Max number of enemies allowed on screen
const MAX_ENEMIES = 8

# Spawn intervals
const SPAWN_INTERVAL_LESS_THAN_3 = 2  # Faster spawn when fewer than 3
const SPAWN_INTERVAL_3_TO_5 = 4
const SPAWN_INTERVAL_6_TO_7 = 8

# Reference to enemy scene
@export var enemy_scene: PackedScene

# List to track spawned enemies
var enemies = []

# Timer for spawning enemies
@onready var spawn_timer = $SpawnTimer

func _ready():
	# Spawn initial 3 enemies immediately
	for i in range(3):
		spawn_enemy()

	# Start the spawn timer
	spawn_timer.start(SPAWN_INTERVAL_3_TO_5)  # Default interval

func _process(delta):
	# Adjust spawn timer based on current enemy count
	if enemies.size() < 3:
		spawn_timer.wait_time = SPAWN_INTERVAL_LESS_THAN_3
	elif enemies.size() <= 5:
		spawn_timer.wait_time = SPAWN_INTERVAL_3_TO_5
	elif enemies.size() >= 6 and enemies.size() < MAX_ENEMIES:
		spawn_timer.wait_time = SPAWN_INTERVAL_6_TO_7
	else:
		spawn_timer.stop()  # Stop spawning if at max enemies

func _on_SpawnTimer_timeout():
	if enemies.size() < MAX_ENEMIES:
		spawn_enemy()

func spawn_enemy():
	# Ensure the enemy scene is set
	if not enemy_scene:
		print("Error: enemy_scene is not assigned.")
		return

	# Spawn a new enemy
	var enemy = enemy_scene.instantiate()
	add_child(enemy)

	# Set the enemy's position (randomized within a range)
	var random_x = randf_range(100, 900)  # Adjust x range as needed
	enemy.global_position = Vector2(random_x, 588)  # Fixed y position

	# Track the enemy
	enemies.append(enemy)

	# Connect the enemy's "tree_exiting" signal to track when it is removed
	enemy.connect("tree_exiting", Callable(self, "_on_enemy_despawned"))

func _on_enemy_despawned(enemy):
	# Remove the enemy from the list when it is despawned
	if enemy in enemies:
		enemies.erase(enemy)
