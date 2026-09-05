class_name SpawnArea
extends Node2D

func get_random_point() -> Marker2D:
	var points = get_children().filter(func(c): return c is Marker2D)
	if points.is_empty():
		return null
	return points.pick_random()
