extends Area3D

## Place these around the track. Set checkpoint_index in order (0, 1, 2...).
## The finish line checkpoint should have is_finish_line = true.

@export var checkpoint_index: int = 0
@export var is_finish_line: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Checkpoints are on layer 3, detect layer 2 (cars)
	collision_layer = 4  # layer 3
	collision_mask = 2   # layer 2


func _on_body_entered(body: Node3D) -> void:
	if body.has_method("on_checkpoint"):
		body.on_checkpoint(checkpoint_index, is_finish_line)
