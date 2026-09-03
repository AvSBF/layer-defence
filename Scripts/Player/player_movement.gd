extends Node

@onready var controller : CharacterBody2D = get_parent()

func _physics_process(delta: float) -> void:
	var direction_x := Input.get_axis("key_left", "key_right")
	controller.velocity.x = direction_x * controller.move_speed

	if not controller.is_on_floor():
		controller.velocity.y += controller.gravity * delta
	elif Input.is_action_just_pressed("jump"):
		controller.velocity.y = controller.jump_force

	controller.move_and_slide()
