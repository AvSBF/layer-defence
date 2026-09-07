extends Node

@onready var controller : CharacterBody2D = get_parent()

var time_jump_pressed : float = 0
var is_dropping : bool = false
var drop_timer : float = 0.0

const DROP_DURATION : float = 0.2
const PLATFORM_LAYER : int = 2

func _physics_process(delta: float) -> void:
	var direction_x := Input.get_axis("key_left", "key_right")
	controller.velocity.x = direction_x * controller.move_speed
	controller.velocity
	if not controller.is_on_floor():
		controller.velocity.y += controller.gravity * delta
	elif Input.is_action_pressed("jump"):
		time_jump_pressed += delta
	elif Input.is_action_just_released("jump"):
		var jump_height = _calculate_jump_height()
		controller.velocity.y = jump_height
	elif Input.is_action_just_pressed("key_down") and _is_on_platform():
		_start_drop()

	if is_dropping:
		drop_timer -= delta
		if drop_timer <= 0:
			_end_drop()

	controller.move_and_slide()

func _is_on_platform() -> bool:
	for i in range(controller.get_slide_collision_count()):
		var collision = controller.get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("platforms"):
			return true
	return false

func _start_drop() -> void:
	is_dropping = true
	drop_timer = DROP_DURATION
	controller.set_collision_mask_value(PLATFORM_LAYER, false)

func _end_drop() -> void:
	is_dropping = false
	controller.set_collision_mask_value(PLATFORM_LAYER, true)

func _calculate_jump_height() -> float:
	if time_jump_pressed > controller.max_jump_hold:
		time_jump_pressed = controller.max_jump_hold
	var t = clamp(time_jump_pressed / controller.max_jump_hold, 0.0, 1.0)
	var magnitude = lerpf(200, 600, t)
	var strength = -magnitude if controller.jump_force < 0 else magnitude
	return strength
