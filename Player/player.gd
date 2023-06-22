extends CharacterBody2D


var SPEED = 25.0
var STOPPING_SPEED = 15.0
var JUMP_VELOCITY = -300.0
var max_running_speed: = 180
var max_air_speed = max_running_speed * 0.9
var direction
var knockback: = Vector2.ZERO
var knockbackTween

var state: = 'normal'
var max_hp: = 3
var current_hp = max_hp
var max_jumps = 1
var jumps_left = max_jumps

signal hp_changed(current_hp)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animSprite = $AnimatedSprite2D
@onready var label = $Label
@onready var collision = $CollisionShape2D

func _ready():
	#Engine.time_scale = 0.5
	animSprite.is_playing()
	
func _process(delta):
	if Input.is_action_just_pressed('reset'):
		get_tree().reload_current_scene()
		
func _physics_process(delta):
	var max_speed
	# Add the gravity.
	if not is_on_floor():
		if velocity.y > 0:
			velocity.y += gravity*1.5 * delta
		else:
			velocity.y += gravity * delta
		SPEED = 30.0
		max_speed = max_air_speed
	else:
		jumps_left = max_jumps
		max_speed = max_running_speed

	# Handle Jump.
	if (Input.is_action_just_pressed("jump")) and jumps_left > 0 and is_on_floor():
#		if abs(velocity.x) == max_running_speed:
#			velocity.y = JUMP_VELOCITY - (abs(velocity.x) * 0.2)
#			max_air_speed = 200
#		else:
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_axis("ui_left", "ui_right")
	if direction > 0:
		animSprite.flip_h = false
		velocity.x = move_toward(velocity.x, max_speed, SPEED)
	elif direction < 0:
		animSprite.flip_h = true
		velocity.x = move_toward(velocity.x, -max_speed, SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, STOPPING_SPEED)
		
	move_and_slide()
	
	if state == 'normal':
		get_animation(velocity)
#	label.text = 'vida: ' + str(current_hp)
	label.text = str(velocity)
	
	for idx in range(get_slide_collision_count()):
		var collision = get_slide_collision(idx)
		if collision.get_collider().name == 'Danger' and state != 'hurt':
			take_damage(1, Vector2(400 ,-250))
		
func get_animation(velocity):
	if velocity.y > 0:
		animSprite.play('fall')
	if velocity.x > 0:
#		collision.position = Vector2(-0.5, -0.25)
		if velocity.y < 0:
			animSprite.play("jump")
		elif velocity.y > 0:
			animSprite.play('fall')
		else:
			animSprite.play('run')
	elif velocity.x < 0:
#		collision.position = Vector2(0.5, -0.25)
		if velocity.y < 0:
			animSprite.play("jump")
		elif velocity.y > 0:
			animSprite.play('fall')
		else:
			animSprite.play('run')
	elif velocity.y < 0:
		animSprite.play("jump")
	elif velocity.y > 0:
		animSprite.play('fall')
	else:
		animSprite.play('idle')
		
func take_damage(damage, knockback_vector:Vector2 = Vector2.ZERO, timer: float = 0.6):
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
