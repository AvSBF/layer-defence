class_name ChaseState
extends State

var jump_cooldown : float = 0.0
var dash_cooldown : float = 0.0
var drop_timer : float = 0.0
var is_dropping : bool = false

const DROP_DURATION : float = 0.2
const PLATFORM_LAYER : int = 2

func enter() -> void:
	jump_cooldown = 0.0
	dash_cooldown = 0.0
	drop_timer = 0.0
	is_dropping = false

func physics_process(delta : float) -> void:
	if is_dropping:
		drop_timer -= delta
		if drop_timer <= 0:
			is_dropping = false
			enemy.set_collision_mask_value(PLATFORM_LAYER, true)

	if not enemy.target:
		state_machine.transition_to("Idle")
		return

	jump_cooldown -= delta
	dash_cooldown -= delta

	var to_target = enemy.target.global_position - enemy.global_position
	var dist = enemy.global_position.distance_to(enemy.target.global_position)

	if dist <= enemy.stats.attack_range:
		enemy.velocity.x = 0
		state_machine.transition_to("Attack")
		return

	var speed = enemy.stats.move_speed + enemy.speed_variation

	if enemy.dash_active:
		return

	enemy.velocity.x = sign(to_target.x) * speed

	if enemy.is_on_floor() and jump_cooldown <= 0:
		if to_target.y < -20 or abs(to_target.x) < 10 and to_target.y < 0:
			enemy.velocity.y = enemy.stats.jump_force
			jump_cooldown = 0.5

	if enemy.is_on_floor() and dash_cooldown <= 0 and dist > 100 and dist < 400:
		enemy.start_dash(sign(to_target.x))
		dash_cooldown = 2.0

	if enemy.is_on_floor() and _is_on_platform() and _is_on_same_platform() and to_target.y > 20:
		_start_drop()

func _is_on_platform() -> bool:
	for i in range(enemy.get_slide_collision_count()):
		var collision = enemy.get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("platforms"):
			return true
	return false

func _is_on_same_platform() -> bool:
	if not enemy.target:
		return false
	return enemy.target.global_position.y > enemy.global_position.y

func _start_drop() -> void:
	is_dropping = true
	drop_timer = DROP_DURATION
	enemy.set_collision_mask_value(PLATFORM_LAYER, false)
