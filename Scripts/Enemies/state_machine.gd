class_name StateMachine
extends Node

@export var initial_state : State

var current_state : State
var states : Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.enemy = get_parent()
	if initial_state:
		current_state = initial_state
		current_state.enter()

func _process(delta : float) -> void:
	if current_state:
		current_state.process(delta)

func _physics_process(delta : float) -> void:
	if current_state:
		current_state.physics_process(delta)

func transition_to(new_state_name : String) -> void:
	var new_state = states.get(new_state_name.to_lower())
	if new_state and new_state != current_state:
		if current_state:
			current_state.exit()
		current_state = new_state
		current_state.enter()
