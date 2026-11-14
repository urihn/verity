extends CanvasLayer
# HUD: HP bar, burger points, attack costs, level / enemy counter and the
# full-screen messages (level clear, "restart?" prompt, victory).

const PlayerScript = preload("res://scripts/player.gd")

const FONT_PATH := "res://fonts/PixelOperator8.ttf"
const FONT_BOLD_PATH := "res://fonts/PixelOperator8-Bold.ttf"

const COL_OK := Color(0.55, 1.0, 0.45)
const COL_DIM := Color(0.6, 0.6, 0.65)
const PIP_ON := Color(1.0, 0.62, 0.15)
const PIP_OFF := Color(0.18, 0.14, 0.14, 0.85)

var font: Font
var font_bold: Font

var hp_fill: ColorRect
var hp_label: Label
var points_label: Label
var pips: Array = []
var line_hint: Label
var burst_hint: Label
var level_label: Label
var enemies_label: Label
var controls_hint: Label

var overlay: Control
var msg_title: Label
var msg_sub: Label
var msg_prompt: Label
var blink_t: float = 0.0


func _ready() -> void:
	layer = 10
	font = load(FONT_PATH)
	font_bold = load(FONT_BOLD_PATH)
	_build()


# ---------------------------------------------------------------- construction
func _label(text: String, pos: Vector2, size_px: int = 8, color: Color = Color(1, 1, 1), bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", font_bold if bold else font)
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	l.add_theme_constant_override("outline_size", 3)
	add_child(l)
	return l


func _centered(text: String, y: float, size_px: int, color: Color, parent: Node, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.position = Vector2(0, y)
	l.size = Vector2(640, size_px + 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", font_bold if bold else font)
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	l.add_theme_constant_override("outline_size", 4)
	parent.add_child(l)
	return l


func _rect(pos: Vector2, size: Vector2, color: Color, parent: Node = null) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if parent == null:
		add_child(r)
	else:
		parent.add_child(r)
	return r


func _build() -> void:
	# --- HP
	hp_label = _label("HP 200/200", Vector2(8, 5), 8, Color(1, 1, 1), true)
	_rect(Vector2(7, 17), Vector2(124, 10), Color(0, 0, 0, 0.75))
	_rect(Vector2(9, 19), Vector2(120, 6), Color(0.25, 0.08, 0.08))
	hp_fill = _rect(Vector2(9, 19), Vector2(120, 6), COL_OK)

	# --- burger points
	var icon := TextureRect.new()
	icon.texture = load("res://sprites/burger.png")
	icon.position = Vector2(8, 32)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	points_label = _label("0/10", Vector2(26, 31), 8, Color(1.0, 0.85, 0.4), true)
	for i in PlayerScript.MAX_POINTS:
		var pip := _rect(Vector2(8 + i * 13, 46), Vector2(11, 7), PIP_OFF)
		pips.append(pip)

	# --- attack hints
	line_hint = _label("[J / L-CLICK] LINE  -3 PTS  30 DMG", Vector2(8, 58), 8, COL_DIM)
	burst_hint = _label("[K / R-CLICK] BURST -2 PTS  20 DMG", Vector2(8, 69), 8, COL_DIM)

	# --- level + enemies (top right)
	level_label = _label("LEVEL 1/3", Vector2(500, 5), 8, Color(1, 1, 1), true)
	level_label.size = Vector2(132, 12)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	enemies_label = _label("ENEMIES 0", Vector2(500, 17), 8, Color(1.0, 0.5, 0.4), true)
	enemies_label.size = Vector2(132, 12)
	enemies_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# --- controls reminder (fades after a few seconds)
	controls_hint = _centered("A/D MOVE   SPACE JUMP   CATCH THE CHEF'S BURGERS TO POWER UP!", 340, 8, Color(1, 1, 1), self)

	# --- full-screen message overlay
	overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false
	add_child(overlay)
	_rect(Vector2(0, 0), Vector2(640, 360), Color(0, 0, 0, 0.62), overlay)
	msg_title = _centered("", 122, 16, Color(1, 1, 1), overlay, true)
	msg_sub = _centered("", 154, 8, Color(0.9, 0.9, 0.95), overlay)
	msg_prompt = _centered("", 186, 8, Color(1.0, 0.9, 0.4), overlay, true)


func _process(delta: float) -> void:
	if overlay.visible and msg_prompt.text != "":
		blink_t += delta
		msg_prompt.modulate.a = 0.55 + 0.45 * sin(blink_t * 6.0)


# ---------------------------------------------------------------- state setters
func reset(level_number: int, level_count: int, enemies: int, hp: int, max_hp: int, points: int, max_points: int) -> void:
	level_label.text = "LEVEL %d/%d" % [level_number, level_count]
	set_enemies(enemies)
	set_hp(hp, max_hp)
	set_points(points, max_points)
	hide_message()
	controls_hint.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(9.0)
	t.tween_property(controls_hint, "modulate:a", 0.0, 1.5)


func set_hp(hp: int, max_hp: int) -> void:
	var f: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	hp_fill.size.x = 120.0 * f
	hp_label.text = "HP %d/%d" % [hp, max_hp]
	if f > 0.5:
		hp_fill.color = COL_OK
	elif f > 0.25:
		hp_fill.color = Color(1.0, 0.8, 0.25)
	else:
		hp_fill.color = Color(1.0, 0.3, 0.25)


func set_points(points: int, max_points: int) -> void:
	points_label.text = "%d/%d" % [points, max_points]
	for i in pips.size():
		pips[i].color = PIP_ON if i < points else PIP_OFF
	var can_line: bool = points >= PlayerScript.LINE_COST
	var can_burst: bool = points >= PlayerScript.BURST_COST
	line_hint.add_theme_color_override("font_color", COL_OK if can_line else COL_DIM)
	burst_hint.add_theme_color_override("font_color", COL_OK if can_burst else COL_DIM)


func set_enemies(n: int) -> void:
	enemies_label.text = "ENEMIES %d" % n


# ---------------------------------------------------------------- messages
func show_message(title: String, sub: String, prompt: String, title_color: Color = Color(1, 1, 1)) -> void:
	msg_title.text = title
	msg_title.add_theme_color_override("font_color", title_color)
	msg_sub.text = sub
	msg_prompt.text = prompt
	msg_prompt.modulate.a = 1.0
	overlay.visible = true


func set_prompt(prompt: String) -> void:
	msg_prompt.text = prompt


func hide_message() -> void:
	overlay.visible = false
