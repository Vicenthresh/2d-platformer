extends Node2D

@onready var animation_player: AnimationPlayer = $MovingHeart/AnimationPlayer
@onready var area_2d: Area2D = $Area2D
@onready var sprite_2d: AnimatedSprite2D = $MovingHeart/AnimatedSprite2D

@export_range(1, 10) var smoothing_distance: int = 8

var _is_collected: bool = false
var _can_follow: bool = false # New flag to control when following starts
var _is_deleted: bool = false
var _player_orientation_ref: CharacterBody2D = null
var _node_to_follow: Node2D = null

func _ready() -> void:
	sprite_2d.play('test')
	if not sprite_2d.animation_finished.is_connected(_on_animation_player_animation_finished):
		sprite_2d.animation_finished.connect(_on_animation_player_animation_finished)
	
	#if animation_player:
		#animation_player.animation_finished.connect(_on_animation_player_animation_finished)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if _is_collected:
		return

	if body is CharacterBody2D:
		var collector_player = body as CharacterBody2D
		
		if collector_player and collector_player.has_method("add_heart_to_trail"):
			collector_player.add_heart_to_trail(self)
			sprite_2d.play("collect")

func set_follow_target_and_player_ref(target: Node2D, player_node: CharacterBody2D):
	_node_to_follow = target
	_player_orientation_ref = player_node
	_is_collected = true # Now confirm collection
	
	area_2d.set_deferred("monitoring", false) # Disable further collision checks for this heart
	# if animation_player:
		# animation_player.play("Collect")

func delete_heart(target: Node2D):
	_is_deleted = true
	sprite_2d.play("collect")

func _on_animation_player_animation_finished() -> void:
	var current_anim = sprite_2d.animation
	
	if current_anim == "collect" and not _is_deleted:
		_can_follow = true
		sprite_2d.play("appear")
	elif current_anim == "collect" and _is_deleted:
		_is_deleted = false
		self.queue_free()
	elif current_anim == "appear":
		sprite_2d.play("test")

func _physics_process(delta: float) -> void:
	# Only start following if collected, _can_follow is true, and targets are valid
	if _is_collected and _can_follow and is_instance_valid(_node_to_follow) and is_instance_valid(_player_orientation_ref) and smoothing_distance > 0:
		var offset_x_direction = 1.0 if not _player_orientation_ref.animSprite.flip_h else -1.0
		var offset = Vector2(offset_x_direction * 16.0, 0)
		
		var desired_position = _node_to_follow.global_position + offset
		global_position = global_position.lerp(desired_position, delta * float(smoothing_distance))
