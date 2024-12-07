extends CharacterBody2D

var min_x = -1031
var max_x = 1520

# Constants for movement
const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0
const DASH_SPEED = 750.0
const BUNNYHOP_SPEED = SPEED * 1.8
const WALL_GRAB_TIME = 0.5
const BUNNYHOP_WINDOW = 0.5
const ATTACK_RADIUS = 0.2

# States
enum State {IDLE, RUN, JUMP, ATTACK_DASH, CROUCH_SLIDE, WALL_GRAB}

# Current state
var current_state = State.IDLE

# Timer variables
var wall_grab_timer = 0.0
var bunnyhop_timer = 0.0
var attack_timer = 0.0
var crouch_state = false

# Track if dash/bunnyhop is active
var is_dashing = false
var bunnyhop_active = false

# Reference to the AnimatedSprite node
@onready var animated_sprite = $AnimatedSprite2D

var flip_offset = 20.0  # Adjust this value based on your sprite dimensions

func update_sprite_flip(direction: int):
	if direction < 0:
		animated_sprite.flip_h = true
		animated_sprite.position.x = flip_offset  # Adjust position for left-facing
	elif direction > 0:
		animated_sprite.flip_h = false
		animated_sprite.position.x = 0  # Reset position for right-facing

func _physics_process(delta):
	# Apply gravity by default
	if not is_on_floor() and current_state != State.WALL_GRAB:
		velocity.y += GRAVITY * delta
	if crouch_state:
		velocity.y += (GRAVITY * 1.15) * delta

	# Handle player state
	match current_state:
		State.IDLE:
			handle_idle_state()
		State.RUN:
			handle_run_state()
		State.JUMP:
			handle_jump_state()
		State.ATTACK_DASH:
			handle_attack_dash_state()
		State.CROUCH_SLIDE:
			handle_crouch_slide_state()
		State.WALL_GRAB:
			handle_wall_grab_state(delta)

	move_and_slide()  # Move player based on the final velocity
	position.x = clamp(position.x, min_x, max_x)  # Prevent moving off the map

func handle_idle_state():
	if Input.is_action_just_pressed("attack"):
		change_state(State.ATTACK_DASH)
	elif Input.is_action_pressed("ui_right") or Input.is_action_pressed("run_right"):
		change_state(State.RUN, 1)
	elif Input.is_action_pressed("ui_left") or Input.is_action_pressed("run_left"):
		change_state(State.RUN, -1)
	elif Input.is_action_pressed("ui_up") or Input.is_action_pressed("jump"):
		change_state(State.JUMP)
	elif Input.is_action_just_pressed("crouch"):
		change_state(State.CROUCH_SLIDE)
	elif is_on_wall():
		change_state(State.WALL_GRAB)

func handle_run_state():
	var direction = 0

	# Determine direction and flip sprite
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("run_left"):
		direction = -1
		update_sprite_flip(direction)
	elif Input.is_action_pressed("ui_right") or Input.is_action_pressed("run_right"):
		direction = 1
		update_sprite_flip(direction)
	else:
		change_state(State.IDLE)
		return

	velocity.x = direction * SPEED
	animated_sprite.play("run")

	if Input.is_action_just_pressed("attack"):
		change_state(State.ATTACK_DASH)

	if Input.is_action_just_pressed("crouch"):
		change_state(State.CROUCH_SLIDE)

	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("jump"):
		change_state(State.JUMP)

func handle_jump_state():
	var direction = 0
	if Input.is_action_just_pressed("attack"):
		change_state(State.ATTACK_DASH)
	elif Input.is_action_pressed("ui_left") or Input.is_action_pressed("run_left"):
		direction = -1
		update_sprite_flip(direction)
	elif Input.is_action_pressed("ui_right") or Input.is_action_pressed("run_right"):
		direction = 1
		update_sprite_flip(direction)

	velocity.x = direction * SPEED
	animated_sprite.play("jump")

	if is_on_wall():
		change_state(State.WALL_GRAB)
	elif is_on_floor():
		change_state(State.IDLE)

func handle_attack_dash_state():
	attack_timer -= get_physics_process_delta_time()
	is_dashing = true
	if attack_timer > 0:
		animated_sprite.play("attack")
		velocity.x = DASH_SPEED * (1 if not animated_sprite.flip_h else -1)
	else:
		is_dashing = false
		change_state(State.IDLE)

func handle_crouch_slide_state():
	var direction = 0
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("run_left"):
		direction = -1
		update_sprite_flip(direction)
	elif Input.is_action_pressed("ui_right") or Input.is_action_pressed("run_right"):
		direction = 1
		update_sprite_flip(direction)

	if Input.is_action_pressed("crouch"):
		animated_sprite.play("crouch")
		crouch_state = true
		velocity.x = SPEED * direction  # Maintain horizontal movement
	else:
		crouch_state = false
		change_state(State.IDLE)

func handle_wall_grab_state(delta):
	wall_grab_timer += delta
	velocity.y = 0  # Stop falling temporarily
	animated_sprite.play("climb")
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		change_state(State.JUMP)
	elif wall_grab_timer > WALL_GRAB_TIME:
		change_state(State.IDLE)  # Resume falling if no jump input

func attack_hits_enemy():
	return

func change_state(new_state, direction = 0):
	current_state = new_state
	match new_state:
		State.IDLE:
			animated_sprite.play("idle")
			velocity.x = 0
		State.RUN:
			animated_sprite.play("run")
			velocity.x = direction * SPEED
		State.JUMP:
			velocity.y = JUMP_VELOCITY
			animated_sprite.play("jump")
		State.ATTACK_DASH:
			is_dashing = true
			attack_timer = 0.3
		State.CROUCH_SLIDE:
			bunnyhop_timer = BUNNYHOP_WINDOW
		State.WALL_GRAB:
			wall_grab_timer = 0.8
