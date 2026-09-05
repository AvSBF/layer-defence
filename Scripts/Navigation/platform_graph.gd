class_name PlatformGraph
extends Node

var platforms : Array[Node2D] = []
var graph : Dictionary = {}

@export var max_jump_height : float = 300.0
@export var max_jump_distance : float = 400.0
@export var max_fall_distance : float = 500.0

func _ready() -> void:
	call_deferred("_build_graph")

func _build_graph() -> void:
	var world = get_parent()
	if not world:
		return

	var platforms_node = world.get_node_or_null("Platforms")
	if not platforms_node:
		return

	for child in platforms_node.get_children():
		if child is Node2D:
			platforms.append(child)

	platforms.append(_get_floor_platform())

	for i in range(platforms.size()):
		var p = platforms[i]
		graph[p] = []
		for j in range(platforms.size()):
			if i == j:
				continue
			var other = platforms[j]
			if _can_jump(p, other):
				graph[p].append(other)

	print("[PlatformGraph] Platforms: ", platforms.size(), " Edges: ", _count_edges())

func _get_floor_platform() -> Node2D:
	var floor = Node2D.new()
	floor.global_position = Vector2(0, 191)
	floor.name = "FloorNav"
	return floor

func _can_jump(from : Node2D, to : Node2D) -> bool:
	var diff = to.global_position - from.global_position
	var horizontal = abs(diff.x)
	var vertical = diff.y
	var can_go_up = vertical >= -max_jump_height
	var can_go_down = vertical <= max_fall_distance
	var in_range = horizontal <= max_jump_distance
	return in_range and can_go_up and can_go_down

func find_path(start_pos : Vector2, target_pos : Vector2) -> Array:
	var closest_start = _find_closest_platform(start_pos)
	var closest_target = _find_closest_platform(target_pos)
	if not closest_start or not closest_target:
		return []

	if closest_start == closest_target:
		return [closest_target]

	var visited : Dictionary = {}
	var queue : Array = [[closest_start]]
	visited[closest_start] = true

	while queue.size() > 0:
		var path = queue.pop_front()
		var current = path[-1]
		if current == closest_target:
			return path

		if graph.has(current):
			for neighbor in graph[current]:
				if not visited.has(neighbor):
					visited[neighbor] = true
					queue.append(path + [neighbor])

	return []

func _find_closest_platform(pos : Vector2) -> Node2D:
	var closest : Node2D = null
	var min_dist : float = INF
	for p in platforms:
		var platform_top = p.global_position.y - 10
		var dist = abs(pos.x - p.global_position.x) + abs(pos.y - platform_top)
		if dist < min_dist:
			min_dist = dist
			closest = p
	return closest

func _count_edges() -> int:
	var count = 0
	for key in graph:
		count += graph[key].size()
	return count
