extends CharacterBody2D

var min_x = -1031
var max_x = 1530

# Constants for movement
const SPEED = 200.0
const JUMP_VELOCITY = -250.0
const GRAVITY = 980.0
const DASH_SPEED = 750.0
const BUNNYHOP_SPEED = SPEED * 1.8
const WALL_GRAB_TIME = 0.5
const BUNNYHOP_WINDOW = 0.5
const ATTACK_RADIUS = 0.2

# States
enum State {IDLE, RUN, JUMP, ATTACK_DASH, CROUCH_SLIDE, WALL_GRAB, PICKUP}

# Current state
var current_state = State.IDLE

# Timer variables
var wall_grab_timer = 0.0
var bunnyhop_timer = 0.0
var attack_timer = 0.0
var idle_rest_timer = 0.0
var dash_sfx_played = false

# Track if dash/bunnyhop is active
var is_dashing = false
var bunnyhop_active = false
var rested = false

# References to nodes
@onready var animated_sprite = $AnimatedSprite2D
@onready var running_sound = $RunningSFX
@onready var low_stamina = $LowStaminaSFX
@onready var attack_dash = $AttackDashSFX
@onready var attack_dash1 = $AttackDashSFX/AttackDashSFX1
@onready var attack_dash2 = $AttackDashSFX/AttackDashSFX2
@onready var jump = $JumpSFX
@onready var land = $JumpSFX/LandSFX
@onready var pickup = $PickupSFX
@onready var slide = $SlideSFX

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
		State.PICKUP:
			handle_pickup()

	move_and_slide()  # Move player based on the final velocity
	position.x = clamp(position.x, min_x, max_x)  # Prevent moving off the map

func handle_idle_state():
	idle_rest_timer -= get_physics_process_delta_time()
	if Input.is_action_just_pressed("attack"):
		change_state(State.ATTACK_DASH)
	elif Input.is_action_just_pressed("interact"):
		change_state(State.PICKUP)
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
	if idle_rest_timer > 0 and not low_stamina.is_playing():
		low_stamina.play()

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
	if not running_sound.is_playing():
		running_sound.play()
	animated_sprite.play("run")

	if Input.is_action_just_pressed("attack"):
		change_state(State.ATTACK_DASH)
	elif Input.is_action_just_pressed("interact"):
		change_state(State.PICKUP)
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("jump"):
		change_state(State.JUMP)
	elif Input.is_action_just_pressed("crouch"):
		change_state(State.CROUCH_SLIDE)

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
		if jump.is_playing():
			jump.stop()  # Stop the jump sound before landing
		land.play()
		change_state(State.IDLE)
	elif Input.is_action_just_pressed("crouch"):
		change_state(State.CROUCH_SLIDE)

func handle_attack_dash_state():
	attack_timer -= get_physics_process_delta_time()
	is_dashing = true
	if attack_timer > 0:
		animated_sprite.play("attack")
		if not dash_sfx_played:
			match randi() % 3:
				0:
					attack_dash.play()
				1:
					attack_dash1.play()
				2:
					attack_dash2.play()
			dash_sfx_played = true
		velocity.x = DASH_SPEED * (1 if not animated_sprite.flip_h else -1)
	else:
		is_dashing = false
		dash_sfx_played = false
		change_state(State.IDLE)

func handle_crouch_slide_state():
	var direction = 0
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("run_left"):
		direction = -1
		update_sprite_flip(direction)
	elif Input.is_action_pressed("ui_right") or Input.is_action_pressed("run_right"):
		direction = 1
		update_sprite_flip(direction)

	animated_sprite.play("crouch")
	velocity.x = SPEED * direction  # Maintain horizontal movement
	if not slide.is_playing():
		slide.play()  # Play slide sound
	if not Input.is_action_pressed("crouch"):
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

func handle_pickup():
	change_state(State.IDLE)
	pickup.play()

func change_state(new_state, direction = 0):
	current_state = new_state
	if new_state != State.RUN:
		running_sound.stop()
	match new_state:
		State.IDLE:
			animated_sprite.play("idle")
			velocity.x = 0
			idle_rest_timer = 1.0
		State.RUN:
			animated_sprite.play("run")
			velocity.x = direction * SPEED
		State.JUMP:
			velocity.y = JUMP_VELOCITY
			animated_sprite.play("jump")
			if not jump.is_playing():
				jump.play()
		State.ATTACK_DASH:
			is_dashing = true
			attack_timer = 0.3
		State.CROUCH_SLIDE:
			bunnyhop_timer = BUNNYHOP_WINDOW
		State.WALL_GRAB:
			wall_grab_timer = 0.8
		State.PICKUP:
			pickup.play()
