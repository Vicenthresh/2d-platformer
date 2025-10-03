extends CharacterBody2D

const JUMP_SPEED = 300
const GRAVITY = 600

@onready var anim_player = $AnimationPlayer
@onready var animation_tree = $AnimationTree

var is_jumping = false

func _ready():
	animation_tree.active = true
	print('tesstestestestestset')
	print(anim_player.animation_started)


func _process(delta):
	await get_tree().create_timer(0.6).timeout
	is_jumping = !is_jumping
	

func _physics_process(delta):
	# Apply gravity

	#if is_on_floor():
		#velocity.y = -JUMP_SPEED
		

	move_and_slide()
	animation_tree.set("parameters/conditions/is_jumping", is_jumping)
	animation_tree.set("parameters/conditions/not_jumping", not is_jumping)
