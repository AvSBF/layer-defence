class_name WaveSpawner
extends Node2D

@export var waves : Array[EnemyWave] = []
@export var target : Node2D
@export var spawn_areas : Array[SpawnArea] = []
@export var spawn_points : Node2D = null

var current_wave_index : int = 0
var enemies_alive : int = 0
var is_spawning : bool = false
var all_waves_complete : bool = false

func _ready() -> void:
	if spawn_areas.is_empty():
		for child in get_children():
			if child is SpawnArea:
				spawn_areas.append(child)
	if spawn_points == null:
		if has_node("RegularSpawnPoints"):
			spawn_points = get_node("RegularSpawnPoints")
	_spawn_next_wave()

func start_waves() -> void:
	if waves.is_empty():
		return
	current_wave_index = 0
	all_waves_complete = false
	_spawn_next_wave()

func _spawn_next_wave() -> void:
	if current_wave_index >= waves.size():
		all_waves_complete = true
		return
	var wave = waves[current_wave_index]
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
	match wave.spawn_mode:
		EnemyWave.SpawnMode.AREA:
			if spawn_areas.size() > 0:
				var area = spawn_areas.pick_random()
				var marker = area.get_random_point()
				if marker:
					return marker.global_position
		EnemyWave.SpawnMode.POINT:
			if spawn_points and spawn_points.get_child_count() > 0:
				var point = spawn_points.get_children().pick_random()
				return point.global_position
	return global_position

func _create_enemy(wave : EnemyWave, pos : Vector2) -> void:
	var enemy = wave.enemy_scene.instantiate()
	if wave.stats:
		enemy.stats = wave.stats
	enemy.target = target
	enemy.global_position = pos
	enemies_alive += 1
	add_child(enemy)
	enemy.health_component.died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	enemies_alive -= 1
	if enemies_alive <= 0:
		current_wave_index += 1
		if current_wave_index < waves.size():
			_spawn_next_wave()
		else:
			all_waves_complete = true

func get_total_waves() -> int:
	return waves.size()

func get_current_wave() -> int:
	return current_wave_index + 1
