class_name PlatformManager
extends Node2D

## Owns the arena's platforms. Between waves it reshuffles the layout: existing
## slabs slide to new slots, new ones drop in from above, removed ones float
## away. Everything is procedural, so the arena never plays the same twice.

const PLATFORM_SCENE := "res://Resources/Prefabs/Platform.tscn"
const SLOTS := [-490.0, -320.0, -160.0, 0.0, 160.0, 320.0, 490.0]
const LEVELS := [45.0, -25.0, -95.0]
const MIN_COUNT := 3
const MAX_COUNT := 6
const SLIDE_TIME := 0.6
const DROP_TIME := 0.65

var rng := RandomNumberGenerator.new()
var layout_index : int = 0
var _busy : bool = false
var _platforms : Array = []

func _ready() -> void:
	rng.seed = GameState.seed_value if GameState.seed_value != 0 else 1234567
	# start from a friendly, hand-tuned layout so wave 1 always reads clearly
	_apply_layout([
		{"x": -240.0, "y": 40.0, "scale": 2.0},
		{"x": 240.0, "y": 40.0, "scale": 2.0},
		{"x": -450.0, "y": -40.0, "scale": 1.0},
		{"x": 450.0, "y": -40.0, "scale": 1.0},
		{"x": 0.0, "y": -100.0, "scale": 1.0},
	], false)

func is_busy() -> bool:
	return _busy

# ------------------------------------------------------------------- layout
func _make_layout() -> Array:
	layout_index += 1
	var local := RandomNumberGenerator.new()
	local.seed = rng.seed ^ (layout_index * 7919)
	var count : int = local.randi_range(MIN_COUNT, MAX_COUNT)
	var used : Dictionary = {}
	var out : Array = []
	var guard : int = 0
	while out.size() < count and guard < 200:
		guard += 1
		var slot_index : int = local.randi_range(0, SLOTS.size() - 1)
		var level_index : int = local.randi_range(0, LEVELS.size() - 1)
		# keep the middle slot high so the green gate area stays clear
		if slot_index == 3 and level_index == 0:
			level_index = 1
		var key := "%d_%d" % [slot_index, level_index]
		if used.has(key):
			continue
		# never stack two slabs right on top of each other
		if used.has("%d_%d" % [slot_index, level_index - 1]) or used.has("%d_%d" % [slot_index, level_index + 1]):
			continue
		used[key] = true
		out.append({
			"x": SLOTS[slot_index],
			"y": LEVELS[level_index],
			"scale": float(local.randi_range(1, 2)),
		})
	out.sort_custom(func(a, b): return a["x"] < b["x"])
	return out

## Kick off the transition, then wait for it. Safe to await.
func reshuffle() -> void:
	if _busy:
		await get_tree().create_timer(SLIDE_TIME).timeout
		return
	_busy = true
	var duration := _apply_layout(_make_layout(), true)
	await get_tree().create_timer(duration).timeout
	_busy = false

## Returns the duration of the whole transition (0.0 when not animated).
func _apply_layout(layout : Array, animated : bool) -> float:
	var pool : Array = []
	for p in _platforms:
		if is_instance_valid(p):
			pool.append(p)
	var next : Array = []
	for entry in layout:
		var node : Node2D = null
		if not pool.is_empty():
			node = pool.pop_front()
			_move_platform(node, entry, animated)
		else:
			node = _create_platform(entry)
			_drop_platform(node, entry, animated)
		next.append(node)
	for leftover in pool:
		_retire_platform(leftover, animated)
	_platforms = next
	return SLIDE_TIME if animated else 0.0

func _create_platform(entry : Dictionary) -> Node2D:
	var scene : PackedScene = load(PLATFORM_SCENE)
	var node : StaticBody2D = scene.instantiate()
	add_child(node)
	node.scale = Vector2(entry["scale"], 1.0)
	node.position = Vector2(entry["x"], entry["y"])
	return node

func _drop_platform(node : Node2D, entry : Dictionary, animated : bool) -> void:
	if not animated:
		return
	node.position = Vector2(entry["x"], entry["y"] - 420.0)
	node.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "position:y", entry["y"], DROP_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(node, "modulate:a", 1.0, 0.2)
	tween.chain().tween_callback(func(): _land_fx(Vector2(entry["x"], entry["y"])))

func _move_platform(node : Node2D, entry : Dictionary, animated : bool) -> void:
	if not animated:
		node.position = Vector2(entry["x"], entry["y"])
		node.scale = Vector2(entry["scale"], 1.0)
		return
	FX.play("dust", node.position + Vector2(0, -8), {"scale": 0.8})
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "position", Vector2(entry["x"], entry["y"]), SLIDE_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "scale:x", entry["scale"], SLIDE_TIME * 0.8)
	tween.chain().tween_callback(func(): _land_fx(Vector2(entry["x"], entry["y"])))

func _retire_platform(node : Node2D, animated : bool) -> void:
	if not animated:
		node.queue_free()
		return
	FX.play("dust_big", node.global_position, {"scale": 1.0})
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "position:y", node.position.y - 380.0, 0.5) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(node, "modulate:a", 0.0, 0.45)
	tween.chain().tween_callback(node.queue_free)

func _land_fx(pos : Vector2) -> void:
	FX.play("dust_big", pos + Vector2(0, 8), {"scale": 1.3})
	FX.shake(0.18)
	Audio.play("pot", 0.15, -8.0)
