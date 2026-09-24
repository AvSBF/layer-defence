extends Node2D

## Ground shadow for flying enemies. A raycast finds the floor (or platform)
## underneath, and a squashed dark ellipse is drawn there, fading with height.
## It is the cheapest way to answer "where is that bat, actually?".

const MAX_HEIGHT := 420.0

var enemy : Enemy
var _height : float = 0.0
var _ground_y : float = 0.0
var _has_ground : bool = false

func _ready() -> void:
	enemy = get_parent() as Enemy
	z_index = 1
	z_as_relative = false
	visible = false

func _physics_process(_delta : float) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if not enemy.flying or enemy.is_dead:
		visible = false
		return
	var space := get_world_2d().direct_space_state
	if space == null:
		return
	var from := enemy.global_position + Vector2(0, 8)
	var params := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 900))
	params.collision_mask = 1 | 2
	params.exclude = [enemy.get_rid()]
	var hit := space.intersect_ray(params)
	if hit.is_empty():
		visible = false
		return
	_has_ground = true
	_ground_y = hit.position.y
	_height = clampf(_ground_y - from.y, 0.0, MAX_HEIGHT)
	global_position = Vector2(enemy.global_position.x, _ground_y - 1.0)
	var t : float = 1.0 - _height / MAX_HEIGHT
	scale = Vector2(0.45 + 0.75 * t, (0.45 + 0.75 * t) * 0.38)
	modulate.a = 0.10 + 0.30 * t
	visible = true

func _draw() -> void:
	if not _has_ground:
		return
	draw_circle(Vector2.ZERO, 7.0, Color(0.03, 0.02, 0.07, 1.0))
