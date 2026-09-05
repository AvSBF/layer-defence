class_name EnemyAbility
extends Resource

enum AbilityType { DASH, JUMP, SHOOT, CHARGE, TELEPORT }

@export var ability_name : String = ""
@export var ability_type : AbilityType = AbilityType.DASH
@export var cooldown : float = 1.0
@export var damage : float = 0
@export var range : float = 100
@export var speed_multiplier : float = 1.0
@export var duration : float = 0.2
