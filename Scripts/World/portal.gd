extends Node2D

## The sky portal. Enemies literally fall out of it: the wave manager spawns
## them at this position with downward velocity, and the portal does the
## presentation (charge-up, burst, idle swirl).

const ART := "res://Aseprites/Generated/Props/"

@export var idle_bob : float = 6.0
@export var idle_speed : float = 1.4

var _t : float = 0.0
var _burst : float = 0.0
var _charge : float = 0.0
var _base_y : float = 0.0
var _portal : AnimatedSprite2D
var _glow : Sprite2D
var _light : PointLight2D
var _moving : bool = false

## Every wave the portal opens somewhere else, always on the opposite side of
## the arena centre, so mobs never pour from the same corner twice.
func relocate_to(x : float, animated : bool = true) -> void:
	if not animated:
		position.x = x
		return
	_moving = true
	Audio.play("magic", 0.1, -6.0)
	FX.play("teleport", global_position, {"scale": 1.4, "modulate": Color("#c9a2ff")})
	var out_tween := create_tween()
	out_tween.set_parallel(true)
	out_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	out_tween.tween_property(self, "position:x", x, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await out_tween.finished
	FX.play("spawn", global_position, {"scale": 1.6, "modulate": Color("#c9a2ff")})
	var in_tween := create_tween()
	in_tween.tween_property(self, "modulate:a", 1.0, 0.25)
	await in_tween.finished
	_moving = false

func _ready() -> void:
	_base_y = position.y
	_portal = AnimatedSprite2D.new()
	_portal.sprite_frames = SheetAnim.build([
		SheetAnim.sheet(ART + "portal.png", 48, 64, "idle", 10.0, true),
	])
	_portal.play("idle")
	_portal.z_index = 3
	add_child(_portal)

	_glow = Sprite2D.new()
	_glow.texture = load(ART + "portal_base.png")
	_glow.position = Vector2(0, 32)
	_glow.z_index = 2
	add_child(_glow)

	_light = PointLight2D.new()
	_light.texture = _make_light_texture()
	_light.color = Color(0.75, 0.55, 1.0)
	_light.energy = 0.9
	_light.texture_scale = 1.6
	_light.z_index = 1
	add_child(_light)

func _make_light_texture() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.9))
	grad.set_color(1, Color(1, 1, 1, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 128
	tex.height = 128
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	return tex

func _process(delta : float) -> void:
	if _moving:
		return
	_t += delta
	position.y = _base_y + sin(_t * idle_speed) * idle_bob
	_burst = maxf(0.0, _burst - delta * 2.4)
	_charge = maxf(0.0, _charge - delta)
	_portal.scale = Vector2.ONE * (1.0 + _burst * 0.18 + _charge * 0.04)
	_portal.modulate = Color(1, 1, 1).lerp(Color(1.4, 0.9, 1.6), _charge)
	_glow.scale = Vector2(1.0 + _burst * 0.1, 1.0)
	_portal.rotation = sin(_t * 0.6) * 0.03

func burst() -> void:
	_burst = minf(1.0, _burst + 0.75)
	FX.play("spawn", global_position + Vector2(0, 6), {"scale": 1.2, "modulate": Color("#c9a2ff")})

func charge() -> void:
	_charge = 1.0
