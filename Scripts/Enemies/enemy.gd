class_name Enemy
extends CharacterBody2D

@export var stats : EnemyStats

@onready var health_component : HealthComponent = $HealthComponent
@onready var ability_component : AbilityComponent = $AbilityComponent
@onready var state_machine : StateMachine = $StateMachine

var target : Node2D
var speed_variation : float = 0.0
var dash_active : bool = false
var dash_timer : float = 0.0
var dash_direction : float = 0.0

func _ready() -> void:
	speed_variation = randf_range(-25, 25)
	if stats:
		health_component.max_health = stats.max_hp
		health_component.health = stats.max_hp
		for ability in stats.abilities:
			ability_component.add_ability(ability)

func start_dash(dir : float) -> void:
	for ability in ability_component.abilities:
		if ability.ability_type == EnemyAbility.AbilityType.DASH and ability_component.can_use_ability(ability):
			ability_component.use_ability(ability)
			dash_active = true
			dash_timer = ability.duration
			dash_direction = dir
			return

func _physics_process(delta : float) -> void:
	if not is_on_floor():
		velocity.y += 980 * delta

	if dash_active:
		dash_timer -= delta
		velocity.x = dash_direction * stats.dash_force
		if dash_timer <= 0:
			dash_active = false

	move_and_slide()
