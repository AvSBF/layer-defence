class_name WeaponWaveController
extends Area2D

@export var attack_damage : float = 10
@export var knockback : float = 200
@export var move_speed : float = 600
@export var destroy_time : float = 1

var can_move : bool = false
var direction : Vector2
var hit_enemies : Array[Enemy] = []

func _ready() -> void:
	get_tree().create_timer(destroy_time).timeout.connect(queue_free)

func set_direction(dir : Vector2):
	direction = dir.normalized()
	rotation = direction.angle()
	can_move = true
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("RESET")

func _physics_process(delta: float) -> void:
	if not can_move:
		return
	global_position += direction * move_speed * delta
	
	for body in get_overlapping_bodies():
		if body.get_parent().is_in_group("enemy") and body not in hit_enemies:
			hit_enemies.append(body)
			body.health_component.take_damage(attack_damage)
			var knockback_dir = (body.global_position - global_position).normalized()
			body.velocity += knockback_dir * knockback
