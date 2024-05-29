extends Node2D
@onready var animated = $animated

func _ready():
	ghosting()
	
func set_properties(tx_pos, tx_scale, sprite_frames, animation,  frame, flip):
	animated = get_node("animated")
	position = tx_pos + Vector2(0, -4)
	scale = tx_scale * 2
	animated.sprite_frames = sprite_frames
	animated.play(animation)
	animated.frame = frame
	animated.stop()
	animated.flip_h = flip
	#sprite_2d.frame = frame

func ghosting():
	var tween_fade = get_tree().create_tween()
	
	tween_fade.tween_property(animated, 'self_modulate', Color(1, 1, 1, 0), 0.75)
	
	await tween_fade.finished
	
	queue_free()
