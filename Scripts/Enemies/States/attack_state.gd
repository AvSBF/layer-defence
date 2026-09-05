class_name AttackState
extends State

var attack_timer : float = 0.0

func enter() -> void:
	attack_timer = 0.0
	enemy.velocity.x = 0

func process(delta : float) -> void:
	attack_timer -= delta

func physics_process(delta : float) -> void:
	if not enemy.target:
		state_machine.transition_to("Idle")
		return

	if enemy.global_position.distance_to(enemy.target.global_position) > enemy.stats.attack_range:
		state_machine.transition_to("Chase")
		return

	if attack_timer <= 0:
		attack_timer = enemy.stats.attack_cooldown
