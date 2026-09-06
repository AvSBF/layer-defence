extends Node2D

@onready var controller : CharacterBody2D = $".."
@onready var initial_x_offset

var looking_left : bool = false

func _ready():
	initial_x_offset = abs(position.x)

func _process(delta: float) -> void:
	looking_left = controller.get_meta("looking_left", false)
	position.x = -initial_x_offset if looking_left else initial_x_offset
	scale.x = -1 if looking_left else 1
