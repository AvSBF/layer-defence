class_name EnemyWave
extends Resource

enum SpawnMode { AREA, POINT }

@export var enemy_scene : PackedScene
@export var stats : EnemyStats
@export var count : int = 5
@export var spawn_mode : SpawnMode = SpawnMode.AREA
@export var delay_between : float = 0.5
