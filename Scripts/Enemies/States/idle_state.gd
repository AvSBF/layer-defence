class_name IdleState
extends State

func enter() -> void:
	enemy.velocity.x = 0

func physics_process(delta : float) -> void:
	if enemy.target:
		state_machine.transition_to("Chase")
