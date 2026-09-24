extends Node2D

## Minimal custom-drawn health bar for elites and bosses. Drawing it by hand
## keeps it crisp at any pixel scale (no StyleBox rounding artefacts).

var _ratio : float = 1.0
var _width : float = 24.0
var _show : bool = false

func configure(width : float, y_offset : float, visible_bar : bool) -> void:
	_width = maxf(16.0, width)
	position = Vector2(0, y_offset)
	visible = visible_bar
	_show = visible_bar
	z_index = 30
	queue_redraw()

func set_ratio(r : float) -> void:
	_ratio = clampf(r, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	if not _show:
		return
	var w := _width
	var h := 4.0
	var x := -w * 0.5
	var bg := Color("#1a1424")
	var border := Color("#0d0a14")
	draw_rect(Rect2(x - 1.0, -1.0, w + 2.0, h + 2.0), border)
	draw_rect(Rect2(x, 0.0, w, h), bg)
	var fill := Color("#e05a4a")
	if _ratio > 0.6:
		fill = Color("#5fd15f")
	elif _ratio > 0.3:
		fill = Color("#ffd34d")
	draw_rect(Rect2(x, 0.0, w * _ratio, h), fill)
	draw_rect(Rect2(x, 0.0, w * _ratio, 1.0), fill.lightened(0.35))
