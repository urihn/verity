extends RefCounted
# Small visual-effect helpers (static, so any script can call Fx.beam(...) etc.)

const FONT_PATH := "res://fonts/PixelOperator8.ttf"


class Ring extends Node2D:
	var radius: float = 30.0
	var color: Color = Color(1.0, 0.85, 0.3, 0.9)
	var progress: float = 0.0

	func set_progress(v: float) -> void:
		progress = v
		queue_redraw()

	func _draw() -> void:
		var r: float = radius * clampf(progress, 0.0, 1.0)
		var fade: float = 1.0 - progress
		var line_col := Color(color.r, color.g, color.b, color.a * fade)
		var fill_col := Color(color.r, color.g, color.b, color.a * fade * 0.25)
		draw_circle(Vector2.ZERO, r, fill_col)
		draw_arc(Vector2.ZERO, maxf(r, 0.5), 0.0, TAU, 40, line_col, 2.0)


static func ring(parent: Node, pos: Vector2, radius: float, color: Color, time: float = 0.25) -> void:
	var r := Ring.new()
	r.radius = radius
	r.color = color
	r.position = pos
	r.z_index = 6
	parent.add_child(r)
	var t := r.create_tween()
	t.tween_method(r.set_progress, 0.0, 1.0, time)
	t.tween_callback(r.queue_free)


static func beam(parent: Node, a: Vector2, b: Vector2) -> void:
	var outer := Line2D.new()
	outer.width = 7.0
	outer.default_color = Color(1.0, 0.65, 0.15, 0.55)
	outer.points = PackedVector2Array([a, b])
	outer.z_index = 6
	parent.add_child(outer)
	var inner := Line2D.new()
	inner.width = 3.0
	inner.default_color = Color(1.0, 0.97, 0.7, 1.0)
	inner.points = PackedVector2Array([a, b])
	inner.z_index = 7
	parent.add_child(inner)
	var t1 := outer.create_tween()
	t1.tween_property(outer, "modulate:a", 0.0, 0.2)
	t1.tween_callback(outer.queue_free)
	var t2 := inner.create_tween()
	t2.tween_property(inner, "modulate:a", 0.0, 0.2)
	t2.tween_callback(inner.queue_free)


static func popup(parent: Node, pos: Vector2, text: String, color: Color) -> void:
	var lab := Label.new()
	lab.text = text
	lab.add_theme_font_override("font", load(FONT_PATH))
	lab.add_theme_font_size_override("font_size", 8)
	lab.add_theme_color_override("font_color", color)
	lab.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lab.add_theme_constant_override("outline_size", 3)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.size = Vector2(80, 10)
	lab.position = pos - Vector2(40, 10)
	lab.z_index = 10
	parent.add_child(lab)
	var t := lab.create_tween()
	t.tween_property(lab, "position:y", lab.position.y - 14.0, 0.7)
	t.parallel().tween_property(lab, "modulate:a", 0.0, 0.45).set_delay(0.3)
	t.tween_callback(lab.queue_free)
