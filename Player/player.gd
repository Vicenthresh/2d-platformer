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
@onready var label = $Label # This label will display the heart count
@onready var dash_node = $"../Dash"
@onready var dash_animSprite = $"../Dash/AnimatedSprite2D"

var hearts_trail: Array[Node2D] = [] # To store the chain of collected hearts
var raycast_length: float = 12.0
# Jump Buffer
@onready var jump_buffer_timer = $JumpBufferTimer
var jumpBuffered: bool = false
# Dash
var direction
var knockback := Vector2.ZERO
var knockbackTween
var can_jump: bool = true

var state := 'normal'
var max_hp := 1
var current_hp = max_hp
var max_jumps = 1
var jumps_left = max_jumps
var can_dash: bool = false
var dashing: bool = false
var dash_direction = Vector2(1, 0)
var wall_jump_vector = Vector2(250, -100)

signal hp_changed(current_hp)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var rotating = false
#@onready var animSprite = $AnimatedSprite2D
@onready var animSprite = $AnimatedSprite2D_doggy

@onready var wall_ray = $RayCast2D
#@onready var label = $Label
#@onready var collision = $CollisionShape2D
# Sounds
@onready var jump_sound = $JumpSound
@onready var damage_sound = $DamageSound

@export var wall_slide_velocity = 80

func _ready():
	#Engine.time_scale = 0.5
	animSprite.is_playing()
	
func _process(_delta):
	if Input.is_action_just_pressed('reset'):
		get_tree().reload_current_scene()
		
func _physics_process(delta):
	label.set_text(str(velocity))
	
	if rotating:
		velocity.x = 0
		return
	# Low gravity
	#delta=delta*0.5
	var max_speed
	# Add the gravity
	if not is_on_floor():
		if can_jump:
			# TODO: Create Timer Node for coyote time
			get_tree().create_timer(coyote_time).timeout.connect(coyoteTimeout)
		# if is falling
		if velocity.y > 0:
			# TODO: Make wall jump possible only on a specfici TileMapLayer
			if wall_collider():
					velocity.y = wall_slide_velocity
					jumps_left = max_jumps
					can_jump = true
			# More gravity when falling to add weight
			else:
				velocity.y += gravity * 1.5 * delta

		elif !dashing:
			velocity.y += gravity * delta
		
		SPEED = 30.0
		max_speed = max_air_speed
	# if is on floor reset variables
	else:
		can_jump = true
		can_dash = true
		jumps_left = max_jumps
		max_speed = max_running_speed

	# Handle Jump.
	if ((Input.is_action_just_pressed("jump")) and (can_jump or jumps_left > 0)) or (can_jump and jumpBuffered):
#		if abs(velocity.x) == max_running_speed:
#			velocity.y = JUMP_VELOCITY - (abs(velocity.x) * 0.2)
#			max_air_speed = 200
#		else:
		if wall_collider():
			if direction < 0:
				velocity = wall_jump_vector
			elif direction > 0:
				velocity = Vector2(-1, 1) * wall_jump_vector
				
		jump_sound.play()
		velocity.y = JUMP_VELOCITY
		#velocity.y = JUMP_VELOCITY - (abs(velocity.x) * 0.2)		
		jumps_left -= 1
		if (jumps_left == 0):
			can_jump = false
	elif (Input.is_action_just_pressed("jump") and !can_jump):
		if !jumpBuffered:
			jumpBuffered = true
			jump_buffer_timer.start()
		
	
	if Input.is_action_just_pressed("dash") and can_dash:
		#ghost_timer.start()
		if (animSprite.flip_h):
			dash_direction = Vector2(1, 0)
		else:
			dash_direction = Vector2(-1, 0)
		# TOFIX: When pressing a direction key, dash X velocity is weaker
		velocity = dash_direction.normalized() * 500
		can_dash = false
		dashing = true
		dash_node.set_orientation(!animSprite.flip_h)
		dash_node.show_effect()
		dash_node.global_position = Vector2(global_position.x - 200, global_position.y - 150)
		print(global_position)
		await get_tree().create_timer(0.1).timeout
		#ghost_timer.stop()
		dashing = false

	direction = Input.get_axis("ui_left", "ui_right")
	if direction > 0:
		animSprite.flip_h = true
		wall_ray.target_position.x = 5
		if not dashing:
			velocity.x = move_toward(velocity.x, max_speed, SPEED)
	elif direction < 0:
		animSprite.flip_h = false
		wall_ray.target_position.x = -5
		if not dashing:
			velocity.x = move_toward(velocity.x, -max_speed, SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, STOPPING_SPEED)
		
	var collision = move_and_slide()
			
	if state == 'normal':
		get_animation(velocity)
				
	if collision:
		var last_slide = get_last_slide_collision()
		var collider = last_slide.get_collider()

		if collider is TileMapLayer:
			var tile_rid = last_slide.get_collider_rid()
			var layer_of_collision = PhysicsServer2D.body_get_collision_layer(tile_rid)
			if layer_of_collision == DANGER_LAYER_BIT and state != 'hurt':
				take_damage(1)
			
		
func get_animation(vel):
	if vel.y > 0:
		animSprite.play('fall')
	elif vel.y < 0 or not is_on_floor():
		animSprite.play('jump')
	elif vel.x != 0:
		animSprite.play('run')
	else:
		animSprite.play('idle')
		
func take_damage(damage, knockback_vector: Vector2 = Vector2(400, -250), timer: float = 0.6):
	damage_sound.play()
	current_hp -= damage
	hp_changed.emit(current_hp)
	animSprite.play('damage')
	if hearts_trail.size() > 0:
		remove_heart()
	
	if knockback_vector != Vector2.ZERO and state != 'hurt':
		state = 'hurt'
		knockback = knockback_vector
		if direction < 0:
			velocity = knockback_vector
		elif direction > 0:
			velocity = Vector2(-1, 1) * knockback_vector
		else:
			velocity = Vector2(0, -knockback_vector.x)
		animSprite.modulate = Color.RED
		knockbackTween = get_tree().create_tween()
		knockbackTween.tween_property(animSprite, "modulate", Color.WHITE, timer)
		knockbackTween.tween_callback(_damage_finished)
		
func die():
	get_tree().reload_current_scene()

func _damage_finished():
	if current_hp < 1:
		die()
	state = 'normal'

func coyoteTimeout():
	can_jump = false

func add_ghost():
	var ghost = ghost_node.instantiate()
	ghost.set_properties(position, animSprite.scale, animSprite.sprite_frames, animSprite.animation, animSprite.frame, animSprite.flip_h)
	get_tree().current_scene.add_child(ghost)

func _on_ghost_timer_timeout():
	add_ghost()
	
func wall_collider():
	return wall_ray.is_colliding() and direction != 0

func _on_jump_buffer_timer_timeout() -> void:
	jumpBuffered = false

# Called by a heart when it's collected
func add_heart_to_trail(new_heart_node: Node2D):
	var target_for_new_heart: Node2D
	if hearts_trail.is_empty():
		target_for_new_heart = self
	else:
		target_for_new_heart = hearts_trail.back()

	hearts_trail.append(new_heart_node)
	num_hearts = hearts_trail.size()
	current_hp += 1

	if new_heart_node.has_method("set_follow_target_and_player_ref"):
		new_heart_node.set_follow_target_and_player_ref(target_for_new_heart, self)
	else:
		print_debug("Player: Heart node is missing 'set_follow_target_and_player_ref' method.")

func remove_heart():
	var last_heart = hearts_trail.pop_back()
	if last_heart.has_method("delete_heart"):
		last_heart.delete_heart(self)


func _on_animated_sprite_2d_doggy_animation_finished() -> void:
	print('hello')
	if animSprite.animation == "rotate_r_to_l" or animSprite.animation == "rotate_l_to_r":
		print('rotate end')
		rotating = false


func _on_animated_sprite_2d_doggy_animation_changed() -> void:
	if animSprite.animation == "rotate_r_to_l" or animSprite.animation == "rotate_l_to_r":
		print('rotate end')
		rotating = false
