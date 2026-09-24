class_name Pot
extends CharacterBody2D

## Sky-pots: they rain from the portal, crack on the ground and spill loot when
## hit. They are the roguelike "loot crate" of the arena.

@export var loot_holder_path : NodePath

var _landed : bool = false
var _hit_count : int = 0
var _spin : float = 0.0
var _age : float = 0.0
var _sprite : Sprite2D

func _ready() -> void:
	add_to_group("breakable")
	collision_layer = 64
	collision_mask = 1
	for c in get_children():
		if c is CollisionShape2D:
			var circle := CircleShape2D.new()
			circle.radius = 8.0
			c.shape = circle
		if c is Sprite2D:
			_sprite = c
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
			FX.play("dust", global_position + Vector2(0, 6), {"scale": 0.9})
			Audio.play("pot", 0.2, -6.0)
		velocity.x = 0.0
	move_and_slide()
	if _age > 40.0:
		queue_free()

## Called by player attacks / projectiles. Two hits or one heavy hit breaks it.
func break_open() -> void:
	_hit_count += 1
	Audio.play("pot", 0.1, -2.0)
	FX.play("explosion", global_position + Vector2(0, -2),
		{"scale": 0.45, "modulate": Color(1.0, 0.85, 0.6)})
	FX.play("dust_big", global_position + Vector2(0, 4), {"scale": 0.8})
	FX.shake(0.12)
	_spill_loot()
	queue_free()

func _spill_loot() -> void:
	var holder : Node = get_parent()
	var node := get_node_or_null(loot_holder_path)
	if node != null:
		holder = node
	var roll : float = randf()
	if roll < 0.58:
		var n : int = randi_range(3, 6)
		Pickup.scatter(holder, global_position, "coin", n, 1)
	elif roll < 0.82:
		Pickup.scatter(holder, global_position, "coin", 2, 1)
		Pickup.scatter(holder, global_position, "heart", 1, 1)
	else:
		Pickup.spawn(holder, global_position, "gem", randi_range(8, 14))
		Pickup.scatter(holder, global_position, "coin", 2, 1)

static func spawn(parent : Node, pos : Vector2, drop_speed : float = 0.0) -> Pot:
	var scene : PackedScene = load("res://Resources/Prefabs/Pot.tscn")
	var p : Pot = scene.instantiate()
	parent.add_child(p)
	p.global_position = pos
	p.velocity.y = drop_speed
	return p
