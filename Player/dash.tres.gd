extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	print('dashing')
	animated_sprite.play("dash")
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	if animated_sprite.animation == 'dash':
		print('dash delete')
		queue_free()
