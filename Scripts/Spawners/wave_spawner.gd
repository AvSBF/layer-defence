class_name WaveSpawner
extends Node2D

signal wave_started(wave_index : int)
signal wave_completed(wave_index : int)
signal all_waves_completed

@export var waves : Array[EnemyWave] = []
@export var delay_between_waves : float = 5.0
@export var auto_start : bool = true
@export var target : Node2D

@export var spawn_areas : Array[Node2D]
@export var regular_spawn_points : Node2D

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
		var spawn_pos = _get_spawn_position(wave)
		_create_enemy(wave, spawn_pos)
		if i < wave.count - 1:
			await get_tree().create_timer(wave.delay_between).timeout
	is_spawning = false

func _get_spawn_position(wave : EnemyWave) -> Vector2:
	if wave.spawn_mode == EnemyWave.SpawnMode.AREA:
		return _get_random_point_in_area(spawn_areas[spawn_areas.size()])
	elif wave.spawn_mode == EnemyWave.SpawnMode.POINT:
		return _get_random_point()
	return global_position

func _get_random_point_in_area(area : Node2D) -> Vector2:
	return area.get_child(randi_range(0,area.get_child_count())).global_position

func _get_random_point() -> Vector2:
	return regular_spawn_points.get_child(randi_range(0,regular_spawn_points.get_child_count())).global_position

func _create_enemy(wave : EnemyWave, pos : Vector2) -> void:
	var enemy = wave.enemy_scene.instantiate()
	enemy.stats = wave.stats
	enemy.target = target
	enemy.global_position = pos
	enemies_alive += 1
	add_child(enemy)
	enemy.health_component.died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	enemies_alive -= 1
	if enemies_alive <= 0 and not is_spawning:
		wave_completed.emit(current_wave)
		current_wave += 1
		await get_tree().create_timer(delay_between_waves).timeout
		_spawn_next_wave()
