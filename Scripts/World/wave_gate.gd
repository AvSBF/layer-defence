extends Area2D

## The glowing green zone between waves. Stand in it and the next wave is
## summoned. It only exists while the arena is quiet.

signal entered

const ART := "res://Aseprites/Generated/Props/wave_gate.png"
const CHARGE_TIME := 0.9

var active : bool = false
var _charge : float = 0.0
var _t : float = 0.0
var _sprite : AnimatedSprite2D

func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SheetAnim.build([
		SheetAnim.sheet(ART, 64, 56, "idle", 9.0, true),
	])
	_sprite.play("idle")
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(52, 60)
	shape.shape = rect
	add_child(shape)
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	z_index = 4
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	deactivate()

func activate() -> void:
	active = true
	visible = true
	_charge = 0.0
	set_process(true)
	FX.play("spawn", global_position + Vector2(0, -6), {"scale": 1.6, "modulate": Color("#7fe6cf")})
	Audio.play("gate", 0.05, -6.0)

func deactivate() -> void:
	active = false
	visible = false
	_charge = 0.0

func _process(delta : float) -> void:
	if not active:
		return
	_t += delta
	scale = Vector2(1.0 + sin(_t * 3.0) * 0.03, 1.0 + sin(_t * 3.0 + 1.0) * 0.05)
	if _charge > 0.0:
		_sprite.modulate = Color(1, 1, 1).lerp(Color(1.6, 1.6, 1.2), _charge)
	else:
		_sprite.modulate = Color(1, 1, 1)
	# the charge is driven by "is the player standing inside", which also
	# covers the case of the gate appearing right under the player
	if _player_inside():
		if _charge <= 0.0:
			Audio.play("gate", 0.1, -8.0)
		_charge = minf(1.0, _charge + delta / CHARGE_TIME)
		if fmod(_t, 0.12) < delta:
			FX.play("dust", global_position + Vector2(randf_range(-20, 20), 20), {"scale": 0.7,
				"modulate": Color("#7fe6cf")})
	else:
		_charge = 0.0
	if GameState.autotest and fmod(_t, 1.0) < delta:
		print("[gate] active=%s inside=%s charge=%.2f pos=%s" % [str(active), str(_player_inside()), _charge, str(global_position)])
	if _charge >= 1.0:
		_charge = 0.0
		active = false
		Audio.play("level_up", 0.05, -3.0)
		FX.play("spawn", global_position, {"scale": 2.0, "modulate": Color("#7fe6cf")})
		entered.emit()

func _player_inside() -> bool:
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false

func _on_body_entered(_body : Node) -> void:
	pass

func _on_body_exited(_body : Node) -> void:
	pass
