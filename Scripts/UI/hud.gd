extends CanvasLayer

## Animated HUD: hearts that pop, a rolling coin counter, wave readout, boss
## bar and a floating notice feed. Everything is drawn from generated pixel art.

const HEART_PATH := "res://Aseprites/Generated/UI/heart.png"
const HEART_SIZE := 12

var _hearts_box : HBoxContainer
var _heart_nodes : Array[TextureRect] = []
var _coin_label : Label
var _coin_icon : TextureRect
var _wave_label : Label
var _enemy_label : Label
var _weapon_icon : TextureRect
var _weapon_label : Label
var _dash_box : HBoxContainer
var _boss_root : VBoxContainer
var _boss_name : Label
var _boss_bar : ProgressBar
var _boss_fill : StyleBoxFlat
var _notices : VBoxContainer
var _gate_hint : HBoxContainer
var _heart_frames : Array[AtlasTexture] = []
var _shown_coins : int = 0
var _coin_tween : Tween
var _hearts_used : int = 0
var _boss_max : float = 1.0

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.upgrades_changed.connect(_refresh)
	GameState.notice.connect(_on_notice)
	GameState.boss_spawned.connect(_on_boss_spawned)
	GameState.boss_health_changed.connect(_on_boss_health)
	GameState.boss_defeated.connect(_on_boss_defeated)
	GameState.wave_changed.connect(_on_wave_changed)
	_shown_coins = GameState.coins
	_refresh()

# -------------------------------------------------------------------- layout
func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = PixelUI.theme()
	add_child(root)

	# --- top left: hearts / weapon / dash
	var left := VBoxContainer.new()
	left.position = Vector2(16, 12)
	left.add_theme_constant_override("separation", 6)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(left)

	var hearts_panel := PixelUI.panel()
	left.add_child(hearts_panel)
	_hearts_box = HBoxContainer.new()
	_hearts_box.add_theme_constant_override("separation", 2)
	hearts_panel.add_child(_hearts_box)

	var frames_tex : Texture2D = load(HEART_PATH)
	for i in 3:
		var at := AtlasTexture.new()
		at.atlas = frames_tex
		at.region = Rect2(i * HEART_SIZE, 0, HEART_SIZE, 10)
		_heart_frames.append(at)

	var weapon_panel := PixelUI.panel()
	left.add_child(weapon_panel)
	var weapon_row := HBoxContainer.new()
	weapon_row.add_theme_constant_override("separation", 8)
	weapon_panel.add_child(weapon_row)
	_weapon_icon = TextureRect.new()
	_weapon_icon.custom_minimum_size = Vector2(28, 28)
	_weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_weapon_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	weapon_row.add_child(_weapon_icon)
	_weapon_label = PixelUI.label("SWORD", PixelUI.SMALL)
	weapon_row.add_child(_weapon_label)
	_dash_box = HBoxContainer.new()
	_dash_box.add_theme_constant_override("separation", 3)
	weapon_row.add_child(_dash_box)

	# --- top right: coins
	var right := HBoxContainer.new()
	right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right.position = Vector2(-140, 12)
	right.add_theme_constant_override("separation", 6)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(right)
	var coin_panel := PixelUI.panel()
	right.add_child(coin_panel)
	var coin_row := HBoxContainer.new()
	coin_row.add_theme_constant_override("separation", 6)
	coin_panel.add_child(coin_row)
	_coin_icon = PixelUI.icon_rect("coin", 28)
	coin_row.add_child(_coin_icon)
	_coin_label = PixelUI.label("0", PixelUI.LARGE, PixelUI.COL_GOLD)
	_coin_label.custom_minimum_size = Vector2(70, 0)
	coin_row.add_child(_coin_label)

	# --- top centre: wave
	var centre := VBoxContainer.new()
	centre.set_anchors_preset(Control.PRESET_CENTER_TOP)
	centre.position = Vector2(-120, 10)
	centre.custom_minimum_size = Vector2(240, 0)
	centre.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(centre)
	_wave_label = PixelUI.label("WAVE 1", PixelUI.LARGE, Color.WHITE)
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centre.add_child(_wave_label)
	_enemy_label = PixelUI.label("", PixelUI.SMALL, PixelUI.COL_DIM)
	_enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centre.add_child(_enemy_label)

	_boss_root = VBoxContainer.new()
	_boss_root.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_root.position = Vector2(-230, 62)
	_boss_root.custom_minimum_size = Vector2(460, 0)
	_boss_root.visible = false
	_boss_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_boss_root)
	_boss_name = PixelUI.label("BOSS", PixelUI.SMALL, PixelUI.COL_BAD)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_root.add_child(_boss_name)
	_boss_bar = ProgressBar.new()
	_boss_bar.custom_minimum_size = Vector2(440, 14)
	_boss_bar.show_percentage = false
	_boss_bar.min_value = 0.0
	_boss_bar.max_value = 1.0
	_boss_bar.value = 1.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("#1a1424")
	bg.border_color = Color("#3d3358")
	bg.set_border_width_all(2)
	_boss_fill = StyleBoxFlat.new()
	_boss_fill.bg_color = Color("#e05a4a")
	_boss_fill.border_color = Color("#ffd34d")
	_boss_fill.set_border_width_all(1)
	_boss_bar.add_theme_stylebox_override("background", bg)
	_boss_bar.add_theme_stylebox_override("fill", _boss_fill)
	_boss_root.add_child(_boss_bar)

	# --- notices
	_notices = VBoxContainer.new()
	_notices.set_anchors_preset(Control.PRESET_CENTER)
	_notices.position = Vector2(-160, 80)
	_notices.custom_minimum_size = Vector2(320, 0)
	_notices.alignment = BoxContainer.ALIGNMENT_CENTER
	_notices.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_notices)

	# --- gate hint
	_gate_hint = HBoxContainer.new()
	_gate_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_gate_hint.position = Vector2(-150, -80)
	_gate_hint.add_theme_constant_override("separation", 8)
	_gate_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gate_hint.visible = false
	root.add_child(_gate_hint)
	var arrow := TextureRect.new()
	arrow.texture = load("res://Aseprites/Generated/UI/arrow.png")
	arrow.custom_minimum_size = Vector2(24, 24)
	arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	arrow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_gate_hint.add_child(arrow)
	var hint := PixelUI.label("STEP INTO THE GREEN GATE", PixelUI.SMALL, PixelUI.COL_GOOD)
	_gate_hint.add_child(hint)
	var tween := create_tween().set_loops()
	tween.tween_property(arrow, "position:y", 4.0, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(arrow, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_SINE)

# -------------------------------------------------------------------- update
func _refresh() -> void:
	_sync_hearts()
	var w := WeaponCatalog.get_weapon(_weapon_id())
	_weapon_icon.texture = load(WeaponCatalog.icon_path(_weapon_id()))
	_weapon_label.text = str(w.get("name", ""))
	_sync_dash()

func _weapon_id() -> String:
	if GameState.player != null and is_instance_valid(GameState.player):
		return str(GameState.player.weapon_id)
	return "sword"

func _sync_hearts() -> void:
	var total := GameState.max_hp()
	if _heart_nodes.size() != total:
		for n in _heart_nodes:
			n.queue_free()
		_heart_nodes.clear()
		for i in total:
			var t := TextureRect.new()
			t.custom_minimum_size = Vector2(HEART_SIZE, 10)
			t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			t.texture = _heart_frames[2]
			_hearts_box.add_child(t)
			_heart_nodes.append(t)
	for i in _heart_nodes.size():
		var filled := i < GameState.health
		_heart_nodes[i].texture = _heart_frames[0] if filled else _heart_frames[2]
		if not filled:
			_heart_nodes[i].modulate = Color(1, 1, 1, 0.35)
		else:
			_heart_nodes[i].modulate = Color.WHITE

func _sync_dash() -> void:
	for c in _dash_box.get_children():
		c.queue_free()
	var charges : int = 1 + int(GameState.get_stat("dash_charges"))
	for i in charges:
		var t := TextureRect.new()
		t.texture = PixelUI.icon("dash")
		t.custom_minimum_size = Vector2(16, 16)
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		t.modulate = Color(1, 1, 1, 1.0) if i < charges else Color(1, 1, 1, 0.2)
		_dash_box.add_child(t)

func _on_coins_changed(total : int, delta : int) -> void:
	if _coin_tween != null and _coin_tween.is_valid():
		_coin_tween.kill()
	var from := _shown_coins
	_coin_tween = create_tween()
	_coin_tween.tween_method(func(v : float): _coin_label.text = str(int(round(v))), float(from), float(total), 0.35)
	_shown_coins = total
	var pop := create_tween()
	_coin_icon.scale = Vector2(1.25, 1.25)
	_coin_icon.pivot_offset = Vector2(14, 14)
	pop.tween_property(_coin_icon, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	if delta > 0:
		var c := PixelUI.label("+%d" % delta, PixelUI.SMALL, PixelUI.COL_GOLD)
		c.position = _coin_label.global_position + Vector2(-40, -6)
		_notices.get_parent().add_child(c)
		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(c, "position:y", c.position.y - 26.0, 0.6)
		t.tween_property(c, "modulate:a", 0.0, 0.6).set_delay(0.2)
		t.chain().tween_callback(c.queue_free)

func _on_notice(text : String, color : Color) -> void:
	var l := PixelUI.label(text, PixelUI.SMALL, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(320, 0)
	_notices.add_child(l)
	l.modulate.a = 0.0
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(l, "modulate:a", 1.0, 0.15)
	t.tween_property(l, "position:y", -18.0, 1.4).set_trans(Tween.TRANS_QUAD)
	t.chain().tween_property(l, "modulate:a", 0.0, 0.3)
	t.chain().tween_callback(l.queue_free)
	if _notices.get_child_count() > 5:
		_notices.get_child(0).queue_free()

func _on_wave_changed(wave : int, is_boss : bool) -> void:
	_wave_label.text = "WAVE %d" % wave
	if is_boss:
		_wave_label.add_theme_color_override("font_color", PixelUI.COL_BAD)
	else:
		_wave_label.add_theme_color_override("font_color", Color.WHITE)
	_wave_label.scale = Vector2(1.4, 1.4)
	_wave_label.pivot_offset = _wave_label.size * 0.5
	var t := create_tween()
	t.tween_property(_wave_label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	_gate_hint.visible = false

func _on_boss_spawned(boss_name : String, max_hp : float) -> void:
	_boss_max = max_hp
	_boss_name.text = boss_name
	_boss_bar.value = 1.0
	_boss_root.visible = true
	_boss_root.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_boss_root, "modulate:a", 1.0, 0.4)

func _on_boss_health(hp : float, max_hp : float) -> void:
	_boss_max = max_hp
	var ratio := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
	var t := create_tween()
	t.tween_property(_boss_bar, "value", ratio, 0.15)
	_boss_fill.bg_color = Color("#e05a4a") if ratio > 0.35 else Color("#ff2f3f")

func _on_boss_defeated() -> void:
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(_boss_root, "modulate:a", 0.0, 0.6).set_delay(0.8)

func set_enemies(alive : int, total : int) -> void:
	if total <= 0:
		_enemy_label.text = ""
		return
	_enemy_label.text = "ENEMIES LEFT  %d" % alive

func show_gate_hint(show_it : bool) -> void:
	_gate_hint.visible = show_it
