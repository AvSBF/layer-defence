class_name Pot
extends CharacterBody2D

## Sky breakables: pots (small loot) and chests (jackpot). They rain from the
## portal, land on the floor *or* on a platform, and spill loot when hit.
##
## The origin of the node is the object's "feet": the collision circle and the
## sprite are both pushed up, otherwise the sprite visually sinks into the tile
## it rests on.

const POT_SHEET := "res://Aseprites/Generated/Props/pot.png"
const POT_BREAK := "res://Aseprites/Generated/Props/pot_break.png"
const CHEST_SHEET := "res://Aseprites/Generated/Props/chest.png"
const CHEST_BREAK := "res://Aseprites/Generated/Props/chest_break.png"

@export var kind : String = "pot"
@export var loot_holder_path : NodePath

var hp : int = 1
var _landed : bool = false
var _spin : float = 0.0
var _age : float = 0.0
var _sprite : AnimatedSprite2D
var _shape : CollisionShape2D

func _ready() -> void:
	add_to_group("breakable")
	collision_layer = 64
	collision_mask = 1 | 2          # world + platforms: pots can land on slabs
	var is_chest := kind == "chest"
	hp = 2 if is_chest else 1

	_sprite = AnimatedSprite2D.new()
	var sheet : String = CHEST_SHEET if is_chest else POT_SHEET
	var fw : int = 18 if is_chest else 16
	var fh : int = 17 if is_chest else 16
	_sprite.sprite_frames = SheetAnim.build([
		SheetAnim.sheet(sheet, fw, fh, "idle", 3.5 if is_chest else 5.0, true),
	])
	_sprite.play("idle")
	_sprite.position = Vector2(0, -fh * 0.5 + 1.0)
	add_child(_sprite)

	_shape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = fw * 0.5 - 1.0
	_shape.shape = circle
	_shape.position = Vector2(0, -circle.radius + 1.0)
	add_child(_shape)
	z_index = 6

func _physics_process(delta : float) -> void:
	_age += delta
	if not is_on_floor():
		velocity.y += 900.0 * delta
		_spin += delta * 4.0
		if _sprite:
			_sprite.rotation = _spin
	else:
		if not _landed:
			_landed = true
			if _sprite:
				_sprite.rotation = 0.0
			velocity = Vector2.ZERO
			FX.play("dust", global_position + Vector2(0, 2), {"scale": 0.9})
			Audio.play("pot", 0.2, -6.0)
		velocity.x = 0.0
	move_and_slide()
	if _age > 40.0:
		queue_free()

## Called by player attacks / projectiles. Chests need two hits.
func break_open() -> void:
	hp -= 1
	Audio.play("pot", 0.1, -1.0)
	FX.play("dust_big", global_position + Vector2(0, 2), {"scale": 0.7})
	FX.shake(0.1)
	if hp > 0:
		# cracked but still standing
		if _sprite != null:
			_sprite.modulate = Color(1.25, 0.95, 0.8)
		FX.play("hit", global_position, {"scale": 1.2})
		return
	var is_chest := kind == "chest"
	FX.play("explosion", global_position + Vector2(0, -4),
		{"scale": 0.5, "modulate": Color(1.0, 0.85, 0.6) if not is_chest else Color(1.0, 0.95, 0.7)})
	if is_chest:
		FX.shake(0.3)
		Audio.play("coin", 0.05, 2.0)
	_spill_loot()
	queue_free()

func _spill_loot() -> void:
	var holder : Node = get_parent()
	var node := get_node_or_null(loot_holder_path)
	if node != null:
		holder = node
	if kind == "chest":
		Pickup.scatter(holder, global_position, "coin", 6, 3)
		Pickup.spawn(holder, global_position + Vector2(0, -6), "gem", randi_range(8, 14))
		if randf() < 0.7:
			Pickup.spawn(holder, global_position + Vector2(-6, -4), "heart", 1)
		return
	var roll : float = randf()
	if roll < 0.58:
		Pickup.scatter(holder, global_position, "coin", randi_range(3, 6), 1)
	elif roll < 0.82:
		Pickup.scatter(holder, global_position, "coin", 2, 1)
		Pickup.scatter(holder, global_position, "heart", 1, 1)
	else:
		Pickup.spawn(holder, global_position, "gem", randi_range(8, 14))
		Pickup.scatter(holder, global_position, "coin", 2, 1)

static func spawn(parent : Node, pos : Vector2, drop_speed : float = 0.0, kind : String = "pot") -> Pot:
	var scene : PackedScene = load("res://Resources/Prefabs/Pot.tscn")
	var p : Pot = scene.instantiate()
	p.kind = kind
	parent.add_child(p)
	p.global_position = pos
	p.velocity.y = drop_speed
	return p
