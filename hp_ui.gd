extends Control

@onready var heart_1 = $heart_1
@onready var heart_2 = $heart_2
@onready var heart_3 = $heart_3

var hearts

func _ready():
	hearts = [heart_1, heart_2, heart_3]
	for heart in hearts:
		heart.is_playing()
	
func _on_player_hp_changed(current_hp):
	match (current_hp):
		0:
			hearts[current_hp].play("damage")
		1:
			hearts[current_hp].play("damage")
		2:
			hearts[current_hp].play("damage")

func _on_heart_1_animation_finished():
	if heart_1.animation == "damage":
		heart_1.play("empty")

func _on_heart_2_animation_finished():
	if heart_2.animation == "damage":
		heart_2.play("empty")

func _on_heart_3_animation_finished():
	if heart_3.animation == "damage":
		heart_3.play("empty")
