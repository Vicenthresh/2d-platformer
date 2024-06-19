extends CharacterBody2D


@export var SPEED: float = 25.0
@export var STOPPING_SPEED: float = 15.0
@export var JUMP_VELOCITY: float = -300.0
@export var max_running_speed: float = 180
@export var max_air_speed: float = max_running_speed * 0.9
@export var coyote_time: float = 0.05

# Ghost
@export var ghost_node : PackedScene
@onready var ghost_timer = $GhostTimer
@onready var label = $Label

# Dash
@export var dash_node : PackedScene

var direction
var knockback: = Vector2.ZERO
var knockbackTween
var can_jump: bool = true

var state: = 'normal'
var max_hp: = 3
var current_hp = max_hp
var max_jumps = 2
var jumps_left = max_jumps
var can_dash: bool = false
var dashing: bool = false
var dash_direction = Vector2(1,0)

signal hp_changed(current_hp)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animSprite = $AnimatedSprite2D
@onready var wall_ray = $RayCast2D
#@onready var label = $Label
@onready var collision = $CollisionShape2D
# Sounds
@onready var jump_sound = $JumpSound
@onready var damage_sound = $DamageSound

@export var wall_slide_velocity = 80

func _ready():
	#Engine.time_scale = 0.5
	animSprite.is_playing()
	
func _process(delta):
	if Input.is_action_just_pressed('reset'):
		get_tree().reload_current_scene()
		
func _physics_process(delta):
	#delta=delta*0.5
	var max_speed
	# Add the gravity
	if not is_on_floor():
		if can_jump:
			get_tree().create_timer(coyote_time).timeout.connect(coyoteTimeout)
		if velocity.y > 0:
			if wall_collider():
					velocity.y = wall_slide_velocity
			else:
				velocity.y += gravity*1.5 * delta
		elif !dashing:
			velocity.y += gravity * delta
		
		SPEED = 30.0
		max_speed = max_air_speed
	else:
		can_jump = true
		can_dash = true
		jumps_left = max_jumps
		max_speed = max_running_speed

	# Handle Jump.
	if (Input.is_action_just_pressed("jump")) and jumps_left > 0 and can_jump:
#		if abs(velocity.x) == max_running_speed:
#			velocity.y = JUMP_VELOCITY - (abs(velocity.x) * 0.2)
#			max_air_speed = 200
#		else:
		jump_sound.play()
		velocity.y = JUMP_VELOCITY
		#velocity.y = JUMP_VELOCITY - (abs(velocity.x) * 0.2)		
		jumps_left -= 1
		if(jumps_left == 0):
			can_jump = false
	
	if Input.is_action_just_pressed("dash") and can_dash:
		ghost_timer.start()
		if (animSprite.flip_h):
			dash_direction = Vector2(-1,0)
		else:
			dash_direction = Vector2(1,0)
			
		velocity = dash_direction.normalized() * 500
		can_dash = false
		dashing = true
		add_dash()
		await get_tree().create_timer(0.3).timeout
		ghost_timer.stop()
		dashing = false

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_axis("ui_left", "ui_right")
	if direction > 0:
		animSprite.flip_h = false
		wall_ray.scale.x = 0.5
		velocity.x = move_toward(velocity.x, max_speed, SPEED)
	elif direction < 0:
		wall_ray.scale.x = -0.5		
		animSprite.flip_h = true
		velocity.x = move_toward(velocity.x, -max_speed, SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, STOPPING_SPEED)
		
	move_and_slide()
	
	if state == 'normal':
		get_animation(velocity)
	label.text = str(velocity)
	
	for idx in range(get_slide_collision_count()):
		var collision = get_slide_collision(idx)
		if collision.get_collider().name == 'Danger' and state != 'hurt':
			take_damage(1, Vector2(400 ,-250))
		
func get_animation(velocity):
	if velocity.y > 0:
		animSprite.play('fall')
	elif velocity.y < 0 or not is_on_floor():
		animSprite.play('jump')
	elif velocity.x != 0:
		animSprite.play('run')
	else:
		animSprite.play('idle')
		
func take_damage(damage, knockback_vector:Vector2 = Vector2.ZERO, timer: float = 0.6):
	damage_sound.play()
	current_hp -= damage
	hp_changed.emit(current_hp)
	if(knockback_vector != Vector2.ZERO):
		knockback = knockback_vector
		state = 'hurt'
		if direction < 0:
			velocity = knockback_vector
		elif direction > 0:
			velocity =  Vector2(-1, 1)*knockback_vector
		else:
			velocity = Vector2(0 ,-knockback_vector.x)
		animSprite.modulate = Color.RED
		animSprite.play('damage')
		knockbackTween = get_tree().create_tween()
		knockbackTween.tween_property(animSprite, "modulate", Color.WHITE, timer)
		knockbackTween.tween_callback(_damage_finished)
		
func die():
	get_tree().reload_current_scene()

func _damage_finished():
	if current_hp == 0:
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
	
func add_dash():
	var dash = dash_node.instantiate()
	get_tree().current_scene.add_child(dash)
	
func wall_collider():
	return wall_ray.is_colliding()
