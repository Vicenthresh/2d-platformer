extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D # Adjust "AnimatedSprite2D" if your node has a different name

func play_dash_animation() -> void:
	if animated_sprite:
		animated_sprite.play("dash")
	else:
		print_debug("Dash script: AnimatedSprite2D node not found or not assigned.")

func set_orientation(is_flipped: bool) -> void:
	if animated_sprite:
		animated_sprite.flip_h = !is_flipped
		if is_flipped:
			self.position = Vector2(-7, -0.5)
		else:
			self.position = Vector2(7, -0.5)
			
	else:
		print_debug("Dash script: AnimatedSprite2D node not found or not assigned.")

func show_effect() -> void:
	self.visible = true
	play_dash_animation()

func hide_effect() -> void:
	self.visible = false
	if animated_sprite:
		animated_sprite.stop()
