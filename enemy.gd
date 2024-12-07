extends CharacterBody2D

# Constants for speed and ranges
const PATROL_SPEED = 50
const CHASE_SPEED = 100
const DETECTION_RADIUS = 200
const ATTACK_RADIUS = 50
const PATROL_DISTANCE = 100
const GRAVITY = 980  # Gravity force

# Variables for state management
enum State { IDLE, PATROL, CHASE, ATTACK }
var current_state = State.IDLE
var direction = 1  # Patrol direction (1 for right, -1 for left)
var patrol_start_position = Vector2()
var idle_timer = 0.0
var health = 3 

# Reference to player node
@onready var player = $Shilo_CharBody2D  # Adjust the path
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	patrol_start_position = global_position
	add_to_group("enemies")

func _physics_process(delta):
	# Apply gravity
	velocity.y += GRAVITY * delta

	match current_state:
		State.IDLE:
			handle_idle_state()
		State.PATROL:
			handle_patrol_state()
		State.CHASE:
			handle_chase_state()
		State.ATTACK:
			handle_attack_state()

	# Handle movement and collisions
	move_and_slide()

# State Handlers
func handle_idle_state():
	animated_sprite.play("idle")
	if player_in_detection_radius():
		change_state(State.CHASE)
	else:
		idle_timer -= get_physics_process_delta_time()
		if idle_timer <= 0:
			change_state(State.PATROL)

func take_damage(amount):
	health -= amount
	animated_sprite.play("hurt")
	if health <= 0:
		die()
		
		
func handle_patrol_state():
	animated_sprite.play("walk")
	patrol_area()
	if player_in_detection_radius():
		change_state(State.CHASE)

func handle_chase_state():
	animated_sprite.play("walk")
	move_towards_player()
	if player_in_attack_radius():
		change_state(State.ATTACK)
	elif not player_in_detection_radius():
		change_state(State.PATROL)

func handle_attack_state():
	animated_sprite.play("attack")
	# Implement attack logic
	if not player_in_attack_radius():
		change_state(State.CHASE)

# Utility Functions
func player_in_detection_radius():
	return global_position.distance_to(player.global_position) <= DETECTION_RADIUS

func player_in_attack_radius():
	return global_position.distance_to(player.global_position) <= ATTACK_RADIUS

func patrol_area():
	velocity.x = direction * PATROL_SPEED  # Move horizontally
	if abs(global_position.x - patrol_start_position.x) > PATROL_DISTANCE:
		direction *= -1  # Change direction at patrol bounds

func move_towards_player():
	var direction_to_player = (player.global_position - global_position).normalized()
	velocity.x = direction_to_player.x * CHASE_SPEED  # Move towards player horizontally

func die():
	animated_sprite.play("death")  # Ensure a "death" animation exists
	await animated_sprite.animation_finished
	queue_free()  # Remove the enemy from the scene
	
func change_state(new_state):
	current_state = new_state
	match new_state:
		State.IDLE:
			idle_timer = 3.0
			velocity.x = 0  # Stop horizontal movement when idle
