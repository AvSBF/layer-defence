class_name ChaseState
extends State

func enter() -> void:
	pass

func physics_process(delta : float) -> void:
	if not enemy.target:
		state_machine.transition_to("Idle")
		return

	enemy.navigation_agent.target_position = enemy.target.global_position

	if enemy.global_position.distance_to(enemy.target.global_position) <= enemy.stats.attack_range:
		state_machine.transition_to("Attack")
