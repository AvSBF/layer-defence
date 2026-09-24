extends Camera2D

## Arena camera: smooth follow + trauma shake + zoom punch.
##
## Shake is "trauma based": events add trauma, and the actual displacement uses
## trauma^2 so small hits barely move the camera while big hits slam it. The
## offset itself is sampled from a smooth Perlin noise field instead of random
## numbers, which is what makes it read as a camera rattle and not as jitter.

@export var target_path : NodePath
@export var trauma_decay : float = 1.6
@export var max_offset : Vector2 = Vector2(14.0, 10.0)
@export var max_roll : float = 0.035
@export var noise_frequency : float = 22.0
@export var base_zoom : Vector2 = Vector2(2.0, 2.0)
@export var follow_speed : float = 8.0
@export var look_ahead : float = 48.0
@export var look_offset_y : float = -50.0
@export var look_offset_speed : float = 2.2
@export var focus_speed : float = 2.6
## How far the camera may lean away from the player when framing a point of
## interest (the portal during a drop). Small on purpose - it is a nudge, not
## a cutscene.
@export var focus_max : Vector2 = Vector2(96.0, 110.0)
@export var focus_ratio : float = 0.42

var trauma : float = 0.0
var target : Node2D
var _noise_x : FastNoiseLite
var _noise_y : FastNoiseLite
var _noise_roll : FastNoiseLite
var _time : float = 0.0
var _zoom_punch : float = 0.0
var _shake_dir : Vector2 = Vector2.ZERO
var _look_offset_target : float = 0.0
var _focus_point : Vector2 = Vector2.ZERO
var _focus_active : bool = false
var _focus_offset : Vector2 = Vector2.ZERO
var _focus_goal : Vector2 = Vector2.ZERO

func _ready() -> void:
	zoom = base_zoom
	position_smoothing_enabled = false
	_noise_x = FastNoiseLite.new()
	_noise_x.seed = 1337
	_noise_x.frequency = noise_frequency
	_noise_y = FastNoiseLite.new()
	_noise_y.seed = 4242
	_noise_y.frequency = noise_frequency * 1.15
	_noise_roll = FastNoiseLite.new()
	_noise_roll.seed = 90210
	_noise_roll.frequency = noise_frequency * 0.5
	_look_offset_target = look_offset_y
	FX.shake_requested.connect(_on_shake_requested)
	FX.zoom_requested.connect(_on_zoom_requested)
	if target == null and target_path != NodePath():
		target = get_node_or_null(target_path)

func set_target(node : Node2D) -> void:
	target = node
	if target != null:
		global_position = target.global_position

func _on_shake_requested(amount : float, direction : Vector2) -> void:
	add_trauma(amount, direction)

func _on_zoom_requested(amount : float) -> void:
	_zoom_punch = minf(_zoom_punch + amount, 0.4)

## Framing helper: the camera looks up while the portal is raining enemies.
func set_look_offset(y : float, instant : bool = false) -> void:
	_look_offset_target = y
	if instant:
		look_offset_y = y

## Lean a little towards a point of interest (the portal). The lean vector is
## a fraction of the distance, clamped by `focus_max`, so the camera drifts in
## the right direction instead of flying off to the target.
func set_focus_point(world_pos : Vector2) -> void:
	_focus_point = world_pos
	_focus_active = true

func clear_focus() -> void:
	_focus_active = false

func _update_focus(delta : float, player_pos : Vector2) -> void:
	if _focus_active:
		var to_point : Vector2 = _focus_point - player_pos
		_focus_goal = to_point * focus_ratio
		_focus_goal.x = clampf(_focus_goal.x, -focus_max.x, focus_max.x)
		_focus_goal.y = clampf(_focus_goal.y, -focus_max.y, focus_max.y)
	else:
		_focus_goal = Vector2.ZERO
	_focus_offset = _focus_offset.lerp(_focus_goal, clampf(focus_speed * delta, 0.0, 1.0))

func add_trauma(amount : float, direction : Vector2 = Vector2.ZERO) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)
	if direction.length() > 0.01:
		_shake_dir = direction.normalized()

func _physics_process(delta : float) -> void:
	_time += delta
	trauma = maxf(0.0, trauma - trauma_decay * delta)
	_zoom_punch = maxf(0.0, _zoom_punch - delta * 1.6)

	if target != null and is_instance_valid(target):
		var look : Vector2 = Vector2.ZERO
		if target is CharacterBody2D:
			look = (target as CharacterBody2D).velocity * 0.12
			look.x = clampf(look.x, -look_ahead, look_ahead)
			look.y = clampf(look.y, -look_ahead * 0.5, look_ahead * 0.5)
		look_offset_y = lerpf(look_offset_y, _look_offset_target, clampf(look_offset_speed * delta, 0.0, 1.0))
		_update_focus(delta, target.global_position)
		var want : Vector2 = target.global_position + look + Vector2(0, look_offset_y) + _focus_offset
		global_position = global_position.lerp(want, clampf(follow_speed * delta, 0.0, 1.0))

	var shake : float = trauma * trauma
	if shake > 0.0001:
		var nx : float = _noise_x.get_noise_2d(_time * 100.0, 0.0)
		var ny : float = _noise_y.get_noise_2d(0.0, _time * 100.0)
		offset = Vector2(nx, ny) * max_offset * shake + _shake_dir * shake * 6.0
		rotation = _noise_roll.get_noise_2d(_time * 100.0, 100.0) * max_roll * shake
	else:
		offset = offset.lerp(Vector2.ZERO, clampf(12.0 * delta, 0.0, 1.0))
		rotation = lerpf(rotation, 0.0, clampf(12.0 * delta, 0.0, 1.0))

	zoom = zoom.lerp(base_zoom * (1.0 - _zoom_punch * 0.35), clampf(10.0 * delta, 0.0, 1.0))
