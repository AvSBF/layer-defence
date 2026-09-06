class_name WeaponWaveController
extends StaticBody2D

@export var move_speed : float = 600
@export var destroy_time : float = 1
var can_move : bool = false
var direction : Vector2

func _ready() -> void:
	get_tree().create_timer(destroy_time).timeout.connect(queue_free)

func set_direction(dir : Vector2):
	direction = dir.normalized()
	rotation = direction.angle()
	can_move = true
	$AnimationPlayer.play("RESET")

func _process(delta: float) -> void:
	if not can_move:
		return
	global_position += direction * move_speed * delta
