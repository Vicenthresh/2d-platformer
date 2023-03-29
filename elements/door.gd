extends Area2D

@export var targetScene: PackedScene
@export var player: CharacterBody2D
@onready var fire = $AnimatedSprite2D

var entered = false
# Called when the node enters the scene tree for the first time.
func _ready():
	fire.play()
	pass # Replace with function body.
func _on_body_entered(body: CharacterBody2D):
	entered = true


func _on_body_exited(body):
	entered = false
	
func _process(delta):
	if entered:
		if Input.is_action_just_pressed("ui_accept"):
			Global.player_position = player.position
			get_tree().change_scene_to_packed(targetScene)
