class_name EnemyCatalog
extends RefCounted

## Every enemy is data. The generic Enemy scene reads a definition from here at
## runtime and configures its own sprites, hitbox, AI and drops, so adding a
## mob means adding one dictionary - no new scene, no new resource file.

const ART := "res://Aseprites/Generated/"

const TYPES := {
	"slime": {
		"name": "SLIME", "archetype": "walker",
		"hp": 22.0, "speed": 46.0, "damage": 1, "coins": 1, "weight": 3.0, "min_wave": 1,
		"sheet": "Enemies/slime_%s.png", "frame": Vector2i(16, 14), "scale": 1.0,
		"body": Vector2(12, 12), "sprite_lift": 0.0,
		"jump": 300.0, "attack_range": 18.0, "attack_cd": 1.0, "knockback_res": 0.0,
		"special": "split", "fps": 8.0,
	},
	"slime_mini": {
		"name": "SLIME SPAWN", "archetype": "walker", "hidden": true,
		"hp": 9.0, "speed": 72.0, "damage": 1, "coins": 0, "weight": 0.5, "min_wave": 1,
		"sheet": "Enemies/slime_%s.png", "frame": Vector2i(16, 14), "scale": 0.62,
		"body": Vector2(12, 12), "sprite_lift": 0.0,
		"jump": 300.0, "attack_range": 16.0, "attack_cd": 1.0, "knockback_res": 0.0,
		"fps": 9.0,
	},
	"bat": {
		"name": "BAT", "archetype": "flyer",
		"hp": 16.0, "speed": 95.0, "damage": 1, "coins": 1, "weight": 2.0, "min_wave": 2,
		"sheet": "Enemies/bat_%s.png", "frame": Vector2i(16, 12), "scale": 1.0,
		"body": Vector2(14, 10), "sprite_lift": 0.0, "flying": true,
		"attack_range": 16.0, "attack_cd": 0.9, "knockback_res": 0.1, "hover": 46.0,
		"fps": 10.0,
	},
	"skeleton": {
		"name": "SKELETON", "archetype": "thrower",
		"hp": 34.0, "speed": 52.0, "damage": 1, "coins": 2, "weight": 2.4, "min_wave": 2,
		"sheet": "Enemies/skeleton_%s.png", "frame": Vector2i(16, 24), "scale": 1.0,
		"body": Vector2(11, 22), "sprite_lift": 0.0,
		"attack_range": 220.0, "attack_cd": 2.4, "knockback_res": 0.0,
		"projectile": "bone", "projectile_speed": 330.0, "projectile_damage": 1,
		"keep_distance": 90.0, "fps": 8.0,
	},
	"spider": {
		"name": "SPIDER", "archetype": "leaper",
		"hp": 26.0, "speed": 104.0, "damage": 1, "coins": 2, "weight": 2.0, "min_wave": 3,
		"sheet": "Enemies/spider_%s.png", "frame": Vector2i(20, 14), "scale": 1.0,
		"body": Vector2(16, 11), "sprite_lift": 0.0,
		"jump": 420.0, "attack_range": 200.0, "attack_cd": 2.0, "knockback_res": 0.0,
		"projectile": "web", "projectile_speed": 260.0, "projectile_damage": 0, "fps": 12.0,
	},
	"imp": {
		"name": "IMP ARCHER", "archetype": "archer",
		"hp": 30.0, "speed": 62.0, "damage": 1, "coins": 3, "weight": 1.8, "min_wave": 3,
		"sheet": "Enemies/imp_%s.png", "frame": Vector2i(16, 22), "scale": 1.0,
		"body": Vector2(11, 20), "sprite_lift": 0.0,
		"attack_range": 300.0, "attack_cd": 1.9, "knockback_res": 0.0,
		"projectile": "arrow", "projectile_speed": 420.0, "projectile_damage": 1,
		"keep_distance": 190.0, "fps": 8.0,
	},
	"orc": {
		"name": "ORC BRUTE", "archetype": "charger",
		"hp": 70.0, "speed": 62.0, "damage": 2, "coins": 3, "weight": 1.6, "min_wave": 4,
		"sheet": "Enemies/orc_%s.png", "frame": Vector2i(18, 24), "scale": 1.0,
		"body": Vector2(14, 22), "sprite_lift": 0.0,
		"jump": 320.0, "attack_range": 24.0, "attack_cd": 1.1, "knockback_res": 0.3,
		"charge_speed": 260.0, "charge_cd": 3.4, "fps": 8.0,
	},
	"ghost": {
		"name": "GHOST", "archetype": "phaser",
		"hp": 30.0, "speed": 56.0, "damage": 1, "coins": 2, "weight": 1.5, "min_wave": 4,
		"sheet": "Enemies/ghost_%s.png", "frame": Vector2i(16, 20), "scale": 1.0,
		"body": Vector2(13, 16), "sprite_lift": 0.0, "flying": true,
		"attack_range": 16.0, "attack_cd": 1.0, "knockback_res": 0.5, "hover": -24.0,
		"fps": 7.0,
	},
	"bomber": {
		"name": "BOMBER", "archetype": "bomber",
		"hp": 26.0, "speed": 88.0, "damage": 2, "coins": 2, "weight": 1.4, "min_wave": 5,
		"sheet": "Enemies/bomber_%s.png", "frame": Vector2i(16, 22), "scale": 1.0,
		"body": Vector2(11, 20), "sprite_lift": 0.0,
		"attack_range": 26.0, "attack_cd": 0.4, "knockback_res": 0.0,
		"explode_radius": 58.0, "explode_damage": 2, "fps": 9.0,
	},
	"mage": {
		"name": "DARK MAGE", "archetype": "caster",
		"hp": 34.0, "speed": 44.0, "damage": 1, "coins": 4, "weight": 1.2, "min_wave": 6,
		"sheet": "Enemies/mage_%s.png", "frame": Vector2i(16, 24), "scale": 1.0,
		"body": Vector2(11, 22), "sprite_lift": 0.0,
		"attack_range": 320.0, "attack_cd": 2.2, "knockback_res": 0.0,
		"projectile": "fireball", "projectile_speed": 300.0, "projectile_damage": 1,
		"keep_distance": 210.0, "teleport_cd": 3.0, "fps": 8.0,
	},
	"golem": {
		"name": "STONE GOLEM", "archetype": "slammer",
		"hp": 150.0, "speed": 34.0, "damage": 2, "coins": 6, "weight": 1.0, "min_wave": 7,
		"sheet": "Enemies/golem_%s.png", "frame": Vector2i(24, 28), "scale": 1.0,
		"body": Vector2(20, 26), "sprite_lift": 0.0,
		"attack_range": 34.0, "attack_cd": 2.6, "knockback_res": 0.85,
		"slam_radius": 92.0, "slam_damage": 2, "fps": 6.0,
	},
	# ------------------------------------------------------------------ bosses
	"slime_king": {
		"name": "SLIME KING", "archetype": "boss_slime", "boss": true,
		"hp": 320.0, "speed": 42.0, "damage": 2, "coins": 25, "weight": 0.0, "min_wave": 5,
		"sheet": "Bosses/slime_king_%s.png", "frame": Vector2i(40, 32), "scale": 1.0,
		"body": Vector2(34, 26), "sprite_lift": 0.0,
		"jump": 460.0, "attack_range": 30.0, "attack_cd": 1.6, "knockback_res": 0.95,
		"slam_radius": 120.0, "slam_damage": 2, "summon_count": 2, "summon_cd": 9.0,
		"fps": 7.0, "bar_color": Color("#5fd15f"),
	},
	"necromancer": {
		"name": "NECROMANCER", "archetype": "boss_necro", "boss": true,
		"hp": 560.0, "speed": 48.0, "damage": 2, "coins": 35, "weight": 0.0, "min_wave": 5,
		"sheet": "Bosses/necromancer_%s.png", "frame": Vector2i(24, 34), "scale": 1.0,
		"body": Vector2(18, 30), "sprite_lift": 0.0,
		"attack_range": 340.0, "attack_cd": 2.0, "knockback_res": 0.9,
		"projectile": "skull", "projectile_speed": 280.0, "projectile_damage": 2,
		"keep_distance": 220.0, "teleport_cd": 4.0, "summon_count": 2, "summon_cd": 7.5,
		"fps": 8.0, "bar_color": Color("#8a6ae0"),
	},
	"demon_lord": {
		"name": "DEMON LORD", "archetype": "boss_demon", "boss": true,
		"hp": 800.0, "speed": 58.0, "damage": 3, "coins": 50, "weight": 0.0, "min_wave": 5,
		"sheet": "Bosses/demon_lord_%s.png", "frame": Vector2i(40, 40), "scale": 1.0,
		"body": Vector2(30, 36), "sprite_lift": 0.0,
		"attack_range": 46.0, "attack_cd": 1.5, "knockback_res": 0.9,
		"projectile": "fireball", "projectile_speed": 320.0, "projectile_damage": 2,
		"charge_speed": 320.0, "charge_cd": 4.0, "slam_radius": 130.0, "slam_damage": 3,
		"summon_count": 2, "summon_cd": 10.0,
		"fps": 8.0, "bar_color": Color("#e05a4a"),
	},
}

const BOSS_ORDER := ["slime_king", "necromancer", "demon_lord"]

static func get_type(id : String) -> Dictionary:
	return TYPES.get(id, TYPES["slime"])

static func spawnable_ids(wave : int) -> Array:
	var out : Array = []
	for id in TYPES:
		var t : Dictionary = TYPES[id]
		if t.get("boss", false) or t.get("hidden", false):
			continue
		if wave >= int(t.get("min_wave", 1)):
			out.append(id)
	return out

static func boss_for_wave(wave : int) -> String:
	var index : int = maxi(0, wave / 5 - 1)
	return BOSS_ORDER[index % BOSS_ORDER.size()]

## Applies wave scaling and returns a ready-to-use dictionary.
static func scaled(id : String, wave : int) -> Dictionary:
	var t : Dictionary = get_type(id).duplicate(true)
	var w : float = float(maxi(1, wave))
	var is_boss : bool = bool(t.get("boss", false))
	var hp_growth : float = 0.16 if is_boss else 0.21
	var hp_scale : float = 1.0 + hp_growth * (w - 1.0)
	t["hp"] = float(t["hp"]) * hp_scale
	t["speed"] = float(t["speed"]) * minf(1.35, 1.0 + 0.012 * (w - 1.0))
	t["damage"] = int(t["damage"]) + int(w / 7.0)
	t["coins"] = int(t["coins"]) + int(w / 4.0)
	t["id"] = id
	t["wave"] = wave
	return t

## Weighted random composition for a wave - uses a simple point budget so late
## waves naturally mix cheap swarms with expensive elites.
static func build_wave(wave : int, rng : RandomNumberGenerator) -> Array:
	var ids := spawnable_ids(wave)
	var budget : float = 4.0 + float(wave) * 1.55
	if wave % 5 == 0:
		budget *= 0.55
	var out : Array = []
	var guard : int = 0
	while budget > 0.5 and guard < 200:
		guard += 1
		var pick : String = _weighted(ids, rng, budget)
		var cost : float = float(get_type(pick)["weight"])
		budget -= cost
		out.append(pick)
	if out.is_empty():
		out.append("slime")
	return out

static func _weighted(ids : Array, rng : RandomNumberGenerator, budget : float) -> String:
	var candidates : Array = []
	for id in ids:
		if float(get_type(id)["weight"]) <= budget + 0.4:
			candidates.append(id)
	if candidates.is_empty():
		return ids[0]
	# weight = spawn "value", cheaper mobs are picked more often
	var total : float = 0.0
	for id in candidates:
		total += 1.0 / float(get_type(id)["weight"])
	var roll : float = rng.randf() * total
	for id in candidates:
		roll -= 1.0 / float(get_type(id)["weight"])
		if roll <= 0.0:
			return id
	return candidates[0]

static func anim_specs(id : String, t : Dictionary) -> Array:
	var path : String = ART + str(t["sheet"])
	var f : Vector2i = t["frame"]
	var fps : float = float(t.get("fps", 8.0))
	var specs : Array = [
		SheetAnim.sheet(path % "idle", f.x, f.y, "idle", fps * 0.7, true),
		SheetAnim.sheet(path % "run", f.x, f.y, "run", fps, true),
		SheetAnim.sheet(path % "attack", f.x, f.y, "attack", fps * 1.1, false),
		SheetAnim.sheet(path % "death", f.x, f.y, "death", fps * 0.9, false),
	]
	if ResourceLoader.exists((path % "slam")):
		specs.append(SheetAnim.sheet(path % "slam", f.x, f.y, "slam", fps, false))
	if ResourceLoader.exists((path % "summon")):
		specs.append(SheetAnim.sheet(path % "summon", f.x, f.y, "summon", fps, false))
	if ResourceLoader.exists((path % "charge")):
		specs.append(SheetAnim.sheet(path % "charge", f.x, f.y, "charge", fps, true))
	return specs
