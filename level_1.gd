extends Node2D  # Attach this to the root node of your scene

@onready var background_sprite : Sprite2D = $Background/Sprite2D  # Reference to the background sprite

# Store original background texture size for scaling logic
var original_texture_size : Vector2

func _ready():
	if background_sprite:
		original_texture_size = background_sprite.texture.get_size()
		center_and_scale_background()

# Called every frame to check if the window has resized
func _process(delta):
	if background_sprite:
		center_and_scale_background()

# Function to scale and center the background
func center_and_scale_background():
	if not background_sprite:
		return  # Ensure background sprite exists before proceeding

	var viewport_size = get_viewport().size  # Get the current size of the viewport
	var texture_size = original_texture_size  # Use the original texture size for scaling logic

	# Convert viewport size to Vector2 (in case it's Vector2i)
	var viewport_size_vec2 = Vector2(viewport_size.x, viewport_size.y)

	# Calculate the scale factor that ensures the background fills the screen
	var scale_factor = max(viewport_size_vec2.x / texture_size.x, viewport_size_vec2.y / texture_size.y)

	# Apply the scale to the background sprite (only for the background)
	background_sprite.scale = Vector2(scale_factor, scale_factor)

	# Center the background sprite based on the new scale and texture size
	var scaled_texture_size = texture_size * background_sprite.scale
	background_sprite.position = (viewport_size_vec2 - scaled_texture_size) / 2
