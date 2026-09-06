class_name EnemyStats
extends Resource

@export var max_hp : float = 100
@export var move_speed : float = 100
@export var damage : float = 10
@export var jump_force : float = -400
@export var dash_force : float = 300
@export var dash_duration : float = 0.2
@export var attack_range : float = 50
@export var attack_cooldown : float = 1.0
@export var abilities : Array[EnemyAbility] = []
