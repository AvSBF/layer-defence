extends CanvasLayer

## Title card + control cheat sheet. Clicking (or pressing attack) starts the
## run and hands control to the wave manager.

signal start_requested

var _root : Control
var _title : Label
var _pulse : float = 0.0

func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	get_tree().paused = true

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = PixelUI.theme()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.07, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var centre := VBoxContainer.new()
	centre.set_anchors_preset(Control.PRESET_CENTER)
	centre.position = Vector2(-330, -190)
	centre.custom_minimum_size = Vector2(660, 0)
	centre.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_theme_constant_override("separation", 8)
	_root.add_child(centre)

	_title = PixelUI.label("LAYER DEFENCE", PixelUI.GIANT, PixelUI.COL_GOLD)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centre.add_child(_title)

	var sub := PixelUI.label("A PIXEL ROGUELIKE ARENA", PixelUI.SMALL, PixelUI.COL_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centre.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	centre.add_child(spacer)

	var controls := [
		"A / D  MOVE        SPACE  JUMP (TAP = HIGHER)",
		"SHIFT  DASH        S  DROP THROUGH PLATFORM",
		"MOUSE  AIM         LMB  ATTACK (HOLD TO SWING)",
		"",
		"SURVIVE THE WAVES. SMASH POTS. BUY UPGRADES.",
		"STEP INTO THE GREEN GATE TO SUMMON THE NEXT WAVE.",
		"EVERY 5TH WAVE IS A BOSS.",
	]
	for line in controls:
		var l := PixelUI.label(line, PixelUI.SMALL, PixelUI.COL_TEXT if line != "" else PixelUI.COL_DIM)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		centre.add_child(l)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	centre.add_child(spacer2)

	var start := PixelUI.label("CLICK TO DESCEND", PixelUI.LARGE, PixelUI.COL_GOOD)
	start.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start.name = "StartLabel"
	centre.add_child(start)

	var t := create_tween().set_loops()
	t.tween_property(start, "modulate:a", 0.35, 0.6)
	t.tween_property(start, "modulate:a", 1.0, 0.6)

func _input(event : InputEvent) -> void:
	if not visible:
		return
	var pressed := event.is_action_pressed("attack") or event.is_action_pressed("ui_accept")
	if pressed:
		_start()

func _start() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	Audio.play("level_up", 0.05, 0.0)
	FX.flash(Color("#7fe6cf"), 0.3)
	start_requested.emit()
