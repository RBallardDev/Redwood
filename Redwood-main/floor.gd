extends StaticBody2D

@onready var sprite : Sprite2D = $Sprite2D
@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var collision_shape : CollisionShape2D = $CollisionShape2D

# Player state
enum PlayerState { IDLE, RUNNING, JUMPING }
var state = PlayerState.IDLE

# Movement and physics properties
var velocity : Vector2 = Vector2.ZERO
var gravity = 800  # Gravity force pulling the player down
var jump_speed = -400  # Speed applied for jumping
var max_fall_speed = 600  # Maximum fall speed
var run_speed = 200  # Horizontal speed
var is_on_ground = true  # Tracks whether the player is on the ground

func _process(delta):
	handle_input()
	apply_gravity(delta)
	move_player(delta)

# Handles input for movement and jumping
func handle_input():
	if Input.is_action_pressed("ui_right"):
		velocity.x = run_speed
		if state != PlayerState.RUNNING:
			animation_player.play("Run")
			state = PlayerState.RUNNING
	elif Input.is_action_pressed("ui_left"):
		velocity.x = -run_speed
		if state != PlayerState.RUNNING:
			animation_player.play("Run")
			state = PlayerState.RUNNING
	else:
		velocity.x = 0
		if state != PlayerState.IDLE:
			animation_player.play("Idle")
			state = PlayerState.IDLE

	if Input.is_action_just_pressed("ui_jump") and is_on_ground:
		velocity.y = jump_speed
		animation_player.play("Run")  # Reuse run animation for jumping
		is_on_ground = false

# Apply gravity
func apply_gravity(delta):
	if not is_on_ground:
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)

# Moves the player manually by adjusting position
func move_player(delta):
	var new_position = global_position + velocity * delta

	# Collision handling (manually reset position if hitting the ground)
	if new_position.y > 400:  # Example ground level at y = 400
		new_position.y = 400
		velocity.y = 0
		is_on_ground = true

	global_position = new_position
