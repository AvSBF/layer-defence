class_name SpawnHelper
extends RefCounted

## Static factory helpers. Anything that needs to create an enemy, pickup or
## projectile from code (boss summons, portals, pots) goes through here so the
## scene paths live in exactly one place.

const ENEMY_SCENE := "res://Resources/Prefabs/Enemy/Enemy.tscn"
const PROJECTILE_SCENE := "res://Resources/Prefabs/Projectile.tscn"

static func spawn_enemy(parent : Node, id : String, pos : Vector2, wave : int,
		from_sky : bool = true, elite : bool = false, fall_speed : float = -1.0) -> Enemy:
	if parent == null or not parent.is_inside_tree():
		return null
	var scene : PackedScene = load(ENEMY_SCENE)
	var e : Enemy = scene.instantiate()
	e.type_id = id
	e.setup(id, wave, from_sky, elite)
	e.target = GameState.player
	e.add_to_group("wave_enemy" if from_sky else "summoned_enemy")
	parent.add_child(e)
	e.global_position = pos
	if from_sky:
		e.velocity = Vector2(randf_range(-30, 30), fall_speed if fall_speed > 0.0 else randf_range(220, 340))
	return e

static func spawn_projectile(parent : Node, kind : String, pos : Vector2, dir : Vector2,
		speed : float, damage : float, friendly : bool, pierce : int = 0) -> Projectile:
	if parent == null or not parent.is_inside_tree():
		return null
	var scene : PackedScene = load(PROJECTILE_SCENE)
	var p : Projectile = scene.instantiate()
	p.kind = kind
	p.friendly = friendly
	p.damage = damage
	p.speed = speed
	p.direction = dir.normalized()
	p.pierce = pierce
	parent.add_child(p)
	p.global_position = pos
	return p
