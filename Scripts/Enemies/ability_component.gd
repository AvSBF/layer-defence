class_name AbilityComponent
extends Node

var abilities : Array[EnemyAbility] = []
var cooldowns : Dictionary = {}

func setup(stats : EnemyStats) -> void:
	pass

func add_ability(ability : EnemyAbility) -> void:
	abilities.append(ability)
	cooldowns[ability] = 0.0

func can_use_ability(ability : EnemyAbility) -> bool:
	return cooldowns.get(ability, 0.0) <= 0.0

func use_ability(ability : EnemyAbility) -> void:
	if can_use_ability(ability):
		cooldowns[ability] = ability.cooldown

func _process(delta : float) -> void:
	for ability in abilities:
		if cooldowns[ability] > 0:
			cooldowns[ability] -= delta
