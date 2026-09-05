class_name EnemyNavigation
extends Node

var platform_graph : PlatformGraph
var target : Node2D
var current_waypoint : Node2D
var path : Array = []
var path_index : int = 0

func setup(graph : PlatformGraph, tgt : Node2D) -> void:
	platform_graph = graph
	target = tgt

func update_path() -> void:
	if not platform_graph or not target:
		return
	path = platform_graph.find_path(get_parent().global_position, target.global_position)
	path_index = 0
	if path.size() > 1:
		current_waypoint = path[1]
		print("[Nav] Path: ", path.size(), " platforms, next: ", current_waypoint.name)
	else:
		current_waypoint = null

func get_move_direction() -> float:
	if not current_waypoint:
		return 0.0
	var diff = current_waypoint.global_position - get_parent().global_position
	return sign(diff.x)

func is_at_waypoint() -> bool:
	if not current_waypoint:
		return true
	var diff = current_waypoint.global_position - get_parent().global_position
	return abs(diff.x) < 30 and abs(diff.y) < 30

func advance_waypoint() -> void:
	path_index += 1
	if path_index < path.size():
		current_waypoint = path[path_index]
		print("[Nav] Next waypoint: ", current_waypoint.name)
	else:
		current_waypoint = null

func should_jump() -> bool:
	if not current_waypoint:
		return false
	var diff = current_waypoint.global_position - get_parent().global_position
	return diff.y < -20 and abs(diff.x) < 150
