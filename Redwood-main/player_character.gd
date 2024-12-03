extends CharacterBody2D  # Using CharacterBody2D for proper physics handling

@onready var sprite : Sprite2D = $Sprite  # Reference to the Sprite2D node
@onready var animation_player : AnimationPlayer = $AnimationSprite2d  # Reference to the AnimationPlayer node

# Player state (idle, run, jump)
enum PlayerState { IDLE, RUNNING, JUMPING }
var state = PlayerState.IDLE

# Jump physics
var jump_speed = -400  # The speed at which the player jumps
var gravity = 800  # Gravity that pulls the player down
var max_fall_speed = 600  # Maximum fall speed to avoid the player falling too fast

# Movement speed
var run_speed = 200  # Horizontal speed when running

# Reference to the player's physics process (for movement and gravity)
func _ready():
	# Check if animation_player is valid before using it
	if animation_player != null:
		animation_player.play("Idle")  # Play idle animation when ready
	else:
		print("Error: AnimationPlayer not found!")

func _process(delta):
	handle_input()  # Handle input for movement and animation switching
	apply_gravity(delta)  # Apply gravity for jump/fall behavior
	update_movement(delta)  # Update player position and physics

# Handle movement input (left/right)
func handle_input():  # Removed unused delta parameter
	# Handle horizontal movement and change animations
	if is_running():
		if state != PlayerState.RUNNING:
			if animation_player != null:
				animation_player.play("Run")  # Switch to running animation
			state = PlayerState.RUNNING
		# Move the player horizontally based on input
		velocity.x = run_speed * Input.get_action_strength("ui_right") - run_speed * Input.get_action_strength("ui_left")
	else:
		if state != PlayerState.IDLE:
			if animation_player != null:
				animation_player.play("Idle")  # Switch to idle animation
			state = PlayerState.IDLE
		velocity.x = 0  # Stop horizontal movement when no input

	# Handle jumping
	if is_jumping() and state != PlayerState.JUMPING:
		if state != PlayerState.JUMPING:
			if animation_player != null:
				animation_player.play("Run")  # Play run animation during jump
			state = PlayerState.JUMPING
		velocity.y = jump_speed  # Apply jump force

# Apply gravity (if the player is in the air)
func apply_gravity(delta):
	if velocity.y < max_fall_speed:
		velocity.y += gravity * delta  # Apply gravity to player if they are falling

# Update the player’s position based on velocity (movement + gravity)
func update_movement(delta):
	move_and_slide()  # No need to pass velocity explicitly

# Check if the player is running
func is_running() -> bool:
	return Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left")

# Check if the player is jumping (jump logic can be modified based on your jumping behavior)
func is_jumping() -> bool:
	return !is_on_floor() and velocity.y < 0  # Example: when player is off the ground and moving upward
