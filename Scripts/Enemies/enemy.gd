class_name Enemy
extends CharacterBody2D

@export var stats : EnemyStats

@onready var health_component : HealthComponent = $HealthComponent
@onready var ability_component : AbilityComponent = $AbilityComponent
@onready var state_machine : StateMachine = $StateMachine
@onready var navigation_agent : NavigationAgent2D = $NavigationAgent2D

var target : Node2D

func _ready() -> void:
	if stats:
		health_component.max_health = stats.max_hp
		health_component.health = stats.max_hp
		ability_component.setup(stats)

func _physics_process(delta : float) -> void:
	if navigation_agent.is_navigation_finished():
		return
	var next_pos = navigation_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	velocity = direction * stats.move_speed
	move_and_slide()
