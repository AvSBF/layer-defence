class_name HealthComponent
extends Node

signal health_changed(new_health : float)
signal died

@export var max_health : float = 100
var health : float

func _ready() -> void:
	health = max_health

func take_damage(amount : float) -> void:
	health = clamp(health - amount, 0, max_health)
	health_changed.emit(health)
	if health <= 0:
		died.emit()

func heal(amount : float) -> void:
	health = clamp(health + amount, 0, max_health)
	health_changed.emit(health)
