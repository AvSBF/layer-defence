class_name Projectile
extends Area2D

## Generic projectile. Faction decides who it can hurt, `kind` picks the sheet,
## and the rest is behaviour flags (homing / wobble / spin / pierce).

const ART := "res://Aseprites/Generated/Projectiles/"

const INFO := {
	"arrow": ["arrow.png", 16, 6, 8.0, "straight"],
	"fireball": ["fireball.png", 12, 12, 14.0, "straight"],
	"orb": ["orb.png", 12, 12, 12.0, "homing"],
	"bone": ["bone.png", 12, 8, 12.0, "spin"],
	"skull": ["skull.png", 12, 12, 10.0, "wobble"],
	"web": ["web.png", 24, 12, 6.0, "straight"],
	"bomb": ["bomb.png", 14, 14, 14.0, "spin"],
	"shard": ["shard.png", 10, 10, 10.0, "spin"],
	"ice_shard": ["ice_shard.png", 12, 12, 12.0, "spin"],
}

@export var kind : String = "arrow"
@export var friendly : bool = false          ## friendly = hurts enemies
@export var damage : float = 10.0
@export var speed : float = 500.0
@export var direction : Vector2 = Vector2.RIGHT
@export var pierce : int = 0
@export var lifetime : float = 2.2
@export var knockback : float = 90.0
@export var homing_strength : float = 0.0
@export var slow_amount : float = 0.0
@export var crit : bool = false
@export var gravity_pull : float = 0.0

var _hits : Array = []
var _age : float = 0.0
var _spin : float = 0.0
var _base_speed : float = 500.0
var _target_provider : Callable = Callable()

@onready var anim : AnimatedSprite2D = $anim
@onready var shape : CollisionShape2D = $shape

func setup_art() -> void:
	var info : Array = INFO.get(kind, INFO["arrow"])
	anim.sprite_frames = SheetAnim.build([
		SheetAnim.sheet(ART + str(info[0]), int(info[1]), int(info[2]), "fly", float(info[3]), true),
	])
	anim.play("fly")
	var radius : float = maxf(int(info[1]), int(info[2])) * 0.35
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle

func _ready() -> void:
	setup_art()
	_base_speed = speed
	rotation = direction.angle()
	if friendly:
		collision_layer = 16
		collision_mask = 4 | 64
	else:
		collision_layer = 32
		collision_mask = 2
	monitoring = true
	z_index = 12

func _physics_process(delta : float) -> void:
	_age += delta
	if _age >= lifetime:
		_despawn(false)
		return
	var info : Array = INFO.get(kind, INFO["arrow"])
	var motion : String = str(info[4])
	if motion == "homing" and homing_strength > 0.0:
		var target := _find_target()
		if target != null:
			var want : Vector2 = (target.global_position - global_position).normalized()
			direction = direction.lerp(want, clampf(homing_strength * delta, 0.0, 1.0)).normalized()
			rotation = direction.angle()
	elif motion == "wobble":
		var side := direction.orthogonal()
		global_position += side * sin(_age * 12.0) * 18.0 * delta
	elif motion == "spin":
		_spin += delta * 12.0
		anim.rotation = _spin
	if gravity_pull != 0.0:
		direction.y = clampf(direction.y + gravity_pull * delta, -1.0, 1.0)
		direction = direction.normalized()
		rotation = direction.angle()
	global_position += direction * speed * delta
	_check_hits()

func _find_target() -> Node2D:
	if _target_provider.is_valid():
		var t = _target_provider.call()
		return t if is_instance_valid(t) else null
	var best : Node2D = null
	var best_dist : float = 260.0 * 260.0
	for e in get_tree().get_nodes_in_group("enemy"):
		var d : float = e.global_position.distance_squared_to(global_position)
		if d < best_dist:
			best_dist = d
			best = e
	return best

func _check_hits() -> void:
	var bodies := get_overlapping_bodies()
	for body in bodies:
		if _hits.has(body):
			continue
		if friendly:
			if body.is_in_group("enemy"):
				_hits.append(body)
				_impact(body, body.global_position)
			elif body.is_in_group("breakable"):
				_hits.append(body)
				if body.has_method("break_open"):
					body.break_open()
				else:
					body.queue_free()
		else:
			if body.is_in_group("player"):
				_hits.append(body)
				if body.has_method("take_damage"):
					body.take_damage(damage, (body.global_position - global_position).normalized() * 120.0)
				else:
					body.call("apply_hit", damage)
				_despawn(true)
				return
		if _hits.size() > pierce:
			_impact_finish()
			return

func _impact(body : Node, pos : Vector2) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, direction.normalized() * knockback, crit)
	else:
		body.call("take_damage", damage)
	if body.has_method("apply_slow") and slow_amount > 0.0:
		body.apply_slow(slow_amount, 2.2)
	FX.play("hit", pos, {"scale": 0.8})
	Audio.play_pitched("hit", randf_range(0.95, 1.15), -4.0)

func _impact_finish() -> void:
	_despawn(true)

func _despawn(with_fx : bool) -> void:
	if with_fx:
		FX.play("hit", global_position, {"scale": 0.7, "modulate": Color(1, 1, 1, 0.8)})
	queue_free()
