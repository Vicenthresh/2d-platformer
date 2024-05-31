extends Area2D

@onready var animSprite = $AnimatedSprite2D
@export var bounce_impulse = Vector2(0, -500) 


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_body_entered(body):
	if body is CharacterBody2D:
		body.velocity = bounce_impulse
		animSprite.play("contract")
