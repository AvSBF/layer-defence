class_name ChaseState
extends State

var nav : EnemyNavigation
var recalc_timer : float = 0.0

func enter() -> void:
	nav = enemy.get_node_or_null("EnemyNavigation")
	recalc_timer = 0.0
	if nav:
		nav.update_path()

func physics_process(delta : float) -> void:
	if not enemy.target:
		state_machine.transition_to("Idle")
		return

	recalc_timer -= delta
	if recalc_timer <= 0:
		recalc_timer = 0.5
		if nav:
			nav.update_path()

	var dist = enemy.global_position.distance_to(enemy.target.global_position)
	if dist <= enemy.stats.attack_range:
		enemy.velocity.x = 0
		state_machine.transition_to("Attack")
		return

	if nav and nav.current_waypoint:
		var dir = nav.get_move_direction()
		enemy.velocity.x = dir * enemy.stats.move_speed

		if nav.should_jump() and enemy.is_on_floor():
			enemy.velocity.y = enemy.stats.jump_force

		if nav.is_at_waypoint():
			nav.advance_waypoint()
			if not nav.current_waypoint:
				nav.update_path()
	else:
		var direction = (enemy.target.global_position - enemy.global_position).normalized()
		enemy.velocity.x = direction.x * enemy.stats.move_speed

		if enemy.is_on_floor():
			var vertical_diff = enemy.target.global_position.y - enemy.global_position.y
			if vertical_diff < -20:
				enemy.velocity.y = enemy.stats.jump_force
