extends CanvasLayer

## The "WAVE N" title card that plays when the player steps into the gate.
## Slide + overshoot + hold + fade, with the wave info stacked underneath.

var _root : Control
var _banner : TextureRect
var _title : Label
var _sub : Label
var _info : Label
var _queue : Array = []
var _playing : bool = false

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = PixelUI.theme()
	_root.modulate.a = 0.0
	add_child(_root)

	var centre := VBoxContainer.new()
	centre.set_anchors_preset(Control.PRESET_CENTER)
	centre.position = Vector2(-320, -90)
	centre.custom_minimum_size = Vector2(640, 0)
	centre.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(centre)

	var banner_holder := CenterContainer.new()
	centre.add_child(banner_holder)
	_banner = TextureRect.new()
	_banner.texture = load("res://Aseprites/Generated/UI/banner.png")
	_banner.custom_minimum_size = Vector2(640, 150)
	_banner.stretch_mode = TextureRect.STRETCH_SCALE
	_banner.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_banner.pivot_offset = Vector2(320, 75)
	banner_holder.add_child(_banner)

	var overlay := VBoxContainer.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay.add_theme_constant_override("separation", 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_holder.add_child(overlay)

	_title = PixelUI.label("WAVE 1", PixelUI.GIANT, Color.WHITE)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_child(_title)
	_sub = PixelUI.label("", PixelUI.SMALL, PixelUI.COL_GOLD)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_child(_sub)

	_info = PixelUI.label("", PixelUI.SMALL, PixelUI.COL_DIM)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centre.add_child(_info)

func show_wave(info : Dictionary) -> void:
	_queue.append(info)
	if not _playing:
		_play_next()

func _play_next() -> void:
	if _queue.is_empty():
		_playing = false
		return
	_playing = true
	var info : Dictionary = _queue.pop_front()
	var wave : int = int(info.get("wave", 1))
	var is_boss : bool = bool(info.get("is_boss", false))
	_title.text = "WAVE %d" % wave
	_title.add_theme_color_override("font_color", PixelUI.COL_BAD if is_boss else Color.WHITE)
	if is_boss:
		_sub.text = "BOSS: " + str(info.get("boss_name", "???"))
	else:
		_sub.text = "%d HOSTILES INCOMING" % int(info.get("total", 0))
	var mods : Array = info.get("modifiers", [])
	_info.text = "  ".join(mods) if not mods.is_empty() else ""

	_root.modulate.a = 0.0
	_root.scale = Vector2(0.9, 0.9)
	_root.pivot_offset = get_viewport().get_visible_rect().size * 0.5
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(_root, "modulate:a", 1.0, 0.22)
	t.tween_property(_root, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.chain().tween_interval(1.5 if not is_boss else 2.1)
	t.chain().tween_property(_root, "modulate:a", 0.0, 0.35)
	t.chain().tween_callback(_play_next)
