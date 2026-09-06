class_name WeaponWaveController
extends StaticBody2D

@export var move_speed : float = 600
@export var destroy_time : float = 1
var can_move : bool = false
var direction : float

func _ready() -> void:
	get_tree().create_timer(destroy_time).timeout.connect(queue_free)

func set_direction(is_left : bool):
	direction = -1 if is_left else 1
	if direction == -1:
		scale.x = -scale.x
	can_move = true
	
func _process(delta: float) -> void:
	if not can_move:
		return
	global_position.x += direction * move_speed * delta
