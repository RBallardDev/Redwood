# FILENAME: shilo.gd

extends CharacterBody2D

# Variable to track the rope's pickup state
var rope_in_range = false  # Is the rope within interaction range?
var held_item = null  # Track the item being held (if any)

# Reference to interaction Area2D
@onready var interaction_area = $Area2D  # Adjust path if necessary

#@onready var rope = get_parent().get_node("Rope")
#var rope = get_parent().get_node("Rope")
var rope = null

# Constants
const PICKUP_KEY = "pickup_drop"  # Key for picking up/dropping items

var min_x = -1031
var max_x = 1515
var min_y = 370

# Constants for movement
const SPEED = 200.0
const JUMP_VELOCITY = -250.0
const GRAVITY = 980.0
const SLIDE_SPEED = 300.0
const CROUCH_WALK_SPEED = 50.0
const WALL_GRAB_TIME = 0.5
const SLIDE_DURATION = 0.5
const DASH_SPEED = 750.0

const DROP_KEY = "pickup_drop"  # Key for dropping items

const DROP_OFFSET = Vector2(10, 0)



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

func _ready():
	# Locate the rope in the level
	rope = get_parent().get_node("Rope")
	if rope:
		print("Rope found:", rope.name)
	else:
		print("Rope not found!")


func update_sprite_flip(direction: int):
	
	if direction < 0:
		animated_sprite.flip_h = true
	elif direction > 0:
		animated_sprite.flip_h = false

func _process(delta: float) -> void:
	#if rope and rope.player_in_range and Input.is_action_just_pressed("pickup_drop"):
		#rope.pick_up()

	#if rope.player_in_range and Input.is_action_just_pressed("pickup_drop"):
		#if rope.is_picked_up:
			#drop_at()
		#else:
			#pick_up()
	pass
	

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

	move_and_slide()  # Move player based on the final velocity
	position.x = clamp(position.x, min_x, max_x, )
	position.y = max(position.y, 370)  # Prevent moving off the map

func handle_idle_state():
		  # Skip further state handling during interaction

	# Allow transitions to other states
	if Input.is_action_just_pressed("attack"):
		change_state(State.ATTACK_DASH)
	elif Input.is_action_just_pressed("interact"):
		pickup.play()
	elif Input.is_action_just_pressed(" pickup_drop"):
		pickup.play()
	elif Input.is_action_pressed("ui_right") or Input.is_action_pressed("run_right"):
		change_state(State.RUN, 1)
	elif Input.is_action_pressed("ui_left") or Input.is_action_pressed("run_left"):
		change_state(State.RUN, -1)
	elif Input.is_action_pressed("ui_up") or Input.is_action_pressed("jump"):
		change_state(State.JUMP)
	elif Input.is_action_just_pressed("crouch"):
		change_state(State.CROUCH)
	#elif Input.is_action_just_pressed("pickup_drop"):
		#if rope.player_in_range:
			#if rope.is_picked_up:
				#drop_at()
			#else:
				#pick_up()
		

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

	# Allow horizontal movement while in the jump state
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("run_left"):
		direction = -1
		update_sprite_flip(direction)
	elif Input.is_action_pressed("ui_right") or Input.is_action_pressed("run_right"):
		direction = 1
		update_sprite_flip(direction)

	velocity.x = direction * SPEED

	# Allow attack dash during jump
	if Input.is_action_just_pressed("attack"):
		change_state(State.ATTACK_DASH)

	# Handle transitions
	if is_on_floor():
		if jump.is_playing():
			jump.stop()  # Stop the jump sound when landing
		land.play()
		change_state(State.IDLE)
	elif Input.is_action_just_pressed("crouch"):
		change_state(State.CROUCH)

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

	# If there is no movement, transition back to crouch
	if direction == 0:
		change_state(State.CROUCH)
		return

	# Apply movement and play crouch walk animation
	velocity.x = direction * CROUCH_WALK_SPEED
	animated_sprite.play("crouch")  # Crouch walk animation

	# Cancel crouch walk when shift is released
	if not Input.is_action_pressed("crouch"):
		if direction != 0:
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
		if slide_timer > 0 and slide.is_playing():
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
	animated_sprite.frame = 1  # Slide frame
	if not slide.is_playing():
		slide.play()

func handle_attack_dash_state():
	
	attack_timer -= get_physics_process_delta_time()
	is_dashing = true

	if attack_timer > 0:
		animated_sprite.play("attack")
		if jump.is_playing():
			jump.stop()  # Stop jump sound during dash
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

func is_attacking() -> bool:
	return current_state == State.ATTACK_DASH

func handle_wall_grab_state(delta):
	wall_grab_timer += delta
	velocity.y = 0
	animated_sprite.play("climb")
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		change_state(State.JUMP)
	elif wall_grab_timer > WALL_GRAB_TIME:
		change_state(State.IDLE)

# Update the collision boxes in change_state
func change_state(new_state, direction = 0):
	
	
	
	if current_state == new_state:
		print("Warning: Already in state", new_state)
		return
	
	# Stop jump sound if leaving jump state
	if current_state == State.JUMP and new_state != State.JUMP:
		if jump.is_playing():
			jump.stop()
	
	if current_state == State.SLIDE or current_state == State.CROUCH or current_state == State.CROUCH_WALK:
		collision_slide.disabled = true
		collision_normal.disabled = false
	
	if new_state == State.SLIDE or new_state == State.CROUCH or new_state == State.CROUCH_WALK:
		collision_slide.disabled = false
		collision_normal.disabled = true
		
	if current_state == State.ATTACK_DASH and new_state != State.ATTACK_DASH:
		is_dashing = false  # Reset is_dashing when leaving the dash state

	# Update state
	current_state = new_state

	# Stop running sound if leaving run state
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
			animated_sprite.frame = 0  # Crouch idle frame
		State.CROUCH_WALK:
			animated_sprite.play("crouch")  # Crouch walk animation
		State.SLIDE:
			slide_timer = SLIDE_DURATION
			animated_sprite.play("crouch")
			animated_sprite.frame = 1  # Slide animation
			if not slide.is_playing():
				slide.play()
		State.ATTACK_DASH:
			is_dashing = true
			attack_timer = 0.3
		State.WALL_GRAB:
			wall_grab_timer = 0.8
		State.PICKUP:
			pickup.play()


#func pick_up():
	#if Input.is_action_just_pressed("pickup_drop"):
		#rope.pick_up()
	#
#func drop_at():
	#
	#rope.drop_at(global_position)
