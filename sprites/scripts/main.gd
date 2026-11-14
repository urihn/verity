extends Node
# Game flow: input setup, level loading, level-clear -> next level,
# death -> "restart?" prompt (SPACE) -> restart the SAME level, victory.

const LevelScript = preload("res://scripts/level.gd")
const HudScript = preload("res://scripts/hud.gd")
const LevelData = preload("res://scripts/level_data.gd")
const PlayerScript = preload("res://scripts/player.gd")

enum State { PLAYING, LEVEL_CLEAR, DEAD, WON }

var level_index: int = 0
var state: int = State.PLAYING
var level
var hud
var can_restart: bool = false


func _ready() -> void:
	_setup_input()
	hud = HudScript.new()
	add_child(hud)
	_start_level(0)


# ---------------------------------------------------------------- input map (built in code)
func _setup_input() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add_key_action("restart", [KEY_SPACE])
	_add_key_action("attack_line", [KEY_J])
	_add_key_action("attack_burst", [KEY_K])
	_add_mouse_action("attack_line_mouse", MOUSE_BUTTON_LEFT)
	_add_mouse_action("attack_burst_mouse", MOUSE_BUTTON_RIGHT)


func _add_key_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _add_mouse_action(action: String, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


# ---------------------------------------------------------------- levels
func _start_level(index: int) -> void:
	if level != null:
		remove_child(level)   # leaves the tree now, so old nodes can't be found by groups
		level.queue_free()
		level = null

	level_index = index
	can_restart = false

	level = LevelScript.new()
	add_child(level)
	level.build(index)

	level.enemies_changed.connect(_on_enemies_changed)
	level.cleared.connect(_on_level_cleared)
	level.player_died.connect(_on_player_died)
	level.player.hp_changed.connect(hud.set_hp)
	level.player.points_changed.connect(hud.set_points)

	hud.reset(
		index + 1, LevelData.LEVELS.size(), level.enemies_left,
		level.player.hp, PlayerScript.MAX_HP,
		level.player.points, PlayerScript.MAX_POINTS
	)
	state = State.PLAYING


func _on_enemies_changed(remaining: int) -> void:
	hud.set_enemies(remaining)


func _on_level_cleared() -> void:
	if state != State.PLAYING:
		return
	state = State.LEVEL_CLEAR
	level.player.invulnerable = true
	get_tree().call_group("projectiles", "queue_free")

	var last: bool = level_index + 1 >= LevelData.LEVELS.size()
	if last:
		hud.show_message("YOU WIN!", "All %d levels cleared. Verity is a very full hero." % LevelData.LEVELS.size(), "", Color(1.0, 0.9, 0.4))
	else:
		hud.show_message("LEVEL %d CLEAR!" % (level_index + 1), "Get ready for level %d..." % (level_index + 2), "", Color(0.55, 1.0, 0.45))

	await get_tree().create_timer(2.2).timeout
	if state != State.LEVEL_CLEAR:
		return
	if last:
		state = State.WON
		can_restart = true
		hud.set_prompt("PRESS SPACE TO PLAY AGAIN")
	else:
		_start_level(level_index + 1)


func _on_player_died() -> void:
	if state != State.PLAYING:
		return
	state = State.DEAD
	can_restart = false
	hud.show_message(
		"VERITY HAS FALLEN",
		"Would you like to restart level %d?" % (level_index + 1),
		"",
		Color(1.0, 0.4, 0.35)
	)
	await get_tree().create_timer(0.7).timeout   # so a jump-mash doesn't skip the prompt
	if state != State.DEAD:
		return
	can_restart = true
	hud.set_prompt("PRESS SPACE TO RESTART")


func _unhandled_input(event: InputEvent) -> void:
	if not can_restart:
		return
	if event.is_action_pressed("restart") and not event.is_echo():
		if state == State.DEAD:
			_start_level(level_index)      # same level you died on
		elif state == State.WON:
			_start_level(0)
