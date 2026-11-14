extends Node2D
# The chef is Verity's ally. He keeps throwing burgers at Verity, but his aim is
# terrible: every throw is rotated by a large random error, so most burgers miss.

const Projectile = preload("res://scripts/projectile.gd")

const SPRITE_SIZE := Vector2(25, 32)

var throw_interval: float = 0.9
var aim_error_deg: float = 20.0     # standard deviation of the aim error, in degrees
var throw_speed: float = 150.0
var throw_range: float = 520.0
var timer: float = 0.8
var t: float = 0.0
var sprite: Sprite2D


func _ready() -> void:
	add_to_group("allies")
	sprite = Sprite2D.new()
	sprite.texture = load("res://sprites/chef.png")
	sprite.centered = false
	sprite.position = Vector2(-SPRITE_SIZE.x / 2.0, -SPRITE_SIZE.y)
	add_child(sprite)


func _physics_process(delta: float) -> void:
	t += delta
	sprite.position.y = -SPRITE_SIZE.y + roundf(sin(t * 4.0) * 0.8)

	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null or player.dead:
		return

	var origin: Vector2 = global_position + Vector2(0, -20)
	var target: Vector2 = player.center()
	sprite.flip_h = target.x < global_position.x

	timer -= delta
	if timer > 0.0:
		return
	if origin.distance_to(target) > throw_range:
		return
	timer = throw_interval * randf_range(0.8, 1.25)

	# aim at Verity... then ruin it with a big random angle error
	var base_dir: Vector2 = (target - origin).normalized()
	var err: float = deg_to_rad(randfn(0.0, aim_error_deg))
	var dir: Vector2 = base_dir.rotated(err)

	var burger := Projectile.new()
	burger.setup(origin + dir * 12.0, dir, throw_speed, true)
	get_parent().add_child(burger)
