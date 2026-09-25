extends CanvasLayer

## In-game controls card (H). Pauses the run while it is open so nobody dies
## reading the key list, and closes on H or ESC.

var _root : Control
var _panel : PanelContainer
var _open : bool = false

func _ready() -> void:
	layer = 28
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	hide()

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = PixelUI.theme()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.03, 0.08, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(centre)

	_panel = PixelUI.panel()
	_panel.custom_minimum_size = Vector2(790, 0)
	centre.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	var heading := PixelUI.label("CONTROLS", PixelUI.LARGE, PixelUI.COL_GOLD)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(heading)

	var legend := ControlsPanel.new()
	legend.set_title("")
	col.add_child(legend)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 8)
	col.add_child(footer)
	footer.add_child(PixelUI.keycap("H"))
	footer.add_child(PixelUI.label("OR", PixelUI.SMALL, PixelUI.COL_DIM))
	footer.add_child(PixelUI.keycap("ESC"))
	footer.add_child(PixelUI.label("RESUME", PixelUI.SMALL, PixelUI.COL_GOOD))

func toggle() -> void:
	if _open:
		close()
	else:
		open()

func open() -> void:
	if _open:
		return
	# the shop / death screen own the pause: never fight them for it
	if get_tree().paused:
		return
	_open = true
	show()
	get_tree().paused = true
	_root.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_root, "modulate:a", 1.0, 0.2)
	Audio.play("click", 0.05, -2.0)

func close() -> void:
	if not _open:
		return
	_open = false
	get_tree().paused = false
	hide()
	_root.modulate.a = 0.0
	Audio.play("click", 0.05, -2.0)

func is_open() -> bool:
	return _open

func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("help"):
		toggle()
		get_viewport().set_input_as_handled()
	elif _open and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
