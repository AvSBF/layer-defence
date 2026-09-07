extends ProgressBar

@onready var health_component : HealthComponent = $"../HealthComponent"

func _ready() -> void:
	max_value = health_component.max_health
	value = health_component.health
	health_component.health_changed.connect(_on_damage_taken)

func _on_damage_taken(new_health : float):
	value = new_health
	
	var ratio = new_health / max_value
	if ratio >= 0.5:
		modulate = Color.GREEN
	elif ratio >= 0.25:
		modulate = Color.ORANGE
	else:
		modulate = Color.RED
