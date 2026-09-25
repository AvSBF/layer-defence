class_name ControlsPanel
extends VBoxContainer

## Reusable controls legend: one row per action, each key rendered as a keycap
## with its meaning next to it. Used by the title screen and by the in-game
## overlay (H), so there is a single source of truth for the bindings.

const ROWS := [
	{"keys": ["A", "D"], "text": "MOVE LEFT / RIGHT", "color": "text"},
	{"keys": ["SPACE"], "text": "JUMP  (TAP FOR A HIGHER HOP)", "color": "text"},
	{"keys": ["SHIFT", "J"], "text": "DASH  (INVULNERABLE, 2 CHARGES MAX)", "color": "teal"},
	{"keys": ["S"], "text": "DROP THROUGH A PLATFORM", "color": "text"},
	{"keys": ["MOUSE"], "text": "AIM  (THE KNIGHT ALWAYS FACES THE CURSOR)", "color": "text"},
	{"keys": ["LMB"], "text": "ATTACK  (HOLD TO KEEP SWINGING)", "color": "gold"},
	{"keys": ["TAB", "E"], "text": "SHOP BETWEEN WAVES", "color": "text"},
	{"keys": ["ESC"], "text": "CLOSE THE SHOP", "color": "dim"},
	{"keys": ["H"], "text": "SHOW / HIDE THIS PANEL", "color": "magic"},
]

var title_text : String = "CONTROLS"
var _title_label : Label
var _rows_box : VBoxContainer

func _ready() -> void:
	add_theme_constant_override("separation", 4)
	if title_text != "":
		_title_label = PixelUI.label(title_text, PixelUI.NORMAL, PixelUI.COL_DIM)
		_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(_title_label)
	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 3)
	add_child(_rows_box)
	build()

## Can be called before the node is added to the tree.
func set_title(text : String) -> void:
	title_text = text
	if _title_label != null:
		_title_label.text = text

func build() -> void:
	for c in _rows_box.get_children():
		c.queue_free()
	for i in ROWS.size():
		_rows_box.add_child(_make_row(ROWS[i], i))

func _make_row(row : Dictionary, index : int) -> Control:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 4)
	# key caps on the left, fixed column width so all descriptions line up
	var keys_box := HBoxContainer.new()
	keys_box.add_theme_constant_override("separation", 4)
	keys_box.custom_minimum_size = Vector2(212, 0)
	for key in row["keys"]:
		keys_box.add_child(PixelUI.keycap(str(key)))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	keys_box.add_child(spacer)
	line.add_child(keys_box)
	var color := PixelUI.COL_TEXT
	match str(row.get("color", "text")):
		"gold": color = PixelUI.COL_GOLD
		"teal": color = PixelUI.COL_GOOD
		"magic": color = PixelUI.COL_MAGIC
		"dim": color = PixelUI.COL_DIM
	var desc := PixelUI.label(str(row["text"]), PixelUI.SMALL, color)
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc.custom_minimum_size = Vector2(0, 24)
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(desc)
	# stagger the rows in, like the shop cards
	line.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(line, "modulate:a", 1.0, 0.18).set_delay(index * 0.05)
	return line

## Rows of "keys -> action" without the title, for embedding into other panels.
static func row_count() -> int:
	return ROWS.size()
