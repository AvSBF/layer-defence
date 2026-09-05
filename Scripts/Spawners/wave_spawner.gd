class_name WaveSpawner
extends Node2D

signal wave_started(wave_index : int)
signal wave_completed(wave_index : int)
signal all_waves_completed

@export var waves : Array[EnemyWave] = []
@export var delay_between_waves : float = 5.0
@export var auto_start : bool = true
@export var target : Node2D
@export var spawn_areas : Array[SpawnArea]
@export var spawn_points : Array[SpawnPoint]

var current_wave : int = 0
var enemies_alive : int = 0
var is_spawning : bool = false

func _ready() -> void:
	if auto_start:
		start_waves()

func start_waves() -> void:
	current_wave = 0
	_spawn_next_wave()

func _spawn_next_wave() -> void:
	if current_wave >= waves.size():
		all_waves_completed.emit()
		return
	var wave = waves[current_wave]
	wave_started.emit(current_wave)
	_spawn_enemies(wave)

func _spawn_enemies(wave : EnemyWave) -> void:
	is_spawning = true
	for i in wave.count:
		var spawn_pos = _get_spawn_position()
		_create_enemy(wave, spawn_pos)
		if i < wave.count - 1:
			await get_tree().create_timer(wave.delay_between).timeout
	is_spawning = false

func _get_spawn_position() -> Vector2:
	if spawn_areas.size() > 0:
		var area = spawn_areas.pick_random()
		var marker = area.get_random_point()
		if marker:
			return marker.global_position
	if spawn_points.size() > 0:
		var point = spawn_points.pick_random()
		return point.global_position
	return global_position

func _create_enemy(wave : EnemyWave, pos : Vector2) -> void:
	print("[Spawner] Creating enemy at: ", pos)
	print("[Spawner] wave.stats: ", wave.stats)
	print("[Spawner] wave.enemy_scene: ", wave.enemy_scene)
	var enemy = wave.enemy_scene.instantiate()
	if wave.stats:
		enemy.stats = wave.stats
	else:
		print("[Spawner] WARNING: wave.stats is null, using default")
	enemy.target = target
	enemy.global_position = pos
	enemies_alive += 1
	add_child(enemy)
	enemy._setup_navigation()
	print("[Spawner] Enemy added. target: ", enemy.target, " stats: ", enemy.stats)
	enemy.health_component.died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	enemies_alive -= 1
	if enemies_alive <= 0 and not is_spawning:
		wave_completed.emit(current_wave)
		current_wave += 1
		await get_tree().create_timer(delay_between_waves).timeout
		_spawn_next_wave()
