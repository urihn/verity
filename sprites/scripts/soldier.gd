extends Node2D
# Soldier: 50 HP. Stands still and fires a bullet in a STRAIGHT LINE at the spot
# where Verity was at the moment of firing (it does not track him afterwards).

signal died

const Fx = preload("res://scripts/fx.gd")
const Projectile = preload("res://scripts/projectile.gd")

const MAX_HP := 50
const BULLET_DAMAGE := 10
const SPRITE_SIZE := Vector2(22, 28)
const MUZZLE := Vector2(11, -17)   # gun barrel tip, relative to the feet, facing right

var hp: int = MAX_HP
var dead: bool = false
var fire_interval: float = 1.8
var bullet_speed: float = 170.0
var detect_range: float = 250.0
var timer: float = 1.0
var was_in_range: bool = false
var facing: int = 1
var flash: float = 0.0
var sprite: Sprite2D


func _ready() -> void:
	add_to_group("enemies")
	sprite = Sprite2D.new()
	sprite.texture = load("res://sprites/soldier.png")
	sprite.centered = false
	sprite.position = Vector2(-SPRITE_SIZE.x / 2.0, -SPRITE_SIZE.y)
	add_child(sprite)
	timer = randf_range(0.6, 1.4)


func hit_rect() -> Rect2:
	return Rect2(global_position + Vector2(-8.0, -26.0), Vector2(16.0, 26.0))


func take_damage(amount: int) -> void:
	if dead:
		return
	hp -= amount
	flash = 0.12
	sprite.modulate = Color(2.5, 2.5, 2.5, 1.0)
	queue_redraw()
	Fx.popup(get_parent(), global_position + Vector2(0, -32), str(amount), Color(1, 1, 1))
	if hp <= 0:
		_die()


func _die() -> void:
	dead = true
	remove_from_group("enemies")
	queue_redraw()
	died.emit()
	Fx.ring(get_parent(), global_position + Vector2(0, -14), 18.0, Color(1.0, 0.4, 0.2, 0.9), 0.3)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.45)
	t.tween_callback(queue_free)


func _draw() -> void:
	if dead or hp >= MAX_HP:
		return
	var w := 20.0
	draw_rect(Rect2(-w / 2.0 - 1.0, -SPRITE_SIZE.y - 6.0, w + 2.0, 4.0), Color(0, 0, 0, 0.8))
	draw_rect(Rect2(-w / 2.0, -SPRITE_SIZE.y - 5.0, w * float(hp) / float(MAX_HP), 2.0), Color(0.9, 0.2, 0.2, 1.0))


func _physics_process(delta: float) -> void:
	if dead:
		return

	if flash > 0.0:
		flash -= delta
		if flash <= 0.0:
			sprite.modulate = Color(1, 1, 1, 1)

	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null or player.dead:
		return

	var target: Vector2 = player.center()
	facing = 1 if target.x >= global_position.x else -1
	sprite.flip_h = facing < 0
	var muzzle: Vector2 = global_position + Vector2(MUZZLE.x * facing, MUZZLE.y)

	var in_range: bool = muzzle.distance_to(target) <= detect_range
	if in_range and not was_in_range:
		timer = maxf(timer, 0.9)  # short warning before the first shot
	was_in_range = in_range
	if not in_range:
		return

	timer -= delta
	if timer > 0.0:
		return
	timer = fire_interval * randf_range(0.85, 1.15)

	# must have a clear line to the target, otherwise the shot would just hit a wall
	var query := PhysicsRayQueryParameters2D.create(muzzle, target, 1)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		return

	_fire(muzzle, target)


func _fire(muzzle: Vector2, target: Vector2) -> void:
	# Straight line toward where the player IS RIGHT NOW. The bullet never steers.
	var dir: Vector2 = (target - muzzle).normalized()
	var b := Projectile.new()
	b.setup(muzzle + dir * 3.0, dir, bullet_speed, false)
	b.damage = BULLET_DAMAGE
	get_parent().add_child(b)
	Fx.ring(get_parent(), muzzle, 7.0, Color(1.0, 0.85, 0.4, 0.9), 0.12)
