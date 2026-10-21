extends Area3D

## Speed boost strip on the track. Gives a temporary boost when driven over.

@export var boost_duration: float = 1.5


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body.has_method("apply_boost"):
		body.apply_boost(boost_duration)
