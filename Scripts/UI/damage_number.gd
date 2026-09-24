extends Node2D

## Floating combat text. Rises, overshoots, fades - the classic feedback loop.

@export var amount : float = 0.0
@export var crit : bool = false
@export var heal : bool = false

var _label : Label
var _velocity := Vector2.ZERO
var _life := 0.0

const LIFE := 0.85

func _ready() -> void:
	_label = Label.new()
	_label.text = ("+" if heal else "") + str(int(round(amount)))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_override("font", PixelUI.font())
	var size := 10 if not crit else 14
	_label.add_theme_font_size_override("font_size", size)
	var color := Color("#ffffff")
	if heal:
		color = Color("#7fe6cf")
	elif crit:
		color = Color("#ffd34d")
	_label.add_theme_color_override("font_color", color)
	_label.add_theme_color_override("font_outline_color", Color("#1a1424"))
	_label.add_theme_constant_override("outline_size", 4)
	_label.position = Vector2(-60, -14)
	_label.size = Vector2(120, 18)
	_label.pivot_offset = Vector2(60, 9)
	add_child(_label)
	z_index = 60
	_velocity = Vector2(randf_range(-16.0, 16.0), -62.0 if not crit else -78.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE * (1.35 if crit else 1.1), 0.08)
	tween.chain().tween_property(self, "scale", Vector2.ONE, 0.12)

func _process(delta : float) -> void:
	_life += delta
	global_position += _velocity * delta
	_velocity.y += 120.0 * delta
	_velocity.x = lerpf(_velocity.x, 0.0, 3.0 * delta)
	modulate.a = clampf(1.0 - (_life - LIFE * 0.45) / (LIFE * 0.55), 0.0, 1.0)
	if _life >= LIFE:
		queue_free()
