extends CharacterBody2D

var DANGER_LAYER_BIT: int = 2

@export var SPEED: float = 25.0
@export var STOPPING_SPEED: float = 15.0
@export var JUMP_VELOCITY: float = -300.0
@export var max_running_speed: float = 180
@export var max_air_speed: float = max_running_speed * 0.9
@export var coyote_time: float = 0.05
@export var num_hearts: int = 0

# Ghost
@export var ghost_node: PackedScene
@onready var ghost_timer = $GhostTimer
@onready var label = $Label
@onready var dash_node = $"../Dash"

var hearts_trail: Array[Node2D] = []
var raycast_length: float = 12.0

# Jump Buffer
@onready var jump_buffer_timer = $JumpBufferTimer
var jumpBuffered: bool = false

# Dash
var direction
var knockback := Vector2.ZERO
var knockbackTween
var can_jump: bool = true

var state := "normal"
var max_hp := 1
var current_hp = max_hp
var max_jumps = 1
var jumps_left = max_jumps
var can_dash: bool = false
var dashing: bool = false
var dash_direction = Vector2(1, 0)
var wall_jump_vector = Vector2(250, -100)

signal hp_changed(current_hp)

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var rotating = false
@onready var wall_ray = $RayCast2D

@onready var animation_tree = $Animation/AnimationTree
var state_machine
@onready var sprite2d = $Sprite2D

var facing_direction = true
var previous_direction = true
var is_turning = false
# Sounds
@onready var jump_sound = $JumpSound
@onready var damage_sound = $DamageSound

@export var wall_slide_velocity = 80

func _ready():
	
	animation_tree.active = true
	state_machine = animation_tree["parameters/playback"]

func _process(_delta):
	Engine.time_scale = 0.1
	track_state_change()
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()

func _physics_process(delta):
	var max_speed
	# Gravity
	if not is_on_floor():
		if can_jump:
			get_tree().create_timer(coyote_time).timeout.connect(coyoteTimeout)

		if velocity.y > 0:
			if wall_collider():
				velocity.y = wall_slide_velocity
				jumps_left = max_jumps
				can_jump = true
			else:
				velocity.y += gravity * 1.5 * delta
		elif not dashing:
			velocity.y += gravity * delta

		SPEED = 30.0
		max_speed = max_air_speed
	else:
		can_jump = true
		can_dash = true
		jumps_left = max_jumps
		max_speed = max_running_speed

	# Jump
	if ((Input.is_action_just_pressed("jump")) and (can_jump or jumps_left > 0)) or (can_jump and jumpBuffered):
		if wall_collider():
			if direction < 0:
				velocity = wall_jump_vector
			elif direction > 0:
				velocity = Vector2(-1, 1) * wall_jump_vector

		jump_sound.play()
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1
		if jumps_left == 0:
			can_jump = false
	elif Input.is_action_just_pressed("jump") and not can_jump:
		if not jumpBuffered:
			jumpBuffered = true
			jump_buffer_timer.start()

	# Horizontal movement
	direction = Input.get_axis("ui_left", "ui_right")
	if direction > 0:
		wall_ray.target_position.x = 5
		if not dashing:
			velocity.x = move_toward(velocity.x, max_speed, SPEED)
	elif direction < 0:
		wall_ray.target_position.x = -5
		if not dashing:
			velocity.x = move_toward(velocity.x, -max_speed, SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, STOPPING_SPEED)
	
	# Dash
	if Input.is_action_just_pressed("dash") and can_dash:
		velocity = dash_direction.normalized() * 500
		can_dash = false
		dashing = true
		dash_node.visible = true
		dash_node.show_effect()
		dash_node.global_position = global_position + Vector2(-200, -150)

		await get_tree().create_timer(0.2).timeout
		dashing = false

	if direction != 0:
		sprite2d.flip_h = direction > 0
		facing_direction = sprite2d.flip_h
		
		dash_node.set_orientation(sprite2d.flip_h)
		if (sprite2d.flip_h):
			dash_direction = Vector2(1, 0)
		else:
			dash_direction = Vector2(-1, 0)

	var collision = move_and_slide()

	if state == "normal":
		update_animation_parameters(velocity)
		track_state_change()

	if collision:
		var last_slide = get_last_slide_collision()
		var collider = last_slide.get_collider()
		if collider is TileMapLayer:
			var tile_rid = last_slide.get_collider_rid()
			var layer_of_collision = PhysicsServer2D.body_get_collision_layer(tile_rid)
			if layer_of_collision == DANGER_LAYER_BIT and state != "hurt":
				take_damage(1)

var current_state: String = ""
var previous_state: String = ""

func update_animation_parameters(vel: Vector2):
	is_turning = (facing_direction != previous_direction) and abs(velocity.x) > 0.1
	
	animation_tree.set("parameters/conditions/on_floor", is_on_floor())
	animation_tree.set("parameters/conditions/is_idle", is_on_floor() and abs(vel.x) < 1)
	animation_tree.set("parameters/conditions/is_running", is_on_floor() and abs(vel.x) >= 1)
	animation_tree.set("parameters/conditions/is_jumping", vel.y < 0 and not is_on_floor())
	animation_tree.set("parameters/conditions/is_falling", vel.y > 0.5 and not is_on_floor())
	animation_tree.set("parameters/conditions/landed", is_on_floor() and vel.y >= 0)
	animation_tree.set("parameters/conditions/is_turning", is_turning)
	animation_tree.set("parameters/conditions/is_not_turning", !is_turning)
	
	print(str(previous_direction) + '->' + str(facing_direction))
	previous_direction = facing_direction
	
func track_state_change():
	current_state = state_machine.get_current_node()
	# Only print when state actually changes
	if current_state != previous_state:
		print("State changed: %s → %s" % [previous_state, current_state])
		previous_state = current_state

func take_damage(damage, knockback_vector: Vector2 = Vector2(400, -250), timer: float = 0.6):
	damage_sound.play()
	current_hp -= damage
	hp_changed.emit(current_hp)

	if hearts_trail.size() > 0:
		remove_heart()

	if knockback_vector != Vector2.ZERO and state != "hurt":
		state = "hurt"
		knockback = knockback_vector

		if direction < 0:
			velocity = knockback_vector
		elif direction > 0:
			velocity = Vector2(-1, 1) * knockback_vector
		else:
			velocity = Vector2(0, -knockback_vector.x)

		# Flash effect handled via tween on the whole player
		modulate = Color.RED
		knockbackTween = get_tree().create_tween()
		knockbackTween.tween_property(self, "modulate", Color.WHITE, timer)
		knockbackTween.tween_callback(_damage_finished)

func die():
	get_tree().reload_current_scene()

func _damage_finished():
	if current_hp < 1:
		die()
	state = "normal"

func coyoteTimeout():
	can_jump = false

func add_ghost():
	var ghost = ghost_node.instantiate()
	get_tree().current_scene.add_child(ghost)

func _on_ghost_timer_timeout():
	add_ghost()

func wall_collider():
	return wall_ray.is_colliding() and direction != 0

func _on_jump_buffer_timer_timeout() -> void:
	jumpBuffered = false

func add_heart_to_trail(new_heart_node: Node2D):
	var target_for_new_heart: Node2D = self if hearts_trail.is_empty() else hearts_trail.back()
	hearts_trail.append(new_heart_node)
	num_hearts = hearts_trail.size()
	current_hp += 1

	if new_heart_node.has_method("set_follow_target_and_player_ref"):
		new_heart_node.set_follow_target_and_player_ref(target_for_new_heart, self)

func remove_heart():
	var last_heart = hearts_trail.pop_back()
	if last_heart.has_method("delete_heart"):
		last_heart.delete_heart(self)
