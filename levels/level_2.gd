extends Node2D

@onready var player = $CharacterBody2D

# Called when the node enters the scene tree for the first time.
func _ready():
	player.position = Global.player_position
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
