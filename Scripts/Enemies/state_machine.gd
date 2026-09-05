class_name StateMachine
extends Node

var current_state : State
var states : Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is State:
			var key = child.name.to_lower().replace("state", "")
			states[key] = child
			child.state_machine = self
			child.enemy = get_parent()

	var first_state = states.values().front()
	if first_state:
		current_state = first_state
		print("[StateMachine] Initial state: ", current_state.name)
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
		print("[StateMachine] ", current_state.name, " -> ", new_state_name)
		if current_state:
			current_state.exit()
		current_state = new_state
		current_state.enter()
	else:
		print("[StateMachine] Could not find state: '", new_state_name, "' in states: ", states.keys())
