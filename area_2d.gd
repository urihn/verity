extends Area2D

@export var speed: float = 300.0
var move_direction: Vector2 = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	# Move continuously in the assigned direction
	global_position += move_direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# Call a death/reset function on your player
		if body.has_method("die"):
			body.die()
		queue_free() # Destroy the platform upon hitting the player
