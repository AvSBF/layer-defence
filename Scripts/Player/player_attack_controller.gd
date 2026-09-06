class_name PlayerAttackController
extends Node

@export var weapon_animation : AnimatedSprite2D
@export var weapon_wave : PackedScene

var is_attacking = false

func _ready() -> void:
	weapon_animation.animation_finished.connect(_on_animation_finished)

func attack():
	if is_attacking:
		return
	weapon_animation.play("SwordSwingAnimation")
	is_attacking = true
	_spawn_wave()

func _on_animation_finished():
	is_attacking = false

func _spawn_wave():
	var wave_instance = weapon_wave.instantiate()
	var weapon_position : Vector2 = $"../Weapon".global_position
	var player : Node = get_parent()
	var is_left : bool = player.get_meta("looking_left") if player.has_meta("looking_left") else false
	wave_instance.global_position = weapon_position
	wave_instance.set_direction(is_left)
	player.get_parent().add_child(wave_instance)
