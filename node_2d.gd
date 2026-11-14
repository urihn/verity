extends Node2D

@export var platform_scene: PackedScene # Drag your HazardPlatform.tscn here in the Inspector
@export var spawn_interval: float = 0.5
@export var move_direction: Vector2 = Vector2.RIGHT # Direction the platform should move

var timer: float = 0.0

func _process(delta: float) -> void:
	timer += delta
	if timer >= spawn_interval:
		timer = 0.0
		_spawn_platform()

func _spawn_platform() -> void:
	if not platform_scene:
		return
	
	# Instantiate the platform scene
	var platform = platform_scene.instantiate()
	
	# Set its starting position to the spawner's position
	platform.global_position = global_position
	
	# Pass the movement direction to the platform script
	platform.move_direction = move_direction
	
	# Add it to the main scene tree (e.g., as a child of current scene or root)
	get_tree().current_scene.add_child(platform)
