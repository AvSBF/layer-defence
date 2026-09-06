class_name PlayerController
extends CharacterBody2D

@export var move_speed : float = 2
@export var jump_force : float = -800
@export var max_jump_hold : float = 1
@export var gravity : float = 980
@export var attack_damage : float = 30

@export var attack_controller : PlayerAttackController

func _unhandled_input(event: InputEvent) -> void:
	_correct_turn()
	if event.is_action_pressed("attack"):
		attack_controller.attack()

func _correct_turn():
	if velocity.x > 0:
		set_meta("looking_left",false)
	elif velocity.x < 0:
		set_meta("looking_left",true)
