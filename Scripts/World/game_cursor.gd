extends Node2D

## Mouse cursor: the OS cursor is replaced by a pixel crosshair, and a ring
## node follows the pointer with a bit of lag + a click pop.

const CURSOR_TEX := "res://Aseprites/Generated/UI/cursor.png"
const RING_TEX := "res://Aseprites/Generated/UI/crosshair.png"

var _ring : Sprite2D
var _pop : float = 0.0
var _smooth : Vector2 = Vector2.ZERO
var _first : bool = true

func _ready() -> void:
	z_index = 100
	var tex : Texture2D = load(RING_TEX)
	if ResourceLoader.exists(CURSOR_TEX):
		var cursor_tex : Texture2D = load(CURSOR_TEX)
		Input.set_custom_mouse_cursor(cursor_tex, Input.CURSOR_ARROW, Vector2(7, 7))
		Input.set_custom_mouse_cursor(cursor_tex, Input.CURSOR_CROSS, Vector2(7, 7))
	_ring = Sprite2D.new()
	_ring.texture = tex
	_ring.modulate = Color(1, 1, 1, 0.55)
	add_child(_ring)

func _process(delta : float) -> void:
	var mouse := get_global_mouse_position()
	if _first:
		_smooth = mouse
		_first = false
	_smooth = _smooth.lerp(mouse, clampf(28.0 * delta, 0.0, 1.0))
	global_position = _smooth
	_pop = maxf(0.0, _pop - delta * 5.0)
	_ring.scale = Vector2.ONE * (1.0 + _pop * 0.8)
	_ring.rotation += delta * 1.5
	_ring.modulate.a = 0.45 + _pop * 0.5

func pop(amount : float = 1.0) -> void:
	_pop = minf(1.5, _pop + amount)
