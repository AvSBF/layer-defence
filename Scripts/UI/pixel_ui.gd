class_name PixelUI
extends RefCounted

## Shared look & feel for every Control in the game. Built in code so the whole
## UI can be re-skinned by regenerating a handful of PNGs.

const ART := "res://Aseprites/Generated/"
const FONT_PATH := ART + "UI/font/pixel_font.fnt"

const SMALL := 14
const NORMAL := 14
const LARGE := 28
const HUGE := 42
const GIANT := 56

const COL_TEXT := Color("#e8e2f2")
const COL_DIM := Color("#9a90b8")
const COL_GOLD := Color("#ffd34d")
const COL_GOOD := Color("#7fe6cf")
const COL_BAD := Color("#ff7a6f")
const COL_MAGIC := Color("#e0a2ff")
const COL_BG := Color("#1b1528")
const COL_OUTLINE := Color("#120e1c")

static var _font : Font
static var _theme : Theme
static var _icon_cache : Dictionary = {}

static func font() -> Font:
	if _font == null:
		if ResourceLoader.exists(FONT_PATH):
			_font = load(FONT_PATH)
	return _font

static func icon(name : String) -> Texture2D:
	if _icon_cache.has(name):
		return _icon_cache[name]
	var path := ART + "UI/icons/" + name + ".png"
	if not ResourceLoader.exists(path):
		path = ART + "UI/icons/damage.png"
	var tex : Texture2D = load(path)
	_icon_cache[name] = tex
	return tex

static func texture(rel : String) -> Texture2D:
	if _icon_cache.has(rel):
		return _icon_cache[rel]
	var path := ART + rel
	if not ResourceLoader.exists(path):
		return null
	var tex : Texture2D = load(path)
	_icon_cache[rel] = tex
	return tex

static func nine_patch(rel : String, margin : int = 6) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	var tex := texture(rel)
	sb.texture = tex
	sb.texture_margin_left = margin
	sb.texture_margin_right = margin
	sb.texture_margin_top = margin
	sb.texture_margin_bottom = margin
	return sb

static func theme() -> Theme:
	if _theme != null:
		return _theme
	_theme = Theme.new()
	var f := font()
	if f != null:
		_theme.default_font = f
	_theme.default_font_size = NORMAL
	_theme.set_color("font_color", "Label", COL_TEXT)
	_theme.set_color("font_color", "Button", COL_TEXT)
	_theme.set_color("font_hover_color", "Button", COL_GOLD)
	_theme.set_color("font_pressed_color", "Button", Color.WHITE)
	_theme.set_color("font_disabled_color", "Button", Color("#6b6480"))
	_theme.set_color("font_outline_color", "Label", COL_OUTLINE)
	_theme.set_constant("outline_size", "Label", 0)
	return _theme

# ------------------------------------------------------------------ factories
static func label(text : String, size : int = NORMAL, color : Color = COL_TEXT) -> Label:
	var l := Label.new()
	l.text = text
	var f := font()
	if f != null:
		l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", COL_OUTLINE)
	l.add_theme_constant_override("outline_size", 4)
	return l

static func button(text : String, size : int = NORMAL) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	var f := font()
	if f != null:
		b.add_theme_font_override("font", f)
	b.add_theme_font_size_override("font_size", size)
	var tex := texture("UI/button.png")
	if tex != null:
		var frames := [0, 1, 2]
		var names := ["normal", "hover", "pressed"]
		for i in 3:
			var sb := StyleBoxTexture.new()
			sb.texture = tex
			sb.region_rect = Rect2(i * 32, 0, 32, 16)
			sb.texture_margin_left = 5
			sb.texture_margin_right = 5
			sb.texture_margin_top = 5
			sb.texture_margin_bottom = 5
			sb.content_margin_left = 14
			sb.content_margin_right = 14
			sb.content_margin_top = 8
			sb.content_margin_bottom = 8
			b.add_theme_stylebox_override(names[i], sb)
	b.pressed.connect(func(): Audio.play("click", 0.05, -3.0))
	return b

static func panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", nine_patch("UI/panel.png", 6))
	return p

static func card() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", nine_patch("UI/card.png", 6))
	return p

static func icon_rect(name : String, size : int = 32) -> TextureRect:
	var t := TextureRect.new()
	t.texture = icon(name)
	t.custom_minimum_size = Vector2(size, size)
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return t

static func texture_rect(rel : String, size : Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = texture(rel)
	t.custom_minimum_size = size
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return t
