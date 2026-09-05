class_name Enemy
extends CharacterBody2D

@export var stats : EnemyStats

@onready var health_component : HealthComponent = $HealthComponent
@onready var ability_component : AbilityComponent = $AbilityComponent
@onready var state_machine : StateMachine = $StateMachine

var target : Node2D

func _ready() -> void:
	if stats:
		health_component.max_health = stats.max_hp
		health_component.health = stats.max_hp

func _setup_navigation() -> void:
	var nav = get_node_or_null("EnemyNavigation")
	if nav:
		var graph = get_tree().get_first_node_in_group("platform_graph")
		if graph:
			nav.setup(graph, target)

func _physics_process(delta : float) -> void:
	if not is_on_floor():
		velocity.y += 980 * delta
	move_and_slide()
