extends Node2D

@onready var camera : Camera2D = $"../Camera2D"
@onready var player : CharacterBody2D = $".."

@export var max_distance_x : float = 50
@export var max_distance_y : float = 25
@export var smooth_speed : float = 0.7

var increase_speed_delay : float = 1.5

func _ready() -> void:
	camera.position = Vector2.ZERO

func _physics_process(delta: float) -> void:
	var current_velocty : Vector2 = player.velocity
	current_velocty.x = clampf(current_velocty.x, -max_distance_x, max_distance_x)
	current_velocty.y = clampf(current_velocty.y, -max_distance_y, max_distance_y)
	
	camera.position = lerp(camera.position, current_velocty, smooth_speed * delta)

	if current_velocty == Vector2.ZERO:
		increase_speed_delay -= delta
		if increase_speed_delay > 0:
			return
		camera.position = lerp(camera.position, Vector2.ZERO, smooth_speed * 10 * delta)
	else:
		increase_speed_delay = 1
