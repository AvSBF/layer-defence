extends Node

## Global "juice" bus: camera shake, hit-stop, screen flash, one-shot FX
## sprites and floating damage numbers. Everything funnels through here so that
## gameplay code stays clean: `FX.shake(0.4)` reads better than wiring signals.

signal shake_requested(trauma : float, direction : Vector2)
signal flash_requested(color : Color, strength : float)
signal hitstop_started(duration : float)
signal zoom_requested(amount : float)

const FX_PATH := "res://Scripts/World/fx_sprite.gd"

var _flash_layer : CanvasLayer
var _flash_rect : ColorRect
var _hitstop_owner : int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_flash_overlay()

func _build_flash_overlay() -> void:
	_flash_layer = CanvasLayer.new()
	_flash_layer.layer = 90
	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_layer.add_child(_flash_rect)
	add_child(_flash_layer)

# ------------------------------------------------------------------- requests
func shake(amount : float, direction : Vector2 = Vector2.ZERO) -> void:
	shake_requested.emit(amount, direction)

## Punch the camera zoom - reads as a shockwave through the lens.
func zoom_punch(amount : float) -> void:
	zoom_requested.emit(amount)

func flash(color : Color = Color(1, 1, 1), strength : float = 0.35) -> void:
	flash_requested.emit(color, strength)
	if _flash_rect == null:
		return
	_flash_rect.color = Color(color.r, color.g, color.b, strength)
	var tween := create_tween()
	tween.tween_property(_flash_rect, "color:a", 0.0, 0.28)

## Freeze frame - extremely cheap way to make hits feel heavy.
func hitstop(duration : float) -> void:
	if duration <= 0.0:
		return
	hitstop_started.emit(duration)
	var token := _hitstop_owner
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	if token == _hitstop_owner:
		Engine.time_scale = 1.0

func slowmo(duration : float, scale : float = 0.35) -> void:
	Engine.time_scale = scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

# ---------------------------------------------------------------- fx spawning
func play(anim_name : String, global_pos : Vector2, opts : Dictionary = {}) -> Node2D:
	var scene : PackedScene = load("res://Resources/Prefabs/FX/FxSprite.tscn")
	if scene == null:
		return null
	var node : Node2D = scene.instantiate()
	node.anim_name = anim_name
	node.flip_h = bool(opts.get("flip", false))
	node.scale = Vector2.ONE * float(opts.get("scale", 1.0))
	node.modulate = opts.get("modulate", Color.WHITE)
	node.z_index = int(opts.get("z", 5))
	node.fps = float(opts.get("fps", 18.0))
	node.autofree = bool(opts.get("autofree", true))
	_parent_for_fx().add_child(node)
	node.global_position = global_pos
	if opts.has("rotation"):
		node.rotation = float(opts["rotation"])
	return node

func damage_number(pos : Vector2, amount : float, opts : Dictionary = {}) -> void:
	var scene : PackedScene = load("res://Resources/Prefabs/FX/DamageNumber.tscn")
	if scene == null:
		return
	var node : Node2D = scene.instantiate()
	node.amount = amount
	node.crit = bool(opts.get("crit", false))
	node.heal = bool(opts.get("heal", false))
	_parent_for_fx().add_child(node)
	node.global_position = pos

func _parent_for_fx() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return self
	var holder : Node = scene.get_node_or_null("FXHolder")
	return holder if holder != null else scene
