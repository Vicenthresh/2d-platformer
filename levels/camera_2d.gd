extends Camera2D

@export_category("Camera Subject")
@export var player: CharacterBody2D
@export var smoothing_enabled: bool = true
@export_range(1, 10) var smoothing_distance: int = 8

func _ready() -> void:
    pass

func _process(_delta: float) -> void:
    pass

func _physics_process(delta: float) -> void:
    # Update the camera position based on the player's position
    if player:
        # var camera_position: Vector2
        position = position.lerp(player.position, delta * 4)
        # if smoothing_enabled:
        #     # Smoothly move the camera towards the player's position
        #     var weight = 1.0 - smoothing_distance / 10.0
        #     camera_position = lerp(global_position, player.global_position, weight)
        # else:
        #     # Instantly move the camera to the player's position
        #     camera_position = player.position
        
        # global_position = camera_position