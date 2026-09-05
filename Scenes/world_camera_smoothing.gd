extends Camera2D

@onready var player : CharacterBody2D = $"../Player"

@export var distance_limit_x : float = 1500
@export var distance_limit_y : float = 600
@export var y_pos_limit : Vector2 = Vector2(100,600)
@export var x_pos_limit : Vector2 = Vector2(-400,400)

func _physics_process(delta: float) -> void:
	var abs_pos_player = abs(player.global_position.x)
	var is_negative = player.global_position.x < 0
	var relative_point = abs_pos_player / distance_limit_x
	var cam_pos_x
	if is_negative:
		cam_pos_x = x_pos_limit.x * relative_point
	else:
		cam_pos_x = x_pos_limit.y * relative_point
	
	var relative_point_y = (player.global_position.y - 15) / distance_limit_y
	var cam_pos_y = (y_pos_limit.y - y_pos_limit.x) * relative_point_y - y_pos_limit.x
	
	global_position = Vector2(cam_pos_x,cam_pos_y)
