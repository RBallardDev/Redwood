extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0
const THROW_FORCE = 600.0

var holding_rock = false
var rock_instance = null  # Reference to the rock the player is close to
var is_throwing = false

@onready var animated_sprite = $AnimatedSprite2D
@onready var throw_timer = $ThrowTimer
@onready var rock = $"../Rock"  # Direct reference to the Rock node

func _ready():
	# Reference to the nearby rock
	rock_instance = rock  # Directly reference the rock node in the scene

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

	# Handle jumping
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_throwing:
		velocity.y = JUMP_VELOCITY

	# Horizontal movement
	var horizontal_input = Input.get_axis("ui_left", "ui_right")

	# Cancel throw animation if moving while throwing
	if is_throwing and horizontal_input != 0:
		is_throwing = false
		throw_timer.stop()
		animated_sprite.play("walk")

	if not is_throwing:
		velocity.x = horizontal_input * SPEED

		if horizontal_input != 0:
			animated_sprite.play("walk")
			animated_sprite.flip_h = horizontal_input < 0
		else:
			animated_sprite.play("idle")

	# Trigger throw animation or throw the rock
	if Input.is_action_just_pressed("throw"):
		if holding_rock:
			throw_rock()
		elif not is_throwing and horizontal_input == 0:
			play_throw_animation()

	move_and_slide()

	# Pick up the rock when E is pressed if near a rock
	if rock_instance and rock_instance.player_in_range and Input.is_action_just_pressed("pickup"):
		pick_up_rock()

	# Keep the rock positioned next to the player if holding it
	if holding_rock and rock_instance:
		var rock_offset = Vector2(30, -10)
		rock_instance.global_position = global_position + rock_offset * (-1 if animated_sprite.flip_h else 1)

func play_throw_animation() -> void:
	animated_sprite.play("throw")
	is_throwing = true
	throw_timer.start()

func _on_ThrowTimer_timeout() -> void:
	is_throwing = false
	animated_sprite.play("idle")

# Function to pick up the rock
func pick_up_rock():
	if rock_instance:
		holding_rock = true
		rock_instance.velocity = Vector2.ZERO  # Stop the rock from moving
		print("Rock picked up")  # Debug line

# Function to throw the rock
func throw_rock() -> void:
	if rock_instance:
		var throw_direction = Vector2(1, -0.5) * (-1 if animated_sprite.flip_h else 1)
		rock_instance.velocity = throw_direction * THROW_FORCE
		rock_instance.start_reset_timer()  # Start the timer to stop rock after throwing
		holding_rock = false
		rock_instance = null
