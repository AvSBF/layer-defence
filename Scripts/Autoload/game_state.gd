extends Node

## The run singleton. Holds the meta state of a roguelike run: coins, wave,
## bought upgrades and every derived player stat. Gameplay nodes never talk to
## each other about these numbers - they ask GameState.

signal coins_changed(coins : int, delta : int)
signal wave_changed(wave : int, is_boss : bool)
signal upgrades_changed
signal run_started
signal run_ended(victory : bool)
signal boss_spawned(boss_name : String, max_hp : float)
signal boss_health_changed(hp : float, max_hp : float)
signal boss_defeated
signal notice(text : String, color : Color)

const MAX_UPGRADE_LEVEL := 5

## Every modifier the player can own. Values are additive percentages / flat
## numbers, resolved by the player when it needs them.
const DEFAULT_STATS := {
	"damage_mult": 0.0,
	"attack_speed_mult": 0.0,
	"move_speed_mult": 0.0,
	"max_hp_bonus": 0.0,
	"crit_chance": 0.05,
	"crit_mult": 1.0,
	"lifesteal": 0.0,
	"magnet_radius": 42.0,
	"dash_cooldown_mult": 0.0,
	"extra_jumps": 0.0,
	"jump_mult": 0.0,
	"damage_reduction": 0.0,
	"coin_mult": 0.0,
	"knockback_mult": 0.0,
	"range_mult": 0.0,
	"pierce_bonus": 0.0,
	"projectile_bonus": 0.0,
	"dash_charges": 0.0,
	"revives": 0.0,
	"luck": 0.0,
	"pickup_heal": 0.0,
}

var coins : int = 0
var wave : int = 0
var kills : int = 0
var coins_earned : int = 0
var damage_dealt : int = 0
var damage_taken : int = 0
var enemies_spawned : int = 0
var run_active : bool = false
var is_boss_wave : bool = false
var stats : Dictionary = {}
var upgrade_levels : Dictionary = {}
var weapon_owned_ids : Array = ["sword"]
var shop_rerolls : int = 0
var health : int = 6
var max_health : int = 6
var seed_value : int = 0
var time_alive : float = 0.0
var autotest : bool = false
var autotest_mortal : bool = false
var aim_lock : Vector2 = Vector2.ZERO
var shop_demo : bool = false

## Set by the world so GameState can heal / revive / kill the player.
var player : Node = null
var wave_manager : Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	reset_run()

func _process(delta : float) -> void:
	if run_active:
		time_alive += delta

# ------------------------------------------------------------------ run flow
func reset_run(new_seed : int = 0) -> void:
	coins = 0
	wave = 0
	kills = 0
	coins_earned = 0
	damage_dealt = 0
	damage_taken = 0
	enemies_spawned = 0
	run_active = false
	is_boss_wave = false
	upgrade_levels.clear()
	weapon_owned_ids = ["sword"]
	shop_rerolls = 0
	time_alive = 0.0
	stats = DEFAULT_STATS.duplicate(true)
	seed_value = new_seed if new_seed != 0 else randi()
	max_health = 6
	health = max_health
	upgrades_changed.emit()
	coins_changed.emit(coins, 0)

func start_run() -> void:
	reset_run()
	run_active = true
	wave = 0
	run_started.emit()

func end_run(victory : bool = false) -> void:
	if not run_active:
		return
	run_active = false
	run_ended.emit(victory)

func next_wave() -> void:
	wave += 1
	is_boss_wave = (wave % 5 == 0)
	shop_rerolls = 0
	wave_changed.emit(wave, is_boss_wave)

# --------------------------------------------------------------------- stats
func get_stat(key : String) -> float:
	return float(stats.get(key, 0.0))

func add_stat(key : String, value : float) -> void:
	stats[key] = float(stats.get(key, 0.0)) + value
	upgrades_changed.emit()

func max_hp() -> int:
	return int(max_health + get_stat("max_hp_bonus"))

func heal(amount : int) -> void:
	var before := health
	health = mini(max_hp(), health + amount)
	if health != before:
		upgrades_changed.emit()
		notice.emit("+%d HP" % (health - before), Color("#7fe6cf"))

func set_health(value : int) -> void:
	health = clampi(value, 0, max_hp())
	upgrades_changed.emit()

# --------------------------------------------------------------------- coins
func add_coins(amount : int) -> void:
	if amount <= 0:
		return
	coins += amount
	coins_earned += amount
	coins_changed.emit(coins, amount)

func coins_for_kill(base : int) -> int:
	var mult := 1.0 + get_stat("coin_mult")
	var amount := maxi(1, int(round(base * mult * randf_range(0.85, 1.25))))
	return amount

func spend(amount : int) -> bool:
	if amount <= 0:
		return false
	if coins < amount:
		notice.emit("NOT ENOUGH COINS", Color("#ff7a6f"))
		Audio.play("click", 0.0, -4.0)
		return false
	coins -= amount
	coins_changed.emit(coins, -amount)
	return true

# ----------------------------------------------------------------- upgrades
func weapon_owned(id : String) -> bool:
	return weapon_owned_ids.has(id)

func mark_weapon_owned(id : String) -> void:
	if not weapon_owned_ids.has(id):
		weapon_owned_ids.append(id)

func upgrade_level(id : String) -> int:
	return int(upgrade_levels.get(id, 0))

func can_take_upgrade(upgrade : Dictionary) -> bool:
	var lvl := upgrade_level(upgrade["id"])
	return lvl < int(upgrade.get("max", MAX_UPGRADE_LEVEL))

func apply_upgrade(upgrade : Dictionary) -> bool:
	var id : String = upgrade["id"]
	if not can_take_upgrade(upgrade):
		return false
	upgrade_levels[id] = upgrade_level(id) + 1
	var effects : Dictionary = upgrade.get("effects", {})
	for key in effects:
		add_stat(key, float(effects[key]))
	match str(upgrade.get("special", "")):
		"heal_full":
			set_health(max_hp())
		"heal_2":
			heal(2)
		"heal_3":
			heal(3)
	upgrades_changed.emit()
	notice.emit(upgrade.get("name", "UPGRADE") + " " + _roman(upgrade_level(id)), Color("#ffd34d"))
	if autotest:
		print("[autotest] bought upgrade %s %s" % [id, _roman(upgrade_level(id))])
	return true

func _roman(n : int) -> String:
	return ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"][clampi(n, 0, 10)]

# ------------------------------------------------------------------- helpers
func register_kill(coins_base : int) -> void:
	kills += 1

func upgrade_cost(upgrade : Dictionary) -> int:
	var base := int(upgrade.get("cost", 12))
	var lvl := upgrade_level(upgrade["id"])
	var wave_scale := 1.0 + 0.06 * float(maxi(0, wave - 1))
	var lvl_scale := 1.0 + 0.35 * float(lvl)
	return int(round(base * wave_scale * lvl_scale))
