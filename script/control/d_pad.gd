extends Control

const ACTIONS := ["move_up", "move_down", "move_left", "move_right"]

var _active := false
var _held := {}


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_active = true
			_update(event.position)
		else:
			_release_all()
	elif event is InputEventMouseMotion and _active:
		_update(event.position)


func _update(pos: Vector2) -> void:
	var col := clampi(int(pos.x / (size.x / 3.0)), 0, 2)
	var row := clampi(int(pos.y / (size.y / 3.0)), 0, 2)

	var wanted := {
		"move_left": col == 0,
		"move_right": col == 2,
		"move_up": row == 0,
		"move_down": row == 2,
	}

	for action in ACTIONS:
		if wanted[action] and not _held.get(action, false):
			Input.action_press(action)
			_held[action] = true
		elif not wanted[action] and _held.get(action, false):
			Input.action_release(action)
			_held[action] = false

	_highlight(wanted)


func _highlight(wanted: Dictionary) -> void:
	$Up.modulate = Color(1, 1, 1, 1) if wanted["move_up"] else Color(1, 1, 1, 0.6)
	$Down.modulate = Color(1, 1, 1, 1) if wanted["move_down"] else Color(1, 1, 1, 0.6)
	$Left.modulate = Color(1, 1, 1, 1) if wanted["move_left"] else Color(1, 1, 1, 0.6)
	$Right.modulate = Color(1, 1, 1, 1) if wanted["move_right"] else Color(1, 1, 1, 0.6)


func _release_all() -> void:
	_active = false
	for action in ACTIONS:
		Input.action_release(action)
		_held[action] = false
	_highlight({"move_up": false, "move_down": false, "move_left": false, "move_right": false})


func _exit_tree() -> void:
	_release_all()
