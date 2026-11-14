extends Node2D
# Builds one level from scripts/level_data.gd: terrain, scenery, sky, soldiers, chef, Verity.

signal enemies_changed(remaining: int)
signal cleared
signal player_died

const LevelData = preload("res://scripts/level_data.gd")
const PlayerScript = preload("res://scripts/player.gd")
const SoldierScript = preload("res://scripts/soldier.gd")
const ChefScript = preload("res://scripts/chef.gd")

const TILE := 16

# more enemies per level (see level_data.gd) AND they get a bit nastier
const SOLDIER_INTERVAL := [2.0, 1.7, 1.45]   # seconds between shots
const SOLDIER_SPEED := [165.0, 185.0, 205.0]  # bullet speed, px/s
const CHEF_INTERVAL := [0.9, 0.8, 0.7]        # the chef throws a little faster each level

# [top tile, body tile] in world_tileset.png (col, row), one pair per theme
const THEME_TILES := [
	[Vector2i(0, 0), Vector2i(0, 1)],   # grass
	[Vector2i(2, 0), Vector2i(2, 1)],   # sand
	[Vector2i(8, 0), Vector2i(8, 1)],   # dark stone
]
# row of platforms.png used per theme
const THEME_PLATFORM_ROW := [0, 1, 3]
# sky colour bands (top -> bottom)
const THEME_SKY := [
	[Color(0.33, 0.58, 0.9), Color(0.46, 0.7, 0.93), Color(0.6, 0.8, 0.95), Color(0.75, 0.88, 0.96)],
	[Color(0.55, 0.3, 0.45), Color(0.85, 0.45, 0.4), Color(0.97, 0.62, 0.38), Color(0.99, 0.8, 0.5)],
	[Color(0.06, 0.07, 0.18), Color(0.1, 0.11, 0.26), Color(0.16, 0.15, 0.34), Color(0.24, 0.2, 0.42)],
]

# scenery: name -> source rect in world_tileset.png (drawn standing on the ground)
const DECOR := {
	"tree": Rect2(0, 48, 16, 48),
	"tree_o": Rect2(80, 48, 16, 48),
	"tree_t": Rect2(96, 48, 16, 48),
	"bush": Rect2(16, 80, 16, 16),
	"mush_r": Rect2(112, 80, 16, 16),
	"mush_o": Rect2(112, 96, 16, 16),
	"mush_p": Rect2(112, 112, 16, 16),
	"mush_t": Rect2(112, 128, 16, 16),
	"sign": Rect2(128, 48, 16, 16),
}

var level_index: int = 0
var data: Dictionary = {}
var tileset: Texture2D
var platform_tex: Texture2D
var solid_cells: Dictionary = {}
var enemies_left: int = 0
var player


func build(index: int) -> void:
	level_index = index
	data = LevelData.LEVELS[index]
	tileset = load("res://sprites/world_tileset.png")
	platform_tex = load("res://sprites/platforms.png")

	_build_sky()
	_build_collision()
	_spawn_chef()
	_spawn_soldiers()
	_spawn_player()
	queue_redraw()


# ---------------------------------------------------------------- sky
func _build_sky() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	var view: Vector2 = get_viewport_rect().size
	var bands: Array = THEME_SKY[data["theme"]]
	var n: int = bands.size()
	var band_h: float = view.y / float(n)
	for i in n:
		var rect := ColorRect.new()
		rect.color = bands[i]
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.position = Vector2(-view.x, i * band_h)
		rect.size = Vector2(view.x * 3.0, band_h + 1.0)
		layer.add_child(rect)


# ---------------------------------------------------------------- collision
func _build_collision() -> void:
	var cols: int = data["cols"]
	var rows: int = data["rows"]

	# solid terrain: physics layer 1 (blocks Verity AND shots)
	var solid := StaticBody2D.new()
	solid.collision_layer = 1
	solid.collision_mask = 0
	add_child(solid)

	for s in data["solid"]:
		var x: int = s[0]
		var y: int = s[1]
		var w: int = s[2]
		var h: int = s[3]
		_add_box(solid, Vector2((x + w / 2.0) * TILE, (y + h / 2.0) * TILE), Vector2(w * TILE, h * TILE), false)
		for cx in range(x, x + w):
			for cy in range(y, y + h):
				solid_cells[Vector2i(cx, cy)] = true

	# invisible walls at both ends of the level
	var wall_h: float = rows * TILE + 800.0
	_add_box(solid, Vector2(-8.0, rows * TILE / 2.0), Vector2(16.0, wall_h), false)
	_add_box(solid, Vector2(cols * TILE + 8.0, rows * TILE / 2.0), Vector2(16.0, wall_h), false)

	# one-way platforms: physics layer 2 (Verity stands on them; shots fly through)
	var oneway := StaticBody2D.new()
	oneway.collision_layer = 2
	oneway.collision_mask = 0
	add_child(oneway)
	for p in data["plat"]:
		var px: int = p[0]
		var py: int = p[1]
		var pw: int = p[2]
		_add_box(oneway, Vector2((px + pw / 2.0) * TILE, py * TILE + 3.0), Vector2(pw * TILE, 6.0), true)


func _add_box(body: StaticBody2D, pos: Vector2, size: Vector2, one_way: bool) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = pos
	cs.one_way_collision = one_way
	body.add_child(cs)


# ---------------------------------------------------------------- spawning
func _feet(tile: Array) -> Vector2:
	return Vector2(tile[0] * TILE + TILE / 2.0, tile[1] * TILE)


func _spawn_chef() -> void:
	var chef := ChefScript.new()
	chef.position = _feet(data["chef"])
	chef.throw_interval = CHEF_INTERVAL[level_index]
	add_child(chef)


func _spawn_soldiers() -> void:
	for s in data["soldiers"]:
		var sol := SoldierScript.new()
		sol.position = _feet(s)
		sol.fire_interval = SOLDIER_INTERVAL[level_index]
		sol.bullet_speed = SOLDIER_SPEED[level_index]
		sol.died.connect(_on_soldier_died)
		add_child(sol)
		enemies_left += 1


func _spawn_player() -> void:
	player = PlayerScript.new()
	player.position = _feet(data["player"])
	player.level_bounds = Rect2i(0, 0, data["cols"] * TILE, data["rows"] * TILE)
	player.died.connect(_on_player_died)
	add_child(player)


func _on_soldier_died() -> void:
	enemies_left -= 1
	enemies_changed.emit(enemies_left)
	if enemies_left <= 0:
		cleared.emit()


func _on_player_died() -> void:
	player_died.emit()


# ---------------------------------------------------------------- drawing
func _draw() -> void:
	if data.is_empty():
		return
	var theme: int = data["theme"]

	# scenery (behind everything)
	for d in data["decor"]:
		var decor_name: String = d[0]
		var src: Rect2 = DECOR[decor_name]
		var pos := Vector2(d[1] * TILE, d[2] * TILE - src.size.y)
		draw_texture_rect_region(tileset, Rect2(pos, src.size), src)

	# terrain tiles
	var tiles: Array = THEME_TILES[theme]
	for cell in solid_cells:
		var above := Vector2i(cell.x, cell.y - 1)
		var tile: Vector2i = tiles[0] if not solid_cells.has(above) else tiles[1]
		var src := Rect2(tile.x * TILE, tile.y * TILE, TILE, TILE)
		draw_texture_rect_region(tileset, Rect2(cell.x * TILE, cell.y * TILE, TILE, TILE), src)

	# floating platforms (each strip is 3 tiles wide)
	var row: int = THEME_PLATFORM_ROW[theme]
	for p in data["plat"]:
		var total: int = p[2] * TILE
		var offset: int = 0
		while offset < total:
			var seg: int = mini(48, total - offset)
			var dst := Rect2(p[0] * TILE + offset, p[1] * TILE, seg, 9)
			var psrc := Rect2(0, row * 16, seg, 9)
			draw_texture_rect_region(platform_tex, dst, psrc)
			offset += 48
