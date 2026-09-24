class_name Player
extends CharacterBody2D

## Player: movement with game-feel niceties (coyote time, jump buffer,
## variable jump, drop-through, dash with i-frames) plus the whole weapon
## pipeline. Stats are read from GameState every time they are needed, so
## upgrades apply instantly without any stat re-calculation step.

const ART := "res://Aseprites/Generated/Characters/"
const PLAYER_LAYER := 2
const ENEMY_LAYER := 4
const PROJECTILE_LAYER := 32
const BREAKABLE_LAYER := 64

@export var move_speed : float = 215.0
@export var jump_velocity : float = -520.0
@export var jump_cut : float = 0.42
@export var gravity : float = 1250.0
@export var max_fall_speed : float = 780.0
@export var dash_speed : float = 640.0
@export var dash_duration : float = 0.16
@export var dash_cooldown : float = 1.15
@export var weapon_id : String = "sword"

var max_jumps : int = 1
var jumps_left : int = 1
var coyote_timer : float = 0.0
var jump_buffer : float = 0.0
var dash_timer : float = 0.0
var dash_cd : float = 0.0
var dash_dir : Vector2 = Vector2.RIGHT
var invuln : float = 0.0
var attack_cd : float = 0.0
var swing_active : bool = false
var is_dead : bool = false
var facing : int = 1
var slow_timer : float = 0.0
var slow_factor : float = 1.0
var ward_ready : bool = true
var lifesteal_pool : float = 0.0
var _drop_timer : float = 0.0
var _afterimage_timer : float = 0.0
var _touch_cooldown : Dictionary = {}
var _dash_charges : int = 0
var _anim : String = ""
var weapon : Dictionary = {}
var aim_override : Vector2 = Vector2.ZERO
var _swing_token : int = 0

@onready var sprite : AnimatedSprite2D = $Sprite
@onready var weapon_sprite : AnimatedSprite2D = $Weapon/WeaponSprite
@onready var weapon_root : Node2D = $Weapon
@onready var hurt_box : Area2D = $HurtBox
@onready var shape : CollisionShape2D = $Shape

func _ready() -> void:
	add_to_group("player")
	GameState.player = self
	shape.shape = RectangleShape2D.new()
	(shape.shape as RectangleShape2D).size = Vector2(11, 30)
	collision_layer = PLAYER_LAYER
	collision_mask = 3
	_build_sprite_frames()
	equip(weapon_id)
	GameState.upgrades_changed.connect(_on_stats_changed)
	GameState.wave_changed.connect(_on_wave_changed)
	_on_stats_changed()

func _on_wave_changed(_wave : int, _is_boss : bool) -> void:
	ward_ready = true

func _reset_weapon_pose() -> void:
	if not is_dead:
		weapon_sprite.frame = 0

func _build_sprite_frames() -> void:
	sprite.sprite_frames = SheetAnim.build([
		SheetAnim.sheet(ART + "player_idle.png", 16, 24, "idle", 6.0, true),
		SheetAnim.sheet(ART + "player_run.png", 16, 24, "run", 13.0, true),
		SheetAnim.sheet(ART + "player_jump.png", 16, 24, "jump", 8.0, false),
		SheetAnim.sheet(ART + "player_fall.png", 16, 24, "fall", 8.0, false),
		SheetAnim.sheet(ART + "player_hurt.png", 16, 24, "hurt", 8.0, false),
		SheetAnim.sheet(ART + "player_dash.png", 16, 24, "dash", 14.0, true),
		SheetAnim.sheet(ART + "player_death.png", 16, 24, "death", 8.0, false),
	])
	weapon_sprite.centered = false
	sprite.position = Vector2(0, 3)

func equip(id : String) -> void:
	weapon_id = id if WeaponCatalog.WEAPONS.has(id) else "sword"
	weapon = WeaponCatalog.get_weapon(weapon_id)
	weapon_sprite.sprite_frames = SheetAnim.build(WeaponCatalog.anim_specs(weapon_id))
	weapon_sprite.play("swing")
	weapon_sprite.stop()
	if not weapon_sprite.animation_finished.is_connected(_reset_weapon_pose):
		weapon_sprite.animation_finished.connect(_reset_weapon_pose)
	GameState.notice.emit("EQUIPPED " + str(weapon["name"]), Color("#ffd34d"))
	if GameState.autotest:
		print("[autotest] equipped ", weapon_id)

func _on_stats_changed() -> void:
	max_jumps = 1 + int(GameState.get_stat("extra_jumps"))

func _physics_process(delta : float) -> void:
	if is_dead:
		velocity.y += gravity * delta
		move_and_slide()
		return
	if invuln > 0.0:
		invuln -= delta
		sprite.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.03)
	else:
		sprite.modulate.a = 1.0
	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			slow_factor = 1.0
	if attack_cd > 0.0:
		attack_cd -= delta
	if dash_cd > 0.0:
		dash_cd -= delta
		if dash_cd <= 0.0:
			_dash_charges = 0
	if _drop_timer > 0.0:
		_drop_timer -= delta
		if _drop_timer <= 0.0:
			set_collision_mask_value(2, true)

	_update_aim()
	_handle_input(delta)
	_apply_gravity(delta)
	_dash_update(delta)
	move_and_slide()
	_update_animation()
	_check_touch_damage(delta)
	_try_attack()

func _handle_input(delta : float) -> void:
	var dir := Input.get_axis("key_left", "key_right")
	var speed := move_speed * (1.0 + GameState.get_stat("move_speed_mult")) * slow_factor
	if dash_timer <= 0.0:
		velocity.x = dir * speed
		if dir != 0.0:
			facing = 1 if dir > 0.0 else -1

	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.14
	if jump_buffer > 0.0:
		jump_buffer -= delta
	if is_on_floor():
		coyote_timer = 0.1
		jumps_left = max_jumps
	else:
		coyote_timer -= delta
	if jump_buffer > 0.0 and (coyote_timer > 0.0 or jumps_left > 0):
		if coyote_timer > 0.0:
			coyote_timer = 0.0
		jumps_left -= 1
		jump_buffer = 0.0
		velocity.y = jump_velocity * (1.0 + GameState.get_stat("jump_mult"))
		Audio.play("jump", 0.1, -4.0)
		FX.play("dust", global_position + Vector2(0, 15), {"scale": 0.8})
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut
	if Input.is_action_just_pressed("key_down") and _on_platform():
		_drop_timer = 0.18
		set_collision_mask_value(2, false)
	if Input.is_action_just_pressed("dash"):
		_try_dash()

func _apply_gravity(delta : float) -> void:
	if dash_timer > 0.0:
		return
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

func _try_dash() -> void:
	if dash_cd > 0.0 and _dash_charges <= 0:
		return
	var charges : int = 1 + int(GameState.get_stat("dash_charges"))
	if dash_cd <= 0.0:
		_dash_charges = charges - 1
	else:
		_dash_charges -= 1
	var dir := Input.get_axis("key_left", "key_right")
	if dir == 0.0:
		dir = float(facing)
	dash_dir = Vector2(dir, 0).normalized()
	dash_timer = dash_duration
	dash_cd = dash_cooldown * (1.0 + GameState.get_stat("dash_cooldown_mult"))
	invuln = maxf(invuln, dash_duration + 0.12)
	Audio.play("dash", 0.1, -3.0)
	FX.shake(0.12)
	_afterimage_timer = 0.0

func _dash_update(delta : float) -> void:
	if dash_timer <= 0.0:
		return
	dash_timer -= delta
	velocity = dash_dir * dash_speed
	velocity.y = 0.0
	_afterimage_timer -= delta
	if _afterimage_timer <= 0.0:
		_afterimage_timer = 0.035
		FX.play("dust", global_position + Vector2(-dash_dir.x * 8.0, 4), {"scale": 0.7,
			"modulate": Color(0.6, 1.4, 1.5, 0.8)})

func _update_aim() -> void:
	# the knight always faces where he is aiming (mouse, or the demo bot's
	# override), and the weapon pose follows in the same frame
	var aim := aim_direction()
	var reference : Vector2 = global_position + aim
	if absf(reference.x - global_position.x) > 0.1:
		facing = 1 if reference.x > global_position.x else -1
	_update_weapon_pose()

const HAND_OFFSET := Vector2(4.0, 2.0)   ## where the hand is, relative to the body centre
const WEAPON_FRAME := Vector2(40.0, 40.0)
const WEAPON_PIVOT := Vector2(20.0, 34.0)

func _update_weapon_pose() -> void:
	# one mirror only: the whole Weapon node flips, so the artwork, the swing
	# arc and the pivot all turn together (a second flip_h would cancel out)
	weapon_root.scale.x = float(facing)
	weapon_sprite.flip_h = false
	weapon_sprite.position = HAND_OFFSET - WEAPON_PIVOT

func aim_direction() -> Vector2:
	if GameState.autotest and aim_override.length() > 0.01:
		return aim_override.normalized()
	var mouse := get_global_mouse_position()
	var dir := mouse - global_position
	if dir.length() < 2.0:
		return Vector2(facing, 0)
	return dir.normalized()

# ------------------------------------------------------------------- attacks
func _try_attack() -> void:
	if attack_cd > 0.0 or dash_timer > 0.0:
		return
	if not Input.is_action_pressed("attack"):
		return
	var speed_mult : float = 1.0 + GameState.get_stat("attack_speed_mult")
	var cooldown : float = float(weapon.get("cooldown", 0.4)) / maxf(0.15, speed_mult)
	attack_cd = cooldown
	_swing_token += 1
	var token := _swing_token
	var aim := aim_direction()
	facing = 1 if aim.x >= 0.0 else -1
	_update_weapon_pose()
	swing_active = true
	weapon_sprite.play("swing")
	Audio.play("swing", 0.15, -6.0)
	var hit_delay : float = cooldown * float(weapon.get("hit_frame", 0.4))
	await get_tree().create_timer(hit_delay).timeout
	if token != _swing_token or is_dead:
		return
	swing_active = false
	if str(weapon.get("kind", "melee")) == "melee":
		_melee_hit(aim)
	else:
		_shoot(aim)

func attack_damage() -> float:
	return float(weapon.get("damage", 10.0)) * (1.0 + GameState.get_stat("damage_mult"))

func roll_crit() -> bool:
	var chance : float = GameState.get_stat("crit_chance") + float(weapon.get("crit_bonus", 0.0))
	return randf() < chance

func _melee_hit(aim : Vector2) -> void:
	var range_stat : float = 1.0 + GameState.get_stat("range_mult")
	var reach : float = float(weapon.get("range", 40.0)) * range_stat
	var arc : float = deg_to_rad(float(weapon.get("arc", 110.0)))
	var damage := attack_damage()
	var kb : float = float(weapon.get("knockback", 180.0)) * (1.0 + GameState.get_stat("knockback_mult"))
	var stun : float = float(weapon.get("stun", 0.0))
	var hit_something : bool = false
	var slash : String = str(weapon.get("slash", "slash_steel"))
	if slash != "":
		# the arc sheet already spans both sides of the aim direction, so the
		# rotation alone points it at the target (no extra flip)
		FX.play(slash, global_position + Vector2(0, -2), {"rotation": aim.angle(), "scale": reach / 40.0,
			"z": 15})
	FX.shake(float(weapon.get("shake", 0.08)))

	# circle query, then filter by the weapon's swing arc
	var space := get_world_2d().direct_space_state
	var circle := CircleShape2D.new()
	circle.radius = reach
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = circle
	params.transform = Transform2D(0.0, global_position)
	params.collision_mask = ENEMY_LAYER | BREAKABLE_LAYER
	params.collide_with_areas = false
	var results := space.intersect_shape(params, 24)
	var crit := roll_crit()
	for r in results:
		var body = r.get("collider")
		if body == null or body == self:
			continue
		var to_body : Vector2 = body.global_position - global_position
		if body.is_in_group("breakable"):
			if body.has_method("break_open"):
				body.break_open()
			continue
		if not body.is_in_group("enemy"):
			continue
		if absf(angle_difference(to_body.angle(), aim.angle())) > arc * 0.5:
			continue
		hit_something = true
		var dmg := damage * (2.0 + GameState.get_stat("crit_mult")) if crit else damage
		body.take_damage(dmg, to_body.normalized() * kb, crit)
		if stun > 0.0 and body.has_method("apply_stun"):
			body.apply_stun(stun)
		_apply_lifesteal(dmg)
		if crit:
			FX.hitstop(0.05)
	if hit_something:
		FX.hitstop(0.035 + float(weapon.get("stun", 0.0)) * 0.1)

func _shoot(aim : Vector2) -> void:
	var speed_mult : float = 1.0 + GameState.get_stat("attack_speed_mult")
	var damage := attack_damage()
	var crit := roll_crit()
	var count : int = 1 + int(GameState.get_stat("projectile_bonus"))
	var pierce : int = int(weapon.get("pierce_count", 0)) + int(GameState.get_stat("pierce_bonus"))
	var spread : float = 0.09
	# muzzle sits at the hand (mirrored with facing) and a bit along the aim,
	# so arrows visibly leave the bow instead of the character's chest
	var origin : Vector2 = global_position + Vector2(HAND_OFFSET.x * facing, HAND_OFFSET.y) + aim * 12.0
	for i in count:
		var offset := 0.0
		if count > 1:
			offset = (float(i) - (count - 1) * 0.5) * spread
		var p := SpawnHelper.spawn_projectile(get_tree().current_scene, str(weapon.get("projectile", "arrow")),
			origin, Vector2.from_angle(aim.angle() + offset), float(weapon.get("projectile_speed", 600.0)),
			damage * (2.0 + GameState.get_stat("crit_mult")) if crit else damage, true, pierce)
		if p != null:
			p.crit = crit
			p.knockback = float(weapon.get("knockback", 90.0)) * (1.0 + GameState.get_stat("knockback_mult"))
			p.homing_strength = float(weapon.get("homing", 0.0))
			p.lifetime = 1.6
	Audio.play("shoot" if str(weapon.get("projectile", "")) == "arrow" else "magic", 0.12, -5.0)
	FX.shake(0.05)

func _apply_lifesteal(damage : float) -> void:
	var ls : float = GameState.get_stat("lifesteal") + float(weapon.get("lifesteal", 0.0))
	if ls <= 0.0:
		return
	lifesteal_pool += damage * ls
	if lifesteal_pool >= 1.0:
		var amount := int(lifesteal_pool)
		lifesteal_pool -= float(amount)
		GameState.heal(amount)
		FX.play("heal", global_position + Vector2(0, -6), {"scale": 0.8})

# -------------------------------------------------------------------- damage
func _check_touch_damage(delta : float) -> void:
	for key in _touch_cooldown.keys():
		var left := float(_touch_cooldown[key]) - delta
		if left <= -2.0:
			_touch_cooldown.erase(key)
		else:
			_touch_cooldown[key] = left
	var bodies := hurt_box.get_overlapping_bodies()
	for body in bodies:
		if not body.is_in_group("enemy") or body.is_dead:
			continue
		var dmg : float = float(body.damage)
		var kb := (global_position - body.global_position).normalized() * 220.0
		take_damage(dmg, kb)
	var areas := hurt_box.get_overlapping_areas()
	for area in areas:
		if area is Projectile and not area.friendly:
			var id := area.get_instance_id()
			if float(_touch_cooldown.get(id, 0.0)) > 0.0:
				continue
			_touch_cooldown[id] = 1.0
			take_damage(area.damage, area.direction * 160.0)

func take_damage(amount : float, knockback : Vector2 = Vector2.ZERO, _is_crit : bool = false) -> void:
	if is_dead or invuln > 0.0:
		return
	# elven ward blocks the first hit of each wave
	if GameState.upgrade_level("shield") > 0 and ward_ready:
		ward_ready = false
		invuln = 1.0
		FX.play("spawn", global_position, {"scale": 1.4, "modulate": Color("#7fe6cf")})
		Audio.play("heal", 0.05, -2.0)
		GameState.notice.emit("WARD BROKEN", Color("#7fe6cf"))
		return
	var reduction := clampf(GameState.get_stat("damage_reduction"), 0.0, 0.75)
	var final_damage : float = maxf(1.0, round(amount * (1.0 - reduction)))
	if GameState.autotest and not GameState.autotest_mortal:
		final_damage = 0.0  # the demo bot needs to survive long enough to test bosses
	GameState.set_health(GameState.health - int(final_damage))
	invuln = 1.1
	velocity += knockback
	velocity.y = minf(velocity.y, -140.0)
	GameState.damage_taken += int(final_damage)
	FX.damage_number(global_position + Vector2(0, -18), final_damage, {})
	FX.shake(0.45)
	FX.hitstop(0.09)
	FX.flash(Color("#ff3355"), 0.3)
	Audio.play("hurt", 0.1, 0.0)
	FX.play("hit", global_position + Vector2(0, -4), {"scale": 1.3, "modulate": Color("#ff8899")})
	if GameState.health <= 0:
		_die()

func heal(amount : int) -> void:
	GameState.heal(amount)

func apply_slow(factor : float, duration : float) -> void:
	slow_factor = minf(slow_factor, 1.0 - factor)
	slow_timer = maxf(slow_timer, duration)

func _die() -> void:
	if is_dead:
		return
	if GameState.get_stat("revives") > 0.0 and GameState.upgrade_level("revive") > 0:
		GameState.upgrade_levels["revive"] = 0
		GameState.add_stat("revives", -1.0)
		GameState.set_health(2)
		invuln = 2.0
		FX.flash(Color.WHITE, 0.6)
		FX.play("heal", global_position, {"scale": 2.0})
		GameState.notice.emit("SECOND WIND!", Color("#7fe6cf"))
		Audio.play("level_up")
		return
	is_dead = true
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 1
	weapon_sprite.visible = false
	FX.play("death", global_position, {"scale": 1.6})
	FX.shake(1.0)
	FX.slowmo(1.2, 0.3)
	Audio.play("game_over")
	_play_anim("death")
	await get_tree().create_timer(1.4, true, false, true).timeout
	GameState.end_run(false)

# ----------------------------------------------------------------- animation
func _update_animation() -> void:
	if is_dead:
		return
	if GameState.health <= 0:
		return
	if dash_timer > 0.0:
		_play_anim("dash")
		return
	if invuln > 0.4 and not is_on_floor():
		_play_anim("hurt")
		return
	if not is_on_floor():
		_play_anim("jump" if velocity.y < 0.0 else "fall")
	elif absf(velocity.x) > 12.0:
		_play_anim("run")
	else:
		_play_anim("idle")
	sprite.flip_h = facing < 0

func _play_anim(anim : String) -> void:
	if _anim == anim:
		return
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(anim):
		return
	_anim = anim
	sprite.play(anim)

func _on_platform() -> bool:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider = col.get_collider()
		if collider != null and collider.is_in_group("platforms"):
			return true
	return false
