extends Node

@onready var controller : CharacterBody2D = get_parent()

var time_jump_pressed : float = 0

func _physics_process(delta: float) -> void:
	var direction_x := Input.get_axis("key_left", "key_right")
	controller.velocity.x = direction_x * controller.move_speed

	if not controller.is_on_floor():
		controller.velocity.y += controller.gravity * delta
	elif Input.is_action_pressed("jump"):
		time_jump_pressed += delta
	elif Input.is_action_just_released("jump"):
		var jump_height = _calculate_jump_height()
		controller.velocity.y = jump_height

	controller.move_and_slide()

func _calculate_jump_height() -> float:
	if time_jump_pressed > controller.max_jump_hold:
		time_jump_pressed = controller.max_jump_hold
	var t = clamp(time_jump_pressed / controller.max_jump_hold, 0.0, 1.0)
	var magnitude = lerpf(200, 600, t)
	var strength = -magnitude if controller.jump_force < 0 else magnitude
	return strength
