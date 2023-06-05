extends Control

@onready var hpBar = $hpBar
@onready var heart_1 = $heart_1
@onready var heart_2 = $heart_2
@onready var heart_3 = $heart_3

var hearts

func _ready():
	print('test')
	hearts = [heart_1, heart_2, heart_3]
	for heart in hearts:
		heart.is_playing()
	
func _on_player_hp_changed(current_hp):
	print(current_hp)
	
	match (current_hp):
		0:
			hearts[current_hp].play("damage")
			print(hearts[current_hp])
		1:
			hearts[current_hp].play("damage")
			print(hearts[current_hp])
		2:
			hearts[current_hp].play("damage")
			print(hearts[current_hp])

func _on_heart_1_animation_finished():
	print('a1')
	if heart_1.animation == "damage":
		heart_1.play("empty")

func _on_heart_2_animation_finished():
	print('a2')
	if heart_2.animation == "damage":
		heart_2.play("empty")


func _on_heart_3_animation_finished():
	print('a3')
	if heart_3.animation == "damage":
		heart_3.play("empty")
