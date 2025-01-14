extends Area2D

# Constants for speed and ranges
const PATROL_SPEED = 50
const CHASE_SPEED = 100
const DETECTION_RADIUS = 200
const ATTACK_RADIUS = 50
const PATROL_DISTANCE = 100

# Variables for state management
enum State { IDLE, PATROL, CHASE, ATTACK, DEATH }
var current_state = State.IDLE
var direction = 1  # Patrol direction (1 for right, -1 for left)
var patrol_start_position = Vector2()
var idle_timer = 0.0
var health = 1  # Enemies die in one hit for simplicity

# References to player and animation
@onready var player = get_parent().get_node("Shilo")  # Adjust the path
@onready var animated_sprite = $AnimatedSprite2D
@onready var timer = $Timer  # Timer node to handle delays like death

func _ready():
	patrol_start_position = global_position
	add_to_group("enemies")
	print("Enemy ready!")

func _process(delta):
	# Process only if not in death state
	if current_state != State.DEATH:
		match current_state:
			State.IDLE:
				handle_idle_state(delta)
			State.PATROL:
				handle_patrol_state(delta)
			State.CHASE:
				handle_chase_state(delta)
			State.ATTACK:
				handle_attack_state()

	# Flip sprite to face the player or patrol direction
	if current_state != State.DEATH:  # Don't flip during death animation
		animated_sprite.flip_h = (player.global_position.x < global_position.x)

# State Handlers
func handle_idle_state(delta):
	animated_sprite.play("idle")
	if player_in_detection_radius():
		change_state(State.CHASE)
	else:
		idle_timer -= delta
		if idle_timer <= 0:
			change_state(State.PATROL)

func handle_patrol_state(delta):
	animated_sprite.play("walk")
	patrol_area(delta)
	if player_in_detection_radius():
		change_state(State.CHASE)

func handle_chase_state(delta):
	if player.global_position.distance_to(global_position) <= ATTACK_RADIUS:
		change_state(State.ATTACK)
		return

	animated_sprite.play("walk")
	move_towards_player(delta)

func handle_attack_state():
	# If close to player, stay idle
	if player.global_position.distance_to(global_position) <= ATTACK_RADIUS:
		animated_sprite.play("idle")
	else:
		change_state(State.CHASE)

# Collision Handling
func _on_body_entered(body):
	if body.name == "Shilo" and body.is_attacking():  # Check if Shilo is attacking
		die()

# Utility Functions
func player_in_detection_radius() -> bool:
	return global_position.distance_to(player.global_position) <= DETECTION_RADIUS

func patrol_area(delta):
	global_position.x += direction * PATROL_SPEED * delta  # Move horizontally
	if abs(global_position.x - patrol_start_position.x) > PATROL_DISTANCE:
		direction *= -1  # Change direction at patrol bounds

func move_towards_player(delta):
	var direction_to_player = (player.global_position - global_position).normalized()
	global_position.x += direction_to_player.x * CHASE_SPEED * delta  # Move towards player horizontally

# Death and Animation Fix
func die():
	if current_state == State.DEATH:
		return  # Prevent multiple calls to die()

	print("Enemy defeated!")
	current_state = State.DEATH

	# Randomize facing direction for death animation
	if randi() % 2 == 0:
		animated_sprite.flip_h = true  # Face away from Shilo
	else:
		animated_sprite.flip_h = false  # Face towards Shilo

	# Play the death animation
	animated_sprite.play("death")
	print("Playing death animation")

	# Wait for death animation using the timer
	timer.start(.8)  # Adjust duration for your "death" animation

func _on_Timer_timeout():
	if current_state == State.DEATH:
		print("Removing enemy after death animation.")
		queue_free()  # Remove the enemy from the scene

# State Transitions
func change_state(new_state):
	if current_state == new_state:
		return

	current_state = new_state
	match new_state:
		State.IDLE:
			idle_timer = 3.0
			direction = 0  # Stop horizontal movement when idle
		State.PATROL:
			direction = 1 if randf() > 0.5 else -1  # Randomize patrol direction
		State.CHASE:
			direction = 0  # Reset patrol direction
