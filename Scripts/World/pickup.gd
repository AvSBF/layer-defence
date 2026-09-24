class_name Pickup
extends Area2D

## Coins, hearts and gems. They pop out of pots / dead enemies, arc under
## gravity, then get magnetised towards the player.

const KIND_INFO := {
	"coin": ["Pickups/coin.png", 12, 12, 10.0],
	"heart": ["Pickups/heart.png", 11, 10, 4.0],
	"gem": ["Pickups/gem.png", 12, 12, 8.0],
}

@export var kind : String = "coin"
@export var amount : int = 1
@export var velocity : Vector2 = Vector2.ZERO

var _grounded : bool = false
var _age : float = 0.0
var _magnetised : bool = false
var _bob : float = 0.0
var _base_y : float = 0.0

@onready var anim : AnimatedSprite2D = $anim
@onready var shape : CollisionShape2D = $shape

func _ready() -> void:
	var info : Array = KIND_INFO.get(kind, KIND_INFO["coin"])
	anim.sprite_frames = SheetAnim.build([
		SheetAnim.sheet("res://Aseprites/Generated/" + str(info[0]), int(info[1]), int(info[2]), "play", float(info[3]), true),
	])
	anim.play("play")
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	z_index = 8
	_base_y = global_position.y
	_bob = randf() * TAU

func _physics_process(delta : float) -> void:
	_age += delta
	var player := GameState.player as Node2D
	var ground : float = _ground_level()
	if not _grounded:
		velocity.y += 900.0 * delta
		global_position += velocity * delta
		if global_position.y >= ground:
			global_position.y = ground
			_grounded = true
			_base_y = global_position.y
			if velocity.length() > 90.0:
				FX.play("dust", global_position + Vector2(0, 6), {"scale": 0.6})
			velocity = Vector2.ZERO
		return

	if player != null and is_instance_valid(player):
		var to_player : Vector2 = player.global_position - global_position
		var radius : float = GameState.get_stat("magnet_radius")
		if kind == "heart":
			radius = maxf(radius, 30.0)
		if _magnetised or to_player.length() < radius:
			_magnetised = true
			var dir := to_player.normalized()
			var speed : float = clampf(340.0 - to_player.length() * 0.6, 120.0, 420.0)
			global_position += dir * speed * delta
			if to_player.length() < 16.0:
				_collect()
				return
		else:
			_bob += delta * 3.0
			global_position.y = _base_y - 8.0 - sin(_bob) * 2.0

	if _age > 30.0:
		queue_free()

func _ground_level() -> float:
	var space := get_world_2d().direct_space_state
	var params := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 400))
	params.collision_mask = 1
	params.exclude = [get_rid()]
	var hit := space.intersect_ray(params)
	if hit.is_empty():
		return global_position.y + 400.0
	return hit.position.y - 5.0

func _collect() -> void:
	match kind:
		"coin":
			GameState.add_coins(amount)
			Audio.play("coin", 0.1, 0.0)
			FX.play("coin_pop", global_position, {"scale": 0.8})
		"gem":
			GameState.add_coins(amount)
			Audio.play("coin", 0.05, 2.0)
			FX.play("coin_pop", global_position, {"scale": 1.3, "modulate": Color("#7fe6cf")})
		"heart":
			GameState.heal(1 + int(GameState.get_stat("pickup_heal")))
			Audio.play("heal")
			FX.play("heal", global_position, {"scale": 1.1})
	queue_free()

static func spawn(parent : Node, pos : Vector2, kind : String, amount : int = 1) -> Pickup:
	var scene : PackedScene = load("res://Resources/Prefabs/Pickup.tscn")
	var p : Pickup = scene.instantiate()
	p.kind = kind
	p.amount = amount
	parent.add_child(p)
	p.global_position = pos
	return p

static func scatter(parent : Node, pos : Vector2, kind : String, count : int, amount : int = 1) -> void:
	for i in count:
		var p := spawn(parent, pos + Vector2(randf_range(-6, 6), randf_range(-8, 0)), kind, amount)
		p.velocity = Vector2(randf_range(-90, 90), randf_range(-260, -160))
