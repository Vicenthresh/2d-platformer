extends CharacterBody2D

var GRAVITY = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var JUMP_VELOCITY: float = -500.0

@onready var anim_player = $AnimationPlayer
@onready var animation_tree = $AnimationTree
@onready var jump_timer = $JumpTimer
@onready var jump_start_timer = $JumpStartTimer

var jump = false
var jump_start = false
var is_jumping = false

func _ready():
	animation_tree.active = true
	begin_jump()
	
func _physics_process(delta):
	if jump:
		jump_start = false
		jump = false
		velocity.y = JUMP_VELOCITY
		jump_timer.start()
		
	if not is_on_floor():
		_handle_air_physics(delta)
	
	move_and_slide()
	update_animation_parameters(velocity)

func _handle_air_physics(delta: float):
	velocity.y += GRAVITY * 1.5 * delta
	
	
func update_animation_parameters(vel: Vector2):
	animation_tree.set("parameters/conditions/on_floor", is_on_floor())
	animation_tree.set("parameters/conditions/is_idle", is_on_floor() and abs(vel.x) < 1)
	animation_tree.set("parameters/conditions/jump_start", jump_start)
	animation_tree.set("parameters/conditions/is_jumping", vel.y < 0 and not is_on_floor())
	animation_tree.set("parameters/conditions/is_falling", vel.y > 0.5 and not is_on_floor())
	animation_tree.set("parameters/conditions/is_landing", is_on_floor() and vel.y >= 0)

func begin_jump():
	jump_start = true
	await get_tree().create_timer(0.5).timeout
	jump = true

func _on_jump_timer_timeout() -> void:
	begin_jump()
