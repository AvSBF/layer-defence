class_name WaveManager
extends Node2D

## Owns the run loop:
##   build a wave -> rain it out of the portal -> wait until the arena is empty
##   -> pay out -> LOOT WINDOW (grab the drops) -> RESHAPE (platforms slide,
##   portal reopens on the other side) -> gate lights up + shop opens.

signal wave_started(wave : int, is_boss : bool, info : Dictionary)
signal wave_cleared(wave : int)
signal enemies_changed(alive : int, total : int)
signal shop_requested(reason : String)
signal hint_changed(text : String, visible : bool)

enum State { IDLE, SPAWNING, FIGHTING, LOOTING, RESHAPING, CLEARED }

@export var portal_path : NodePath
@export var gate_path : NodePath
@export var enemy_holder_path : NodePath
@export var pot_holder_path : NodePath
@export var platforms_path : NodePath
@export var spawn_interval : float = 0.42
@export var pot_interval : Vector2 = Vector2(6.0, 10.0)
@export var pot_chance : float = 0.75
@export var loot_window : float = 7.0
@export var reshape_time : float = 1.1

var state : int = State.IDLE
var wave_total : int = 0
var wave_modifiers : Array = []
var rng := RandomNumberGenerator.new()
var loot_timer : float = 0.0

var _queue : Array = []
var _spawn_timer : float = 0.0
var _pot_timer : float = 0.0
var _boss_name : String = ""
var _portal : Node2D
var _gate : Node2D
var _platforms : Node2D
var _enemy_holder : Node
var _pot_holder : Node
var _portal_x : float = 0.0

func _ready() -> void:
	GameState.wave_manager = self
	rng.seed = GameState.seed_value
	_portal = get_node_or_null(portal_path)
	_gate = get_node_or_null(gate_path)
	_platforms = get_node_or_null(platforms_path)
	_enemy_holder = get_node_or_null(enemy_holder_path)
	_pot_holder = get_node_or_null(pot_holder_path)
	if _enemy_holder == null:
		_enemy_holder = self
	if _pot_holder == null:
		_pot_holder = self
	if _portal != null:
		_portal_x = _portal.global_position.x
	if _gate != null:
		_gate.connect("entered", Callable(self, "_on_gate_entered"))
		_gate.call("deactivate")
	_pot_timer = rng.randf_range(pot_interval.x, pot_interval.y)

# ------------------------------------------------------------------- lifecycle
func start_run() -> void:
	state = State.IDLE
	wave_total = 0
	_queue.clear()
	# debug helper: `godot -- --autotest --start-wave=5` jumps straight to a boss
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--start-wave="):
			GameState.wave = maxi(0, int(arg.split("=")[1]) - 1)
	if _gate != null:
		_gate.call("activate")
	hint_changed.emit("STEP INTO THE GREEN GATE", true)

func is_between_waves() -> bool:
	return state == State.CLEARED or state == State.IDLE or state == State.LOOTING or state == State.RESHAPING

func can_start_wave() -> bool:
	return state == State.CLEARED or state == State.IDLE

func set_gate(enabled : bool) -> void:
	if _gate == null:
		return
	if enabled and can_start_wave():
		_gate.call("activate")
	else:
		_gate.call("deactivate")

func start_wave() -> void:
	GameState.next_wave()
	var wave := GameState.wave
	var is_boss := GameState.is_boss_wave
	if _gate != null:
		_gate.call("deactivate")
	hint_changed.emit("", false)
	_queue.clear()
	wave_modifiers.clear()
	_boss_name = ""
	if is_boss:
		_boss_name = EnemyCatalog.boss_for_wave(wave)
		_queue.append({"id": _boss_name, "boss": true})
		for id in EnemyCatalog.build_wave(wave, rng):
			_queue.append({"id": id, "boss": false})
		if _queue.size() > 7:
			_queue.resize(7)
	else:
		for id in EnemyCatalog.build_wave(wave, rng):
			_queue.append({"id": id, "boss": false})
	wave_total = _queue.size()
	GameState.enemies_spawned += wave_total
	state = State.SPAWNING
	_spawn_timer = 0.35
	if _portal != null:
		_portal.call("charge")
	var info := {
		"wave": wave,
		"is_boss": is_boss,
		"boss_name": _boss_name,
		"total": wave_total,
		"modifiers": wave_modifiers,
	}
	if GameState.autotest:
		print("[autotest] wave %d start: %d enemies (boss=%s) hp=%d coins=%d portal_x=%.0f" %
			[wave, wave_total, str(is_boss), GameState.health, GameState.coins, _portal_x])
	Audio.play("wave_start")
	if is_boss:
		Audio.play("boss")
		FX.shake(0.5)
	wave_started.emit(wave, is_boss, info)
	enemies_changed.emit(0, wave_total)
	if _portal != null:
		_portal.call("burst")

func _process(delta : float) -> void:
	match state:
		State.SPAWNING:
			_spawn_timer -= delta
			if _spawn_timer <= 0.0:
				_spawn_next()
		State.FIGHTING:
			_update_fighting(delta)
		State.LOOTING:
			_update_looting(delta)

func _update_fighting(_delta : float) -> void:
	var alive := get_tree().get_nodes_in_group("enemy").size()
	enemies_changed.emit(alive, wave_total)
	if alive <= 0:
		_finish_wave()

func _update_looting(delta : float) -> void:
	loot_timer -= delta
	var left := maxi(0, int(ceil(loot_timer)))
	hint_changed.emit("COLLECT THE LOOT  %ds" % left, true)
	if loot_timer <= 0.0:
		_begin_reshape()

func _spawn_next() -> void:
	if _queue.is_empty():
		state = State.FIGHTING
		_pot_timer = minf(_pot_timer, 3.0)
		return
	var entry : Dictionary = _queue.pop_front()
	var id : String = entry["id"]
	var is_boss : bool = entry.get("boss", false)
	var base_pos : Vector2 = _portal.global_position if _portal != null else global_position
	var offset := rng.randf_range(-46.0, 46.0) if not is_boss else 0.0
	var pos := base_pos + Vector2(offset, -10.0)
	var elite := (not is_boss) and rng.randf() < elite_chance()
	var fall := rng.randf_range(200.0, 330.0) if not is_boss else 120.0
	var e := SpawnHelper.spawn_enemy(_enemy_holder, id, pos, GameState.wave, true, elite, fall)
	if e != null:
		e.died.connect(_on_enemy_died)
	if is_boss:
		GameState.boss_spawned.emit(str(e.data.get("name", "BOSS")), e.max_hp)
		FX.shake(0.7)
		FX.zoom_punch(0.18)
		if _portal != null:
			_portal.call("burst")
	_spawn_timer = spawn_interval if not is_boss else 1.1
	if _portal != null:
		_portal.call("burst")

func elite_chance() -> float:
	return clampf(0.03 + 0.012 * float(maxi(0, GameState.wave - 5)), 0.0, 0.22)

func _on_enemy_died(_e : Enemy) -> void:
	if state == State.SPAWNING or state == State.FIGHTING:
		var alive := get_tree().get_nodes_in_group("enemy").size()
		enemies_changed.emit(alive, wave_total)

func _finish_wave() -> void:
	state = State.LOOTING
	loot_timer = loot_window
	var wave := GameState.wave
	var bonus := GameState.coins_for_kill(6 + wave * 2)
	GameState.add_coins(bonus)
	GameState.notice.emit("WAVE %d CLEARED  +%d COINS" % [wave, bonus], Color("#ffd34d"))
	if GameState.autotest:
		print("[autotest] wave %d cleared, bonus=%d, hp=%d, total coins=%d" %
			[wave, bonus, GameState.health, GameState.coins])
	Audio.play("level_up", 0.05, 0.0)
	wave_cleared.emit(wave)

## End of the loot window: hoover up whatever is still lying around, then let
## the arena rebuild itself before the gate lights up again.
func _begin_reshape() -> void:
	state = State.RESHAPING
	hint_changed.emit("THE ARENA IS SHIFTING…", true)
	Pickup.vacuum_all()
	await get_tree().create_timer(0.35).timeout
	if _platforms != null and _platforms.has_method("reshuffle"):
		_platforms.call("reshuffle")
	_move_portal()
	await get_tree().create_timer(reshape_time).timeout
	state = State.CLEARED
	hint_changed.emit("STEP INTO THE GREEN GATE", true)
	if _gate != null:
		_gate.call("activate")
	shop_requested.emit("wave_cleared")

## Alternate sides of the arena and randomise the distance from the centre.
func _move_portal() -> void:
	if _portal == null:
		return
	var side := -1.0 if _portal_x >= 0.0 else 1.0
	var distance := rng.randf_range(170.0, 430.0)
	_portal_x = side * distance
	if _portal.has_method("relocate_to"):
		_portal.call("relocate_to", _portal_x)

func _on_gate_entered() -> void:
	if can_start_wave():
		start_wave()

# ---------------------------------------------------------------------- pots
func _spawn_breakable() -> void:
	var x : float
	if rng.randf() < 0.5:
		x = _portal_x + rng.randf_range(-160.0, 160.0)
	else:
		x = rng.randf_range(-520.0, 520.0)
	var pos := Vector2(clampf(x, -620.0, 620.0), -430.0)
	var kind := "chest" if rng.randf() < 0.14 else "pot"
	Pot.spawn(_pot_holder, pos, rng.randf_range(120.0, 220.0), kind)

func _pot_tick(delta : float) -> void:
	if state != State.FIGHTING and state != State.SPAWNING:
		return
	_pot_timer -= delta
	if _pot_timer <= 0.0:
		_pot_timer = rng.randf_range(pot_interval.x, pot_interval.y)
		if rng.randf() < pot_chance:
			_spawn_breakable()

func _physics_process(delta : float) -> void:
	_pot_tick(delta)
