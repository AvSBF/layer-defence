class_name Enemy
extends CharacterBody2D

## One scene drives all 13 mobs. `setup()` pulls a definition out of
## EnemyCatalog and every behaviour below is a small "archetype" branch, so
## adding an enemy means adding data + reusing (or adding) one archetype.

signal died(enemy : Enemy)

const GRAVITY := 980.0

var type_id : String = "slime"
var data : Dictionary = {}
var target : Node2D

var max_hp : float = 10.0
var hp : float = 10.0
var damage : int = 1
var speed : float = 50.0
var coin_drop : int = 1
var flying : bool = false
var boss : bool = false
var elite : bool = false
var archetype : String = "walker"
var spawn_from_sky : bool = true

var is_dead : bool = false
var attacking : bool = false

var slow_timer : float = 0.0
var slow_factor : float = 1.0
var stun_timer : float = 0.0

var _attack_cd : float = 0.0
var _special_cd : float = 0.0
var _anim : String = ""
var _facing : int = 1
var _hit_flash : float = 0.0
var _wobble : float = 0.0
var _stuck_timer : float = 0.0
var _spawn_grace : float = 0.4
var _drop_timer : float = 0.0
var _windup_timer : float = 0.0
var _dive_timer : float = 0.0
var _dive_cooldown : float = 0.0
var _dive_dir : Vector2 = Vector2.ZERO
var _telegraph : float = 0.0
var _phase : int = 1
var action_lock : float = 0.0
var _slam_pending : bool = false
var _slam_airborne : bool = false
var _body_size : Vector2 = Vector2(12, 12)

@onready var sprite : AnimatedSprite2D = $Sprite
@onready var shape : CollisionShape2D = $Shape
@onready var bar : Node2D = $HealthBar

func setup(id : String, wave : int, from_sky : bool = true, is_elite : bool = false) -> void:
	type_id = id
	data = EnemyCatalog.scaled(id, wave)
	elite = is_elite
	if elite and not bool(data.get("boss", false)):
		data["hp"] = float(data["hp"]) * 1.9
		data["coins"] = int(data["coins"]) + 2
		data["name"] = "ELITE " + str(data.get("name", ""))
	max_hp = float(data["hp"])
	hp = max_hp
	damage = int(data["damage"])
	speed = float(data["speed"])
	coin_drop = int(data["coins"])
	flying = bool(data.get("flying", false))
	boss = bool(data.get("boss", false))
	archetype = str(data.get("archetype", "walker"))
	spawn_from_sky = from_sky

func _ready() -> void:
	add_to_group("enemy")
	if data.is_empty():
		setup(type_id, 1)
	_apply_visuals()
	collision_layer = 4
	collision_mask = 4 | 1 | 2
	if flying:
		collision_mask = 0
	z_index = 11 if boss else 10
	_attack_cd = randf_range(0.35, 1.3)
	_special_cd = float(data.get("summon_cd", 3.0)) * 0.5
	if target == null:
		target = GameState.player
	if spawn_from_sky:
		velocity = Vector2(randf_range(-30, 30), randf_range(220, 340))
	_play_anim("run")
	FX.play("spawn", global_position, {"scale": 1.0 * float(data.get("scale", 1.0)), "modulate": Color("#c9a2ff")})

func _apply_visuals() -> void:
	sprite.sprite_frames = SheetAnim.build(EnemyCatalog.anim_specs(type_id, data))
	var frame : Vector2i = data.get("frame", Vector2i(16, 16))
	var scale_mult : float = float(data.get("scale", 1.0))
	sprite.scale = Vector2.ONE * scale_mult
	_body_size = Vector2(data.get("body", Vector2(12, 12))) * scale_mult
	var rect := RectangleShape2D.new()
	rect.size = _body_size
	shape.shape = rect
	# feet-on-floor alignment: sprite bottom lines up with the body bottom
	sprite.position = Vector2(0, _body_size.y * 0.5 - frame.y * scale_mult * 0.5 + float(data.get("sprite_lift", 0.0)))
	if bar != null:
		bar.configure(_body_size.x + 8.0, -_body_size.y * 0.5 - 12.0, boss or elite)

# --------------------------------------------------------------------- state
func _play_anim(anim : String) -> void:
	if _anim == anim:
		return
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(anim):
		return
	_anim = anim
	sprite.play(anim)

func _physics_process(delta : float) -> void:
	if is_dead:
		move_and_slide()
		return
	if _spawn_grace > 0.0:
		_spawn_grace -= delta
	if _hit_flash > 0.0:
		_hit_flash -= delta
	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			slow_factor = 1.0
	if stun_timer > 0.0:
		stun_timer -= delta
	_attack_cd -= delta
	_special_cd -= delta
	_wobble += delta
	_update_modulate()

	if target == null or not is_instance_valid(target):
		target = GameState.player
	if target == null:
		return

	if _drop_timer > 0.0:
		_drop_timer -= delta
		if _drop_timer <= 0.0:
			set_collision_mask_value(2, true)

	if not flying:
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		if is_on_wall() and absf(velocity.x) < 8.0:
			_stuck_timer += delta
			if _stuck_timer > 0.35:
				velocity.y = -float(data.get("jump", 300.0))
				_stuck_timer = 0.0
		else:
			_stuck_timer = 0.0

	if stun_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
		move_and_slide()
		return

	if action_lock > 0.0:
		action_lock -= delta
		if action_lock <= 0.0:
			attacking = false
		velocity.x = move_toward(velocity.x, 0.0, 1600.0 * delta)
	else:
		_ai(delta)

	_update_facing()
	move_and_slide()
	_clamp_bounds()
	# heavy landings (boss leaps, golem stomps) fire when they touch down
	if _slam_pending and not is_dead:
		if not is_on_floor():
			_slam_airborne = true
		elif _slam_airborne:
			_slam_pending = false
			_slam_airborne = false
			_slam_now()

## Enter an "attack pose" for `seconds` - the AI holds still until the lock
## expires. Timed instead of boolean so an interrupted attack can never wedge
## the enemy into a permanent animation state.
func _lock_action(seconds : float) -> void:
	action_lock = maxf(action_lock, seconds)
	attacking = true

func _update_modulate() -> void:
	var col := Color.WHITE
	if archetype == "phaser":
		col.a = 0.55 + 0.45 * sin(_wobble * 2.2)
	if slow_timer > 0.0:
		col = col.lerp(Color(0.6, 0.8, 1.35), 0.55)
	if stun_timer > 0.0:
		col = col.lerp(Color(1.35, 1.3, 0.6), 0.5)
	if _phase == 2 and boss:
		col = col.lerp(Color(1.0, 0.4, 0.4), 0.3)
	if _telegraph > 0.0:
		col = col.lerp(Color(1.9, 1.1, 0.7), _telegraph * 0.8)
	if _hit_flash > 0.0:
		col = Color(3, 3, 3, col.a)
	sprite.modulate = col

func _clamp_bounds() -> void:
	# Safety net: a mob that gets squeezed through the arena walls (or falls
	# out of the world) is recovered instead of making the wave unclearable.
	var pos := global_position
	if pos.y > 260.0 or pos.x < -680.0 or pos.x > 680.0:
		global_position = Vector2(randf_range(-460.0, 460.0), -220.0)
		velocity = Vector2.ZERO
		FX.play("spawn", global_position, {"scale": 1.0, "modulate": Color("#c9a2ff")})
	elif flying:
		global_position.x = clampf(pos.x, -620.0, 620.0)
		global_position.y = clampf(pos.y, -700.0, 120.0)

func _update_facing() -> void:
	if absf(velocity.x) > 6.0:
		_facing = 1 if velocity.x > 0.0 else -1
	sprite.flip_h = _facing < 0

func _to_target() -> Vector2:
	return target.global_position - global_position

func _ai(delta : float) -> void:
	var to_target := _to_target()
	var dist := to_target.length()
	# never camp on a platform while the player is below: hop off instead
	if not flying and is_on_floor() and to_target.y > 42.0 and _drop_timer <= 0.0 and _is_on_platform():
		_drop_timer = 0.25
		set_collision_mask_value(2, false)
	match archetype:
		"walker":
			_walk_towards(to_target)
			if _attack_cd <= 0.0 and dist < float(data.get("attack_range", 20.0)) + 8.0:
				_melee_swing()
		"flyer":
			_flyer(to_target, dist, delta)
			if _attack_cd <= 0.0 and dist < float(data.get("attack_range", 18.0)) + 6.0:
				_melee_swing()
		"thrower", "archer", "caster":
			_kiter(to_target, dist, delta, float(data.get("keep_distance", 120.0)))
			try_shoot(dist, float(data.get("attack_range", 240.0)))
			if archetype == "caster":
				_try_teleport(dist)
		"leaper":
			_leaper(to_target, dist)
		"charger":
			_charger(to_target, dist)
		"phaser":
			_phaser(to_target, delta)
		"slammer":
			_walk_towards(to_target)
			if _attack_cd <= 0.0 and dist < float(data.get("slam_radius", 90.0)) * 0.75:
				_do_slam()
		"bomber":
			_bomber(to_target, dist)
		"boss_slime":
			_boss_slime(to_target, dist)
		"boss_necro":
			_boss_necro(to_target, dist)
		"boss_demon":
			_boss_demon(to_target, dist)
		_:
			_walk_towards(to_target)

# ---------------------------------------------------------------- behaviours
func _walk_towards(to_target : Vector2) -> void:
	velocity.x = signf(to_target.x) * speed * slow_factor
	if is_on_floor():
		var jump := float(data.get("jump", 0.0))
		if jump > 0.0 and to_target.y < -30.0 and _attack_cd < float(data.get("attack_cd", 1.0)) - 0.6:
			velocity.y = -jump
			_attack_cd = float(data.get("attack_cd", 1.0))
	_play_anim("run")

func _fly_towards(to_target : Vector2, delta : float) -> void:
	var sp := speed * slow_factor
	var hover := float(data.get("hover", 40.0))
	var desired_y := target.global_position.y - hover
	var target_vel := to_target.normalized() * sp
	target_vel.y += sin(_wobble * 3.0) * sp * 0.3
	target_vel.y = clampf((desired_y - global_position.y) * 3.2, -sp * 1.4, sp * 1.4)
	velocity = velocity.lerp(target_vel, clampf(5.0 * delta, 0.0, 1.0))
	_play_anim("run")

## Bats (and other flyers) hover next to the player, telegraph a wind-up, then
## swoop through. The pattern is deliberately readable: hold -> flash -> dive.
func _flyer(to_target : Vector2, dist : float, delta : float) -> void:
	var sp := speed * slow_factor
	if _windup_timer > 0.0:
		_windup_timer -= delta
		velocity = velocity.lerp(Vector2.ZERO, clampf(8.0 * delta, 0.0, 1.0))
		_telegraph = 1.0
		_play_anim("attack")
		if _windup_timer <= 0.0:
			_telegraph = 0.0
			_dive_dir = (target.global_position + Vector2(0, -6) - global_position).normalized()
			_dive_timer = float(data.get("dive_time", 0.36))
			Audio.play("swing", 0.2, -10.0)
			FX.play("dust", global_position, {"scale": 0.7, "modulate": Color("#b79bf0")})
		return
	if _dive_timer > 0.0:
		_dive_timer -= delta
		velocity = _dive_dir * float(data.get("dive_speed", 470.0))
		_play_anim("attack")
		if _dive_timer <= 0.0:
			_dive_cooldown = float(data.get("dive_cd", 2.1))
			_play_anim("run")
		return
	if _dive_cooldown > 0.0:
		_dive_cooldown -= delta
	# hover at a readable stand-off point above and to the side of the player
	var hover := float(data.get("hover", 46.0))
	var side := -1.0 if to_target.x >= 0.0 else 1.0
	var anchor := target.global_position + Vector2(side * 42.0, -hover - 26.0)
	var to_anchor := anchor - global_position
	var target_vel := to_anchor.normalized() * sp
	target_vel.y += sin(_wobble * 3.4) * 22.0
	velocity = velocity.lerp(target_vel, clampf(4.5 * delta, 0.0, 1.0))
	_play_anim("run")
	if _dive_cooldown <= 0.0 and dist < 260.0 and to_target.y > -230.0:
		_windup_timer = float(data.get("windup", 0.34))
		_dive_cooldown = 0.0001

func _kiter(to_target : Vector2, dist : float, delta : float, keep : float) -> void:
	var sp := speed * slow_factor
	if dist > keep + 18.0:
		velocity.x = signf(to_target.x) * sp
	elif dist < keep - 34.0:
		velocity.x = -signf(to_target.x) * sp * 0.9
	else:
		velocity.x = move_toward(velocity.x, 0.0, sp * 5.0 * delta)
	_play_anim("run")

func _leaper(to_target : Vector2, dist : float) -> void:
	if is_on_floor():
		_play_anim("run")
		if dist < float(data.get("attack_range", 200.0)) and _special_cd <= 0.0:
			_special_cd = float(data.get("attack_cd", 2.0))
			velocity = (to_target + Vector2(0, -50)).normalized() * float(data.get("jump", 420.0))
			Audio.play("jump", 0.15, -8.0)
		else:
			velocity.x = signf(to_target.x) * speed * slow_factor
	else:
		_play_anim("attack")
	if dist < 80.0 and dist > 34.0 and _attack_cd <= 0.0:
		_attack_cd = 2.4
		_fire(to_target, str(data.get("projectile", "web")), float(data.get("projectile_speed", 260.0)),
			int(data.get("projectile_damage", 0)))

func _charger(to_target : Vector2, dist : float) -> void:
	if _special_cd <= 0.0 and dist > 110.0 and dist < 420.0 and absf(to_target.y) < 70.0:
		_special_cd = float(data.get("charge_cd", 3.4))
		_lock_action(0.65)
		_play_anim("charge")
		velocity.x = signf(to_target.x) * float(data.get("charge_speed", 260.0))
		Audio.play("dash", 0.2, -6.0)
		FX.play("dust_big", global_position + Vector2(0, 8), {"scale": 0.9})
		await get_tree().create_timer(0.6).timeout
		return
	_walk_towards(to_target)
	if _attack_cd <= 0.0 and dist < float(data.get("attack_range", 26.0)) + 10.0:
		_melee_swing()

func _phaser(to_target : Vector2, delta : float) -> void:
	velocity = velocity.lerp(to_target.normalized() * speed * slow_factor, clampf(3.0 * delta, 0.0, 1.0))
	_play_anim("run")
	if _attack_cd <= 0.0 and to_target.length() < float(data.get("attack_range", 16.0)) + 8.0:
		_melee_swing()

func _bomber(to_target : Vector2, dist : float) -> void:
	velocity.x = signf(to_target.x) * speed * slow_factor
	if is_on_floor() and to_target.y < -26.0:
		velocity.y = -430.0
	_play_anim("run")
	if dist < float(data.get("attack_range", 26.0)):
		_explode()

func _explode() -> void:
	if is_dead:
		return
	is_dead = true
	var radius := float(data.get("explode_radius", 58.0))
	FX.play("explosion", global_position, {"scale": radius / 22.0})
	FX.shake(0.5)
	Audio.play("explode")
	AreaDamage.explode(get_parent(), global_position, radius, float(data.get("explode_damage", 2)), false, self)
	_die_common(false)
	_die_anim()

func _melee_swing() -> void:
	_attack_cd = float(data.get("attack_cd", 1.0))
	_lock_action(0.34)
	_play_anim("attack")
	Audio.play("swing", 0.2, -8.0)
	await get_tree().create_timer(0.32).timeout
	if is_dead:
		return
	_play_anim("run")

func _do_slam() -> void:
	_attack_cd = float(data.get("attack_cd", 2.6))
	_lock_action(0.75)
	_play_anim("slam")
	FX.play("telegraph", global_position + Vector2(0, 12),
		{"scale": float(data.get("slam_radius", 92.0)) / 22.0, "fps": 8.0})
	Audio.play("magic", 0.15, -4.0)
	await get_tree().create_timer(0.6).timeout
	if is_dead:
		return
	var radius := float(data.get("slam_radius", 92.0))
	FX.play("shockwave", global_position + Vector2(0, 10), {"scale": radius / 24.0})
	FX.play("dust_big", global_position + Vector2(0, 8), {"scale": 1.4})
	FX.shake(0.45)
	Audio.play("explode", 0.1, -3.0)
	AreaDamage.explode(get_parent(), global_position, radius, float(data.get("slam_damage", damage)), false, self)

func _try_teleport(dist : float) -> void:
	if _special_cd > 0.0 or dist > float(data.get("keep_distance", 200.0)) * 0.75:
		return
	_special_cd = float(data.get("teleport_cd", 3.0))
	FX.play("teleport", global_position, {"scale": 1.0})
	Audio.play("magic", 0.2, 2.0)
	var spot := global_position - _to_target().normalized() * randf_range(150.0, 230.0) + Vector2(0, -randf_range(0.0, 40.0))
	global_position = Vector2(clampf(spot.x, -1250.0, 1250.0), clampf(spot.y, -420.0, 60.0))
	velocity = Vector2.ZERO
	FX.play("teleport", global_position, {"scale": 1.0})

# ------------------------------------------------------------------ shooting
func try_shoot(dist : float, max_range : float) -> void:
	if _attack_cd > 0.0 or dist > max_range:
		return
	var proj := str(data.get("projectile", ""))
	if proj == "":
		return
	_attack_cd = float(data.get("attack_cd", 2.0))
	_lock_action(0.34)
	_play_anim("attack")
	await get_tree().create_timer(0.3).timeout
	if is_dead or target == null or not is_instance_valid(target):
		return
	_fire(_to_target(), proj, float(data.get("projectile_speed", 300.0)), int(data.get("projectile_damage", damage)))
	_play_anim("run")

func _fire(dir : Vector2, kind : String, proj_speed : float, proj_damage : int, count : int = 1, spread : float = 0.0) -> void:
	var base_angle := dir.angle()
	for i in count:
		var offset := 0.0
		if count > 1:
			offset = (float(i) - (count - 1) * 0.5) * maxf(spread, 0.25)
		var p := SpawnHelper.spawn_projectile(get_parent(), kind, global_position + Vector2(0, -6),
			Vector2.from_angle(base_angle + offset), proj_speed, float(proj_damage), false)
		if p != null:
			p.lifetime = 3.4
			p.slow_amount = 0.45 if kind == "web" else 0.0
	Audio.play("shoot" if kind == "arrow" else "magic", 0.15, -6.0)

# --------------------------------------------------------------------- bosses
func _boss_phase_check() -> void:
	if _phase == 1 and hp / maxf(1.0, max_hp) < 0.5:
		_phase = 2
		speed *= 1.2
		_attack_cd = 0.0
		FX.flash(Color("#ff5577"), 0.3)
		FX.shake(0.6)
		Audio.play("boss", 0.0, 2.0)
		GameState.notice.emit("ENRAGED!", Color("#ff7a6f"))

func _boss_slime(to_target : Vector2, dist : float) -> void:
	_boss_phase_check()
	if is_on_floor():
		velocity.x = signf(to_target.x) * speed * slow_factor
		_play_anim("run")
		if _attack_cd <= 0.0 and dist < 300.0:
			_attack_cd = float(data.get("attack_cd", 1.6))
			_lock_action(0.5)
			_slam_pending = true
			_play_anim("attack")
			velocity.y = -float(data.get("jump", 460.0))
			velocity.x = signf(to_target.x) * 190.0
			Audio.play("jump", 0.1, -4.0)
	else:
		_play_anim("attack")
	if _special_cd <= 0.0:
		_special_cd = float(data.get("summon_cd", 7.0))
		_summon("slime", int(data.get("summon_count", 3)))

func _boss_necro(to_target : Vector2, dist : float) -> void:
	_boss_phase_check()
	var sp := speed * slow_factor
	velocity.x = -signf(to_target.x) * sp if dist < 170.0 else 0.0
	_play_anim("run")
	if _attack_cd <= 0.0:
		_attack_cd = float(data.get("attack_cd", 2.0))
		_lock_action(0.34)
		_play_anim("attack")
		await get_tree().create_timer(0.32).timeout
		if is_dead:
			return
		_fire(_to_target(), str(data.get("projectile", "skull")), 290.0, int(data.get("projectile_damage", 2)),
			3 if _phase == 1 else 5, 0.28)
	if _special_cd <= 0.0:
		_special_cd = float(data.get("summon_cd", 6.0))
		_play_anim("summon")
		_summon("skeleton", int(data.get("summon_count", 2)))
	_try_teleport(dist)

func _boss_demon(to_target : Vector2, dist : float) -> void:
	_boss_phase_check()
	if dist < 70.0 and _attack_cd <= 0.0:
		_attack_cd = 2.4
		_do_slam()
		return
	if _attack_cd <= 0.0 and dist < 440.0 and dist > 100.0:
		_attack_cd = 2.2
		_lock_action(0.34)
		_play_anim("attack")
		await get_tree().create_timer(0.32).timeout
		if is_dead:
			return
		_fire(_to_target(), "fireball", 340.0, int(data.get("projectile_damage", 2)), 3 if _phase == 1 else 5, 0.22)
		return
	if _special_cd <= 0.0 and dist > 130.0:
		_special_cd = float(data.get("charge_cd", 4.0))
		_lock_action(0.65)
		_play_anim("attack")
		Audio.play("dash", 0.15, -4.0)
		velocity.x = signf(to_target.x) * float(data.get("charge_speed", 320.0))
		await get_tree().create_timer(0.6).timeout
		return
	if _phase == 2 and _special_cd < -3.0:
		_special_cd = float(data.get("summon_cd", 8.0))
		_summon("imp", 2)
	velocity.x = signf(to_target.x) * speed * slow_factor
	_play_anim("run")

func _slam_now() -> void:
	var radius := float(data.get("slam_radius", 110.0))
	FX.play("shockwave", global_position + Vector2(0, 8), {"scale": radius / 24.0})
	FX.play("dust_big", global_position + Vector2(0, 6), {"scale": 1.6})
	FX.shake(0.55)
	Audio.play("explode", 0.05, 0.0)
	AreaDamage.explode(get_parent(), global_position, radius, float(data.get("slam_damage", 2)), false, self)
	velocity.x *= 0.3

func _is_on_platform() -> bool:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider = col.get_collider()
		if collider != null and collider.is_in_group("platforms"):
			return true
	return false

func _ground_distance() -> float:
	var space := get_world_2d().direct_space_state
	var params := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 90))
	params.collision_mask = 1
	params.exclude = [get_rid()]
	var hit := space.intersect_ray(params)
	if hit.is_empty():
		return 999.0
	return global_position.distance_to(hit.position)

func _summon(id : String, count : int) -> void:
	var alive := get_tree().get_nodes_in_group("enemy").size()
	if alive >= 14:
		return
	Audio.play("magic", 0.1, -2.0)
	for i in count:
		var spot := global_position + Vector2(randf_range(-150, 150), -230.0)
		SpawnHelper.spawn_enemy(get_tree().current_scene, id, spot, maxi(1, GameState.wave - 1), true)
		FX.play("spawn", spot, {"scale": 1.1, "modulate": Color("#c9a2ff")})

# --------------------------------------------------------------------- combat
func take_damage(amount : float, knockback : Vector2 = Vector2.ZERO, is_crit : bool = false) -> void:
	if is_dead:
		return
	hp -= amount
	GameState.damage_dealt += int(round(amount))
	_hit_flash = 0.1
	var res := float(data.get("knockback_res", 0.0))
	FX.damage_number(global_position + Vector2(0, -_body_size.y * 0.5 - 4.0), amount, {"crit": is_crit})
	FX.play("hit", global_position + Vector2(0, -4), {"scale": 1.0, "z": 20})
	Audio.play_pitched("hit_crit" if is_crit else "hit", 1.0 if is_crit else randf_range(0.9, 1.15), -3.0)
	if knockback.length() > 0.0:
		velocity += knockback * (1.0 - res)
		if flying:
			velocity *= 0.8
	if bar != null:
		bar.set_ratio(hp / maxf(1.0, max_hp))
	if boss:
		GameState.boss_health_changed.emit(maxf(0.0, hp), max_hp)
	if hp <= 0.0:
		_die()

func apply_slow(factor : float, duration : float) -> void:
	slow_factor = minf(slow_factor, 1.0 - factor)
	slow_timer = maxf(slow_timer, duration)
	FX.play("freeze_spark", global_position, {"scale": 0.9})

func apply_stun(duration : float) -> void:
	stun_timer = maxf(stun_timer, duration)

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	FX.play("death", global_position + Vector2(0, -6), {"scale": float(data.get("scale", 1.0))})
	Audio.play("enemy_die", 0.15, -3.0)
	if not boss:
		FX.shake(0.12)
	_die_common(true)
	if boss:
		_boss_death_sequence()
	_die_anim()

func _die_common(drop_loot : bool) -> void:
	GameState.register_kill(coin_drop)
	remove_from_group("enemy")
	collision_layer = 0
	collision_mask = 1
	attacking = true
	if bar != null:
		bar.visible = false
	if str(data.get("special", "")) == "split" and not elite and not boss:
		for i in 2:
			var spot := global_position + Vector2(randf_range(-14, 14), -6.0)
			SpawnHelper.spawn_enemy(get_parent(), "slime_mini", spot, GameState.wave, false)
	if drop_loot:
		_spawn_drops()

func _boss_death_sequence() -> void:
	FX.shake(1.2)
	FX.flash(Color.WHITE, 0.45)
	FX.play("explosion", global_position, {"scale": 2.4})
	Audio.play("boss", 0.0, 0.0)
	GameState.boss_defeated.emit()
	GameState.notice.emit(str(data.get("name", "BOSS")) + " SLAIN", Color("#ffd34d"))

func _spawn_drops() -> void:
	var holder : Node = get_parent()
	var n : int = clampi(coin_drop, 1, 10)
	var per : int = maxi(1, int(round(float(coin_drop) / float(n))))
	Pickup.scatter(holder, global_position, "coin", n, per)
	var heart_chance := 0.05 + GameState.get_stat("luck") * 0.1
	if not boss and randf() < heart_chance:
		Pickup.spawn(holder, global_position, "heart", 1)

func _die_anim() -> void:
	_play_anim("death")
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("death"):
		var frames := sprite.sprite_frames.get_frame_count("death")
		var fps := maxf(1.0, sprite.sprite_frames.get_animation_speed("death"))
		await get_tree().create_timer(maxf(0.22, frames / fps)).timeout
	died.emit(self)
	queue_free()
