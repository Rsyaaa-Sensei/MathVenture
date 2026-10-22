extends Node2D

const MIN_ZOOM: float = 1.5

@onready var floor_layer: TileMapLayer = $Floor
@onready var player: CharacterBody2D = %Player
@onready var cam: Camera2D = %Player/Camera2D
@onready var screen_fade: ColorRect = $InteractionUI/ScreenFade
@onready var leave_button: Button = $InteractionUI/LeaveHouseButton

var is_transitioning: bool = false


func _ready() -> void:
	_setup_player_and_camera()

	screen_fade.color = Color(0, 0, 0, 1)
	screen_fade.visible = true
	screen_fade.mouse_filter = Control.MOUSE_FILTER_STOP

	if leave_button and not leave_button.pressed.is_connected(
		_on_leave_button_pressed
	):
		leave_button.pressed.connect(_on_leave_button_pressed)

	get_viewport().size_changed.connect(_limit_camera_to_room)

	fade_in(0.5)


func _setup_player_and_camera() -> void:
	if not is_instance_valid(player):
		return

	if is_instance_valid(cam):
		cam.enabled = true
		cam.make_current()
		cam.position_smoothing_enabled = false
		cam.limit_smoothed = false

	if SceneTransition.interior_return_position != Vector2.ZERO:
		player.global_position = SceneTransition.interior_return_position
		SceneTransition.interior_return_position = Vector2.ZERO
	else:
		var door_shape: Node2D = get_node_or_null(
			"InteriorDoorArea/CollisionShape2D"
		)

		if door_shape:
			player.global_position = (
				door_shape.global_position + Vector2(0, -80)
			)

			if "last_direction" in player:
				player.last_direction = Vector2.UP

	_limit_camera_to_room()


func _limit_camera_to_room() -> void:
	if not is_instance_valid(floor_layer) or not is_instance_valid(cam):
		return
	if not floor_layer.tile_set:
		return

	var rect: Rect2i = floor_layer.get_used_rect()
	if rect.size == Vector2i.ZERO:
		return

	# Ukuran tile dalam koordinat dunia (dikali skala layer)
	var tile_size: Vector2 = (
		Vector2(floor_layer.tile_set.tile_size) * floor_layer.global_scale.abs()
	)

	# Sudut luar area tile yang digunakan
	var first_cell: Vector2 = floor_layer.to_global(
		floor_layer.map_to_local(rect.position)
	)
	var last_cell: Vector2 = floor_layer.to_global(
		floor_layer.map_to_local(rect.end - Vector2i.ONE)
	)

	var left: float = minf(first_cell.x, last_cell.x) - tile_size.x / 2.0
	var right: float = maxf(first_cell.x, last_cell.x) + tile_size.x / 2.0
	var top: float = minf(first_cell.y, last_cell.y) - tile_size.y / 2.0
	var bottom: float = maxf(first_cell.y, last_cell.y) + tile_size.y / 2.0

	var viewport_size: Vector2 = get_viewport_rect().size
	var room_size := Vector2(right - left, bottom - top)

	# Zoom otomatis: ruangan harus memenuhi layar (tanpa area hijau di luar lantai)
	var fit_zoom: float = maxf(
		viewport_size.x / room_size.x,
		viewport_size.y / room_size.y
	)
	var z: float = maxf(MIN_ZOOM, fit_zoom)
	cam.zoom = Vector2(z, z)

	var half_view: Vector2 = viewport_size / (2.0 * cam.zoom)

	cam.limit_left = floori(left)
	cam.limit_right = ceili(right)
	cam.limit_top = floori(top)
	cam.limit_bottom = ceili(bottom)

	# Jika ruangan masih lebih kecil dari layar di salah satu sumbu, pusatkan
	if room_size.x <= half_view.x * 2.0:
		var cx: float = (left + right) / 2.0
		cam.limit_left = floori(cx - half_view.x)
		cam.limit_right = ceili(cx + half_view.x)

	if room_size.y <= half_view.y * 2.0:
		var cy: float = (top + bottom) / 2.0
		cam.limit_top = floori(cy - half_view.y)
		cam.limit_bottom = ceili(cy + half_view.y)

	cam.enabled = true
	cam.make_current()


# ANIMASI FADE
func fade_in(duration: float = 0.5) -> void:
	screen_fade.visible = true
	screen_fade.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()
	tween.tween_property(screen_fade, "color:a", 0.0, duration)

	await tween.finished

	screen_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_fade.visible = false


func fade_out(duration: float = 0.5) -> void:
	screen_fade.visible = true
	screen_fade.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()
	tween.tween_property(screen_fade, "color:a", 1.0, duration)

	await tween.finished


# TOMBOL KELUAR RUMAH
func _on_leave_button_pressed() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	leave_button.disabled = true

	if is_instance_valid(player):
		player.set_physics_process(false)
		player.velocity = Vector2.ZERO

	await fade_out(0.5)

	get_tree().change_scene_to_file(
		"res://scenes/world/world.tscn"
	)
