extends CharacterBody2D
# Verity: a platforming blob.
#  - starts with 200 HP, each soldier bullet takes 10
#  - every burger from the chef = +1 point (max 10) and he gets fatter:
#       0-2 pts: design 1 | 3-5: design 2 | 6-8: design 3 | 9-10: design 4
#  - points are ammo:
#       LINE  attack (J / left click)  : 3 pts, 30 dmg to every enemy in a straight line
#       BURST attack (K / right click) : 2 pts, 20 dmg to every enemy within 30 px

signal hp_changed(hp: int, max_hp: int)
signal points_changed(points: int, max_points: int)
signal died

const Fx = preload("res://scripts/fx.gd")

const MAX_HP := 200
const MAX_POINTS := 10

const LINE_COST := 3
const LINE_DAMAGE := 30
const LINE_RANGE := 340.0
const LINE_THICKNESS := 5.0

const BURST_COST := 2
const BURST_DAMAGE := 20
const BURST_RADIUS := 30.0

const ATTACK_COOLDOWN := 0.35

const SPEED := 115.0
const ACCEL := 900.0
const FRICTION := 1100.0
const JUMP_VELOCITY := -340.0
const GRAVITY := 950.0
const MAX_FALL := 520.0

var hp: int = MAX_HP
var points: int = 0
var stage: int = 0
var dead: bool = false
var invulnerable: bool = false
var facing: float = 1.0
var cooldown: float = 0.0
var coyote: float = 0.0
var flash: float = 0.0
var shake: float = 0.0
var anim_t: float = 0.0

var level_bounds: Rect2i = Rect2i(0, 0, 1000, 368)

var textures: Array = []
var visual: Node2D
var sprite: Sprite2D
var body_shape: CollisionShape2D
var camera: Camera2D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 4   # nothing needs to collide *with* Verity
	collision_mask = 3    # solid terrain (1) + one-way platforms (2)

	for i in range(1, 5):
		textures.append(load("res://sprites/verity_%d.png" % i))

	visual = Node2D.new()
	add_child(visual)
	sprite = Sprite2D.new()
	sprite.centered = false
	visual.add_child(sprite)

	body_shape = CollisionShape2D.new()
	body_shape.shape = RectangleShape2D.new()
	add_child(body_shape)

	camera = Camera2D.new()
	camera.position = Vector2(0, -26)
	camera.limit_left = level_bounds.position.x
	camera.limit_top = level_bounds.position.y
	camera.limit_right = level_bounds.end.x
	camera.limit_bottom = level_bounds.end.y
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)
	camera.make_current()

	_apply_stage()


# ---------------------------------------------------------------- helpers
func _tex() -> Texture2D:
	return textures[stage]


func _w() -> float:
	return float(_tex().get_width())


func _h() -> float:
	return float(_tex().get_height())


func center() -> Vector2:
	return global_position + Vector2(0.0, -_h() / 2.0)


func hit_rect() -> Rect2:
	return Rect2(global_position + Vector2(-_w() / 2.0, -_h()), Vector2(_w(), _h()))


func _apply_stage() -> void:
	var tex: Texture2D = _tex()
	sprite.texture = tex
	sprite.position = Vector2(-_w() / 2.0, -_h())
	var rs: RectangleShape2D = body_shape.shape
	rs.size = Vector2(_w() - 4.0, _h() - 2.0)
	body_shape.position = Vector2(0.0, -rs.size.y / 2.0)


# ---------------------------------------------------------------- damage / points
func take_damage(amount: int) -> void:
	if dead or invulnerable:
		return
	hp = maxi(hp - amount, 0)
	flash = 0.15
	shake = 1.0
	hp_changed.emit(hp, MAX_HP)
	Fx.popup(get_parent(), global_position + Vector2(0.0, -_h() - 4.0), "-%d" % amount, Color(1.0, 0.35, 0.3))
	if hp <= 0:
		_die()


func eat_burger() -> void:
	if dead:
		return
	if points >= MAX_POINTS:
		Fx.popup(get_parent(), global_position + Vector2(0.0, -_h() - 4.0), "FULL!", Color(1.0, 0.9, 0.4))
		return
	points += 1
	_after_points_change()
	Fx.popup(get_parent(), global_position + Vector2(0.0, -_h() - 4.0), "+1", Color(0.5, 1.0, 0.4))
	Fx.ring(get_parent(), center(), 14.0, Color(0.6, 1.0, 0.4, 0.8), 0.2)


func _spend(cost: int) -> void:
	points -= cost
	_after_points_change()


func _after_points_change() -> void:
	# fatter every 3 points, 4 designs total
	stage = mini(floori(points / 3.0), 3)
	_apply_stage()
	points_changed.emit(points, MAX_POINTS)


func _die() -> void:
	dead = true
	died.emit()
	var t := create_tween()
	t.tween_property(visual, "scale", Vector2(1.5, 0.35), 0.25)
	t.parallel().tween_property(visual, "modulate", Color(0.45, 0.45, 0.5, 0.85), 0.25)


# ---------------------------------------------------------------- attacks
func _no_points(cost: int) -> void:
	cooldown = 0.2
	Fx.popup(get_parent(), global_position + Vector2(0.0, -_h() - 4.0), "NEED %d" % cost, Color(1.0, 0.7, 0.3))


func _line_attack(dir: Vector2) -> void:
	if points < LINE_COST:
		_no_points(LINE_COST)
		return
	_spend(LINE_COST)
	cooldown = ATTACK_COOLDOWN
	if dir.length() < 0.1:
		dir = Vector2(facing, 0.0)
	dir = dir.normalized()

	var origin: Vector2 = center()
	var target: Vector2 = origin + dir * LINE_RANGE

	# walls stop the beam, enemies do not (it pierces)
	var query := PhysicsRayQueryParameters2D.create(origin, target, 1)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		target = hit["position"]

	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead:
			continue
		var r: Rect2 = e.hit_rect().grow(LINE_THICKNESS)
		if _segment_hits_rect(origin, target, r):
			e.take_damage(LINE_DAMAGE)

	Fx.beam(get_parent(), origin, target)


func _burst_attack() -> void:
	if points < BURST_COST:
		_no_points(BURST_COST)
		return
	_spend(BURST_COST)
	cooldown = ATTACK_COOLDOWN

	var c: Vector2 = center()
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead:
			continue
		var r: Rect2 = e.hit_rect()
		var closest := Vector2(clampf(c.x, r.position.x, r.end.x), clampf(c.y, r.position.y, r.end.y))
		if closest.distance_to(c) <= BURST_RADIUS:
			e.take_damage(BURST_DAMAGE)

	Fx.ring(get_parent(), c, BURST_RADIUS, Color(1.0, 0.8, 0.25, 0.95), 0.28)


# segment (a -> b) versus axis-aligned rectangle, slab method
func _segment_hits_rect(a: Vector2, b: Vector2, r: Rect2) -> bool:
	var d: Vector2 = b - a
	var tmin: float = 0.0
	var tmax: float = 1.0
	for axis in 2:
		var a_i: float = a[axis]
		var d_i: float = d[axis]
		var lo: float = r.position[axis]
		var hi: float = r.position[axis] + r.size[axis]
		if absf(d_i) < 0.0001:
			if a_i < lo or a_i > hi:
				return false
		else:
			var t1: float = (lo - a_i) / d_i
			var t2: float = (hi - a_i) / d_i
			if t1 > t2:
				var swap: float = t1
				t1 = t2
				t2 = swap
			tmin = maxf(tmin, t1)
			tmax = minf(tmax, t2)
			if tmin > tmax:
				return false
	return true


# ---------------------------------------------------------------- main loop
func _physics_process(delta: float) -> void:
	if cooldown > 0.0:
		cooldown -= delta

	# hit flash
	if not dead:
		if flash > 0.0:
			flash -= delta
			var on: bool = int(flash * 40.0) % 2 == 0
			visual.modulate = Color(1.0, 0.45, 0.45, 1.0) if on else Color(1.0, 1.0, 1.0, 1.0)
		else:
			visual.modulate = Color(1.0, 1.0, 1.0, 1.0)

	# small camera shake after taking a hit
	shake = maxf(shake - delta * 4.0, 0.0)
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake * 2.5

	# gravity
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)

	if dead:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		move_and_slide()
		return

	# horizontal movement
	var dir: float = Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		facing = signf(dir)
		velocity.x = move_toward(velocity.x, dir * SPEED, ACCEL * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	# jumping (with a little coyote time and variable height)
	if is_on_floor():
		coyote = 0.1
	else:
		coyote -= delta
	if Input.is_action_just_pressed("jump") and coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		coyote = 0.0
	if Input.is_action_just_released("jump") and velocity.y < -140.0:
		velocity.y = -140.0

	move_and_slide()

	# attacks
	if cooldown <= 0.0:
		if Input.is_action_just_pressed("attack_line"):
			_line_attack(Vector2(facing, 0.0))
		elif Input.is_action_just_pressed("attack_line_mouse"):
			_line_attack(get_global_mouse_position() - center())
		elif Input.is_action_just_pressed("attack_burst") or Input.is_action_just_pressed("attack_burst_mouse"):
			_burst_attack()

	_animate(delta)


func _animate(delta: float) -> void:
	anim_t += delta
	var target := Vector2.ONE
	if not is_on_floor():
		var stretch: float = clampf(absf(velocity.y) / 1500.0, 0.0, 0.18)
		target = Vector2(1.0 - stretch, 1.0 + stretch)
	elif absf(velocity.x) > 10.0:
		var s: float = sin(anim_t * 20.0)
		target = Vector2(1.0 + 0.05 * s, 1.0 - 0.07 * s)
	else:
		var b: float = sin(anim_t * 3.0) * 0.025
		target = Vector2(1.0 - b, 1.0 + b)
	visual.scale = visual.scale.lerp(target, 1.0 - exp(-22.0 * delta))
