extends CharacterBody2D

# ============================================================
# CONSTANTS
# ============================================================
var DANGER_LAYER_BIT: int = 2

# ============================================================
# EXPORTS - Movement
# ============================================================
@export var SPEED: float = 25.0
@export var STOPPING_SPEED: float = 15.0
@export var JUMP_VELOCITY: float = -300.0
@export var max_running_speed: float = 180
@export var max_air_speed: float = max_running_speed * 0.9
@export var wall_slide_velocity: float = 80

# ============================================================
# EXPORTS - Jump & Combat
# ============================================================
@export var coyote_time: float = 0.05
@export var num_hearts: int = 0

# ============================================================
# EXPORTS - Effects
# ============================================================
@export var ghost_node: PackedScene

# ============================================================
# NODE REFERENCES
# ============================================================
@onready var sprite2d = $Sprite2D
@onready var animation_tree = $Animation/AnimationTree
@onready var wall_ray = $RayCast2D
@onready var ghost_timer = $GhostTimer
@onready var jump_buffer_timer = $JumpBufferTimer
@onready var label = $Label
@onready var jump_sound = $JumpSound
@onready var damage_sound = $DamageSound

# ============================================================
# SCENES REFERENCES
# ============================================================
var DashScene: = preload('res://Player/dash.tscn')

# ============================================================
# DIRECTION STATE (Single Source of Truth)
# ============================================================
var current_direction: int = 1 # 1 = right, -1 = left
var previous_direction: int = 1

# ============================================================
# MOVEMENT STATE
# ============================================================
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var dash_direction := Vector2(1, 0)
var wall_jump_vector := Vector2(250, -300)  # Increased Y to match regular jump
var knockback := Vector2.ZERO
var just_wall_jumped: bool = false  # Track if we just wall jumped

# ============================================================
# ABILITY STATE
# ============================================================
var can_jump: bool = true
var can_dash: bool = false
var dashing: bool = false
var max_jumps: int = 1
var jumps_left: int = max_jumps
var jumpBuffered: bool = false

# ============================================================
# HEALTH STATE
# ============================================================
var state := "normal"
var max_hp := 1
var current_hp: int = max_hp
var hearts_trail: Array[Node2D] = []

# ============================================================
# ANIMATION STATE
# ============================================================
var state_machine
var current_state: String = ""
var previous_state: String = ""
var is_turning: bool = false

# ============================================================
# MISC
# ============================================================
var knockbackTween
var raycast_length: float = 12.0

# ============================================================
# SIGNALS
# ============================================================
signal hp_changed(current_hp)

# ============================================================
# INITIALIZATION
# ============================================================
func _ready():
	animation_tree.active = true
	state_machine = animation_tree["parameters/playback"]

# ============================================================
# PROCESS
# ============================================================
func _process(_delta):
	track_state_change()
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()

# ============================================================
# PHYSICS
# ============================================================
func _physics_process(delta):
	label.text = str(velocity)
	var max_speed: float
	
	# Handle jump input BEFORE gravity
	_handle_jump_input()
	
	# Apply gravity and set speeds (skip gravity on wall jump frame)
	if not is_on_floor():
		_handle_air_physics(delta)
		max_speed = max_air_speed
	else:
		_handle_ground_physics()
		max_speed = max_running_speed
	
	# Handle horizontal movement
	_handle_horizontal_movement(max_speed)
	
	# Handle dash input
	_handle_dash_input()
	
	# Update direction tracking (single source of truth)
	_update_direction()
	
	# Move character
	var collision = move_and_slide()
	
	# Update animations
	if state == "normal":
		update_animation_parameters(velocity)
		track_state_change()
	
	# Check for danger collisions
	_check_danger_collision(collision)

# ============================================================
# PHYSICS HELPERS
# ============================================================
func _handle_air_physics(delta: float):
	if can_jump:
		get_tree().create_timer(coyote_time).timeout.connect(coyoteTimeout)
	
	# Skip gravity application on wall jump frame
	if just_wall_jumped:
		just_wall_jumped = false
		return
	
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

func _handle_ground_physics():
	can_jump = true
	can_dash = true
	jumps_left = max_jumps

func _handle_jump_input():
	if ((Input.is_action_just_pressed("jump")) and (can_jump or jumps_left > 0)) or (can_jump and jumpBuffered):
		if wall_collider():
			# Wall jump - jump away from wall
			velocity = wall_jump_vector * Vector2(-current_direction, 1)
			just_wall_jumped = true  # Flag to skip gravity this frame
		else:
			velocity.y = JUMP_VELOCITY
		
		jump_sound.play()
		jumps_left -= 1
		if jumps_left == 0:
			can_jump = false
	elif Input.is_action_just_pressed("jump") and not can_jump:
		if not jumpBuffered:
			jumpBuffered = true
			jump_buffer_timer.start()

func _handle_horizontal_movement(max_speed: float):
	var input_direction = Input.get_axis("ui_left", "ui_right")
	
	if input_direction > 0:
		wall_ray.target_position.x = 5
		if not dashing:
			velocity.x = move_toward(velocity.x, max_speed, SPEED)
	elif input_direction < 0:
		wall_ray.target_position.x = -5
		if not dashing:
			velocity.x = move_toward(velocity.x, -max_speed, SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, STOPPING_SPEED)

func _handle_dash_input():
	if Input.is_action_just_pressed("dash") and can_dash:
		velocity = dash_direction.normalized() * 500
		can_dash = false
		dashing = true
		
		
		var dash_fx = DashScene.instantiate()
		dash_fx.global_position = global_position
		dash_fx.scale.x = current_direction
		get_tree().current_scene.add_child(dash_fx)
		# Spawn dash effect in world
		#var dash_effect = dash_node.initialize()
		#get_tree().current_scene.add_child(dash_effect)
		#dash_effect.setup(global_position, current_direction)
		
		await get_tree().create_timer(0.2).timeout
		dashing = false

func _update_direction():
	var input_direction = Input.get_axis("ui_left", "ui_right")
	
	if input_direction != 0:
		previous_direction = current_direction
		current_direction = 1 if input_direction > 0 else -1
		
		# Update sprite
		sprite2d.flip_h = (current_direction == 1)
		
		# Update dash direction and orientation
		dash_direction = Vector2(current_direction, 0)

func _check_danger_collision(collision: bool):
	if collision:
		var last_slide = get_last_slide_collision()
		var collider = last_slide.get_collider()
		if collider is TileMapLayer:
			var tile_rid = last_slide.get_collider_rid()
			var layer_of_collision = PhysicsServer2D.body_get_collision_layer(tile_rid)
			if layer_of_collision == DANGER_LAYER_BIT and state != "hurt":
				take_damage(1)

# ============================================================
# ANIMATION
# ============================================================
func update_animation_parameters(vel: Vector2):
	is_turning = (current_direction != previous_direction) and abs(velocity.x) > 0.1
	
	animation_tree.set("parameters/conditions/on_floor", is_on_floor())
	animation_tree.set("parameters/conditions/is_idle", is_on_floor() and abs(vel.x) < 1)
	animation_tree.set("parameters/conditions/is_running", is_on_floor() and abs(vel.x) >= 1)
	animation_tree.set("parameters/conditions/is_jumping", vel.y < 0 and not is_on_floor())
	animation_tree.set("parameters/conditions/is_falling", vel.y > 0.5 and not is_on_floor())
	animation_tree.set("parameters/conditions/landed", is_on_floor() and vel.y >= 0)
	animation_tree.set("parameters/conditions/is_turning", is_turning)
	animation_tree.set("parameters/conditions/is_not_turning", !is_turning)

func track_state_change():
	current_state = state_machine.get_current_node()
	if current_state != previous_state:
		print("State changed: %s → %s" % [previous_state, current_state])
		previous_state = current_state

# ============================================================
# COMBAT & DAMAGE
# ============================================================
func take_damage(damage: int, knockback_vector: Vector2 = Vector2(400, -250), timer: float = 0.6):
	damage_sound.play()
	current_hp -= damage
	hp_changed.emit(current_hp)
	
	if hearts_trail.size() > 0:
		remove_heart()
	
	if knockback_vector != Vector2.ZERO and state != "hurt":
		state = "hurt"
		knockback = knockback_vector
		
		# Apply knockback away from damage source using current_direction
		velocity = knockback_vector * Vector2(-current_direction, 1)
		
		# Flash effect
		modulate = Color.RED
		knockbackTween = get_tree().create_tween()
		knockbackTween.tween_property(self, "modulate", Color.WHITE, timer)
		knockbackTween.tween_callback(_damage_finished)

func _damage_finished():
	if current_hp < 1:
		die()
	state = "normal"

func die():
	get_tree().reload_current_scene()

# ============================================================
# WALL DETECTION
# ============================================================
func wall_collider() -> bool:
	var input_direction = Input.get_axis("ui_left", "ui_right")
	return wall_ray.is_colliding() and input_direction != 0

# ============================================================
# JUMP BUFFER & COYOTE TIME
# ============================================================
func coyoteTimeout():
	can_jump = false

func _on_jump_buffer_timer_timeout() -> void:
	jumpBuffered = false

# ============================================================
# GHOST EFFECT
# ============================================================
func add_ghost():
	var ghost = ghost_node.instantiate()
	get_tree().current_scene.add_child(ghost)

func _on_ghost_timer_timeout():
	add_ghost()

# ============================================================
# HEART TRAIL SYSTEM
# ============================================================
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
