extends CanvasLayer

## End of run screen: dying shows a stat sheet (the roguelike report card) and
## a retry button.

var _root : Control
var _stats_box : VBoxContainer
var _title : Label

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	hide()
	GameState.run_ended.connect(_on_run_ended)

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = PixelUI.theme()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.02, 0.04, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(centre)

	var panel := PixelUI.panel()
	panel.custom_minimum_size = Vector2(560, 420)
	centre.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	_title = PixelUI.label("YOU DIED", PixelUI.GIANT, PixelUI.COL_BAD)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)

	var sub := PixelUI.label("THE LAYER HAS FALLEN", PixelUI.SMALL, PixelUI.COL_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)

	_stats_box = VBoxContainer.new()
	_stats_box.add_theme_constant_override("separation", 4)
	col.add_child(_stats_box)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 20)
	col.add_child(buttons)
	var retry := PixelUI.button("RETRY", PixelUI.NORMAL)
	retry.pressed.connect(_retry)
	buttons.add_child(retry)
	var quit := PixelUI.button("QUIT", PixelUI.NORMAL)
	quit.pressed.connect(func(): get_tree().quit())
	buttons.add_child(quit)

func _on_run_ended(victory : bool) -> void:
	if GameState.autotest:
		print("[autotest] run ended at wave %d (hp=%d) - paused" % [GameState.wave, GameState.health])
	get_tree().paused = true
	_title.text = "VICTORY" if victory else "YOU DIED"
	_title.add_theme_color_override("font_color", PixelUI.COL_GOOD if victory else PixelUI.COL_BAD)
	for c in _stats_box.get_children():
		c.queue_free()
	_add_stat("WAVE REACHED", str(GameState.wave))
	_add_stat("ENEMIES SLAIN", str(GameState.kills))
	if GameState.wave_manager != null:
		_add_stat("ENEMIES SPAWNED", str(GameState.enemies_spawned))
	_add_stat("COINS EARNED", str(GameState.coins_earned))
	_add_stat("DAMAGE DEALT", str(GameState.damage_dealt))
	_add_stat("DAMAGE TAKEN", str(GameState.damage_taken))
	_add_stat("TIME", "%d:%02d" % [int(GameState.time_alive) / 60, int(GameState.time_alive) % 60])
	var upgrades := []
	for id in GameState.upgrade_levels:
		upgrades.append("%s %d" % [UpgradeCatalog.get_upgrade(id).get("name", id), GameState.upgrade_level(id)])
	_add_stat("UPGRADES", ", ".join(upgrades) if not upgrades.is_empty() else "NONE")
	show()
	_root.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_root, "modulate:a", 1.0, 0.4)
	_title.scale = Vector2(1.6, 1.6)
	_title.pivot_offset = _title.size * 0.5
	var t2 := create_tween()
	t2.tween_property(_title, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _add_stat(label_text : String, value : String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var l := PixelUI.label(label_text, PixelUI.SMALL, PixelUI.COL_DIM)
	l.custom_minimum_size = Vector2(240, 0)
	row.add_child(l)
	var v := PixelUI.label(value, PixelUI.SMALL, PixelUI.COL_TEXT)
	v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.custom_minimum_size = Vector2(260, 0)
	row.add_child(v)
	_stats_box.add_child(row)

func _retry() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()
