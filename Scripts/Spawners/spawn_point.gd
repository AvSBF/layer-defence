class_name SpawnPoint
extends Marker2D

@export var spawn_direction : Vector2 = Vector2.LEFT

func get_spawn_position() -> Vector2:
	return global_position

func get_spawn_direction() -> Vector2:
	return spawn_direction.normalized()
