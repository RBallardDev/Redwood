extends Area2D

# State tracking
var is_picked_up = false
var player_in_range = false

@onready var npc2_node = get_parent().get_node("npc2")

func _ready():
	# Ensure the rope is hidden and collision is disabled at the start
	self.visible = false
	$CollisionShape2D.disabled = true
	print("Rope initialized: hidden and inactive.")

func activate():
	# Called to make the rope visible and enable collision
	self.visible = true
	$CollisionShape2D.disabled = false
	print("Rope activated: visible and active.")

func _on_area_entered(area: Node) -> void:
	if area.name == "Shilo":
		player_in_range = true
		print("Shilo is near the rope! Press 'E' to pick it up.")

func _on_area_exited(area: Node) -> void:
	if area.name == "Shilo":
		player_in_range = false
		print("Shilo left the rope!")

func _process(delta: float) -> void:
	# Check if player is in range and presses 'E' to interact
	if player_in_range and Input.is_action_just_pressed("interact"):
		pick_up()

func pick_up():
	if not is_picked_up:
		print("Rope picked up!")
		is_picked_up = true
		self.visible = false  # Hide the rope
		$CollisionShape2D.disabled = true  # Disable collision
		# Update NPC2's `picked_up` state
		if npc2_node:
			npc2_node.picked_up = true
			print("NPC 2 notified: Rope has been picked up!")
# Called when Shilo drops the rope
#func drop_at(drop_position):
	#
	#is_picked_up = false
	#global_position = drop_position  # Set the new position
	#self.visible = true
	##$CollisionShape2D.disabled = false  # Re-enable collision
