extends CharacterBody2D

var GRAVITY = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var JUMP_VELOCITY: float = -300.0

@onready var anim_player = $AnimationPlayer
@onready var animation_tree = $AnimationTree
@onready var jump_timer = $JumpTimer

var jump = false

var is_jumping = false

func _ready():
	animation_tree.active = true
	
#func _process(delta: float) -> void:
	#jump_behavior()

func _physics_process(delta):
	# Apply gravity
	move_and_slide()
	update_animation_parameters(velocity)
	
	#if jump:
		#velocity.y = JUMP_VELOCITY
	
	if not is_on_floor():
		_handle_air_physics(delta)
		
		
#func jump_behavior():
	#jump = true
	#jump_timer.start()
	
func _handle_air_physics(delta: float):
	if velocity.y > 0:
		velocity.y += GRAVITY * 1.5 * delta
	
	
func update_animation_parameters(vel: Vector2):
	animation_tree.set("parameters/conditions/on_floor", is_on_floor())
	animation_tree.set("parameters/conditions/is_idle", is_on_floor() and abs(vel.x) < 1)
	animation_tree.set("parameters/conditions/is_jumping", vel.y < 0 and not is_on_floor())
	animation_tree.set("parameters/conditions/is_falling", vel.y > 0.5 and not is_on_floor())
	animation_tree.set("parameters/conditions/is_landing", is_on_floor() and vel.y >= 0)


#func _on_jump_timer_timeout() -> void:
	#jump = false
