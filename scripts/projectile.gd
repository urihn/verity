extends Node2D
# One script for both soldier bullets and chef burgers.
#  - bullet: flies in a straight line, hurts Verity (10 damage)
#  - burger: flies in a straight line, feeds Verity (+1 point)
# Both stop when they hit the level's solid terrain.

const Fx = preload("res://scripts/fx.gd")

var velocity: Vector2 = Vector2.ZERO
var damage: int = 10
var is_burger: bool = false
var radius: float = 3.0
var life: float = 5.0
var spin: float = 0.0


func setup(pos: Vector2, dir: Vector2, speed: float, burger: bool) -> void:
	position = pos
	velocity = dir.normalized() * speed
	is_burger = burger
	radius = 6.0 if burger else 3.0
	spin = randf_range(-9.0, 9.0)


func _ready() -> void:
	add_to_group("projectiles")
	z_index = 4
	if is_burger:
		var s := Sprite2D.new()
		s.texture = load("res://sprites/burger.png")
		add_child(s)


func _draw() -> void:
	if is_burger:
		return
	# bullet: glowing tracer pointing along its flight direction
	var d := velocity.normalized()
	draw_line(-d * 7.0, Vector2.ZERO, Color(1.0, 0.45, 0.1, 0.8), 2.0)
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.55, 0.15, 1.0))
	draw_circle(Vector2.ZERO, 1.6, Color(1.0, 0.95, 0.6, 1.0))


func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return

	if is_burger:
		rotation += spin * delta

	var from: Vector2 = global_position
	var to: Vector2 = from + velocity * delta

	# solid terrain (physics layer 1) stops the shot
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var spark_col := Color(1.0, 0.8, 0.4, 0.9) if not is_burger else Color(0.9, 0.6, 0.3, 0.9)
		Fx.ring(get_parent(), hit["position"], 6.0, spark_col, 0.15)
		queue_free()
		return

	global_position = to

	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null or player.dead:
		return
	var r: Rect2 = player.hit_rect()
	var closest := Vector2(
		clampf(global_position.x, r.position.x, r.end.x),
		clampf(global_position.y, r.position.y, r.end.y)
	)
	if closest.distance_to(global_position) <= radius:
		if is_burger:
			player.eat_burger()
		else:
			player.take_damage(damage)
		queue_free()
