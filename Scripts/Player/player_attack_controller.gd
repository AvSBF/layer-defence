class_name PlayerAttackController
extends Node

@export var weapon_animation : AnimatedSprite2D
@export var weapon_wave : PackedScene

var is_attacking = false

func _ready() -> void:
	weapon_animation.animation_finished.connect(_on_animation_finished)

func attack_with_direction(click_direction : Vector2):
	if is_attacking:
		return
	weapon_animation.play("SwordSwingAnimation")
	is_attacking = true
	_spawn_wave(click_direction)

func attack():
	if is_attacking:
		return
	weapon_animation.play("SwordSwingAnimation")
	is_attacking = true
	_spawn_wave()

func _on_animation_finished():
	is_attacking = false

func _spawn_wave(direction : Vector2 = Vector2.RIGHT) -> Node2D:
	var wave_instance = weapon_wave.instantiate()
	var weapon_position : Vector2 = $"../Weapon".global_position
	wave_instance.global_position = weapon_position
	get_parent().get_parent().add_child(wave_instance)
	wave_instance.set_direction(direction)
	return wave_instance
