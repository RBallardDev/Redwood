extends Node2D

# Max number of enemies allowed on-screen
const MAX_ENEMIES_ON_SCREEN = 16

# Spawn intervals (in seconds)
const SPAWN_INTERVAL_LESS_THAN_3 = 2
const SPAWN_INTERVAL_3_TO_5 = 3
const SPAWN_INTERVAL_6_TO_7 = 4

# Reference to the enemy scene
@export var enemy_scene: PackedScene

# Track currently active enemies
var active_enemy_count = 0
var current_spawn_interval = 0  # Tracks the current interval to avoid redundant changes

# Timer to handle spawning
@onready var spawn_timer = $SpawnTimer

func _ready():
	# Spawn the initial 3 enemies
	for i in range(3):
		spawn_enemy()

	# Start the spawn timer with the shortest interval
	current_spawn_interval = SPAWN_INTERVAL_LESS_THAN_3
	spawn_timer.start(current_spawn_interval)
	print("Game started: Spawn timer started at interval:", current_spawn_interval)

func _process(delta):
	# Adjust the spawn timer's interval based on the current number of active enemies
	var new_spawn_interval = 0
	if active_enemy_count < 3:
		new_spawn_interval = SPAWN_INTERVAL_LESS_THAN_3
	elif active_enemy_count <= 5:
		new_spawn_interval = SPAWN_INTERVAL_3_TO_5
	elif active_enemy_count <= 7:
		new_spawn_interval = SPAWN_INTERVAL_6_TO_7

	# Only update the timer if the interval has changed
	if new_spawn_interval != current_spawn_interval:
		current_spawn_interval = new_spawn_interval
		spawn_timer.wait_time = current_spawn_interval
		print("Spawn interval adjusted to:", current_spawn_interval, "seconds")

	# Ensure the timer is running if more enemies are needed
	if active_enemy_count < MAX_ENEMIES_ON_SCREEN and spawn_timer.is_stopped():
		spawn_timer.start()
		print("Spawn timer restarted.")

func _on_SpawnTimer_timeout():
	if active_enemy_count < MAX_ENEMIES_ON_SCREEN:
		print("Spawn timer timeout: Spawning a new enemy.")
		spawn_enemy()
	else:
		print("Spawn timer timeout: Max enemies on screen, no spawn.")

func spawn_enemy():
	# Validate the enemy scene
	if not enemy_scene:
		print("Error: Enemy scene is not assigned!")
		return

	var enemy = enemy_scene.instantiate()
	add_child(enemy)

	# Randomize the enemy's X position, with a fixed Y position
	var random_x = randf_range(-1000, 1500)  # Adjust range as needed
	enemy.global_position = Vector2(random_x, 588)

	# Increment the active enemy count
	active_enemy_count += 1
	print("Enemy spawned! Active enemies:", active_enemy_count)

	# Connect the enemy's "tree_exiting" signal to detect when it is despawned
	enemy.connect("tree_exiting", Callable(self, "_on_enemy_despawned"))

func _on_enemy_despawned():
	# Reduce the active enemy count when an enemy is removed from the scene
	active_enemy_count -= 1
	print("Enemy despawned. Active enemies:", active_enemy_count)

	# Restart the spawn timer if needed
	if spawn_timer.is_stopped():
		spawn_timer.start()
		print("Spawn timer restarted after despawn.")
