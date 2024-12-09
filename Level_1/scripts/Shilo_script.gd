extends CharacterBody2D

var min_x = -1031
var max_x = 1520

# Constants for movement
const SPEED = 200.0
const JUMP_VELOCITY = -250.0
const GRAVITY = 980.0
const SLIDE_SPEED = 300.0
const CROUCH_WALK_SPEED = 50.0
const WALL_GRAB_TIME = 0.5
const SLIDE_DURATION = 0.5
const DASH_SPEED = 750.0

# States
enum State {IDLE, RUN, JUMP, ATTACK_DASH, CROUCH, CROUCH_WALK, SLIDE, WALL_GRAB, PICKUP}

# Current state
var current_state = State.IDLE

# Timer variables
var wall_grab_timer = 0.0
var attack_timer = 0.0
var idle_rest_timer = 0.0
var dash_sfx_played = false
var slide_timer = 0.0

# Track if dash is active
var is_dashing = false
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

@onready var collision_normal = $CollisionNormal  # Normal hitbox
@onready var collision_slide = $CollisionSlide  # Slide hitbox



var flip_offset = 0

func update_sprite_flip(direction: int):
	if direction < 0:
		animated_sprite.flip_h = true
	elif direction > 0:
		animated_sprite.flip_h = false

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
		State.CROUCH:
			handle_crouch_state()
		State.CROUCH_WALK:
			handle_crouch_walk_state()
		State.SLIDE:
			handle_slide_state(delta)
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
		change_state(State.CROUCH)

func handle_run_state():
	var direction = 0
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
	elif Input.is_action_just_pressed("crouch"):
		change_state(State.SLIDE)

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
		if jump.is_playing():
			jump.stop()
		land.play()
		change_state(State.IDLE)
	elif Input.is_action_just_pressed("crouch"):
		change_state(State.CROUCH)

	if is_on_wall():
		change_state(State.WALL_GRAB)
	elif is_on_floor():
		if jump.is_playing():
			jump.stop()
		land.play()
		change_state(State.IDLE)

func handle_crouch_state():
	velocity.x = 0  # Stay idle while crouching
	animated_sprite.play("crouch")
	animated_sprite.frame = 0  # Updated to first frame for idle crouch

	# Transition to crouch walk when moving while crouching
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("run_left") or Input.is_action_pressed("ui_right") or Input.is_action_pressed("run_right"):
		change_state(State.CROUCH_WALK)
	elif not Input.is_action_pressed("crouch"):
		change_state(State.IDLE)

func handle_crouch_walk_state():
	var direction = 0
	# Check for movement
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("run_left"):
		direction = -1
		update_sprite_flip(direction)
	elif Input.is_action_pressed("ui_right") or Input.is_action_pressed("run_right"):
		direction = 1
		update_sprite_flip(direction)

	velocity.x = direction * CROUCH_WALK_SPEED
	animated_sprite.play("crouch")  # Loop through crouch animation for movement

	# Cancel crouch walk when shift is released
	if not Input.is_action_pressed("crouch"):
		if direction != 0:  # Transition to RUN if movement keys are still held
			change_state(State.RUN, direction)
		else:
			change_state(State.IDLE)

func handle_slide_state(delta):
	slide_timer -= delta

	# Allow jumping out of slide
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("jump"):
		if slide.is_playing():
			slide.stop()
		change_state(State.JUMP)
		return

	# Cancel slide when crouch key is released
	if not Input.is_action_pressed("crouch"):
		if slide_timer > 0:  # Ensure it's still sliding before stopping sound
			if slide.is_playing():
				slide.stop()
		change_state(State.IDLE)
		return

	# Transition to crouch walk when slide timer ends
	if slide_timer <= 0:
		if slide.is_playing():
			slide.stop()
		change_state(State.CROUCH_WALK)
		return

	velocity.x = SLIDE_SPEED * (1 if not animated_sprite.flip_h else -1)
	animated_sprite.play("crouch")
	animated_sprite.frame = 1  # Updated to second frame for slide
	if not slide.is_playing():
		slide.play()
		
func handle_attack_dash_state():
	attack_timer -= get_physics_process_delta_time()
	is_dashing = true
	if attack_timer > 0:
		animated_sprite.play("attack")
		if jump.is_playing():
			jump.stop()  # Stop jump audio if dashing
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

func handle_wall_grab_state(delta):
	wall_grab_timer += delta
	velocity.y = 0
	animated_sprite.play("climb")
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		change_state(State.JUMP)
	elif wall_grab_timer > WALL_GRAB_TIME:
		change_state(State.IDLE)

func handle_pickup():
	change_state(State.IDLE)
	pickup.play()

func change_state(new_state, direction = 0):
	# Handle collision shape changes for SLIDE state
	if current_state == State.SLIDE and new_state != State.SLIDE:
		collision_slide.disabled = true
		collision_normal.disabled = false

	if new_state == State.SLIDE:
		collision_slide.disabled = false
		collision_normal.disabled = true

	current_state = new_state
	if new_state != State.RUN:
		running_sound.stop()
	match new_state:
		State.IDLE:
			velocity.x = 0
			animated_sprite.play("idle")
		State.RUN:
			velocity.x = direction * SPEED
			animated_sprite.play("run")
		State.JUMP:
			velocity.y = JUMP_VELOCITY
			animated_sprite.play("jump")
			if not jump.is_playing():
				jump.play()
		State.CROUCH:
			velocity.x = 0
			animated_sprite.play("crouch")
			animated_sprite.frame = 0
		State.CROUCH_WALK:
			animated_sprite.play("crouch")
		State.SLIDE:
			slide_timer = SLIDE_DURATION
			animated_sprite.play("crouch")
			animated_sprite.frame = 1
			if not slide.is_playing():
				slide.play()
		State.ATTACK_DASH:
			is_dashing = true
			attack_timer = 0.3
		State.WALL_GRAB:
			wall_grab_timer = 0.8
		State.PICKUP:
			pickup.play()
