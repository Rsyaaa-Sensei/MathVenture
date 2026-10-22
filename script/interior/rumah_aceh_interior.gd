extends Node2D

const MIN_ZOOM: float = 1.0
const LEVEL_INTRO_SCENE := "res://scenes/levelintro/level_intro.tscn"

@onready var floor_node: Node2D = $Floor
@onready var player: CharacterBody2D = %Player
@onready var cam: Camera2D = %Player/Camera2D
@onready var screen_fade: ColorRect = $InteractionUI/ScreenFade
@onready var leave_button: Button = get_node_or_null(
	"InteractionUI/LeaveHouseButton"
) as Button

var is_transitioning: bool = false


func _ready() -> void:
	# Scene ini khusus Level 2, jadi pakai level 2 bila belum ada pilihan dari peta.
	if not get_tree().has_meta("selected_level"):
		get_tree().set_meta("selected_level", 2)

	_setup_player_and_camera()

	screen_fade.color = Color(0, 0, 0, 1)
	screen_fade.visible = true
	screen_fade.mouse_filter = Control.MOUSE_FILTER_STOP

	if leave_button and not leave_button.pressed.is_connected(
		_on_leave_button_pressed
	):
		leave_button.pressed.connect(_on_leave_button_pressed)

	get_viewport().size_changed.connect(_limit_camera_to_room)

	await fade_in(0.5)

	# Kartu intro level (LEVEL 2 — RUMOH ACEH, Aceh) hanya sekali per masuk level.
	_show_level_intro()


func _setup_player_and_camera() -> void:
	if not is_instance_valid(player):
		return

	if is_instance_valid(cam):
		cam.enabled = true
		cam.make_current()
		cam.position_smoothing_enabled = false
		cam.limit_smoothed = false

	# Kembali dari mini-game 3D: pemain muncul lagi di dekat peti.
	if (
		SceneTransition.pending_room_return
		and SceneTransition.interior_return_position != Vector2.ZERO
	):
		player.global_position = SceneTransition.interior_return_position
		SceneTransition.pending_room_return = false
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

		SceneTransition.pending_room_return = false
		SceneTransition.interior_return_position = Vector2.ZERO

	_limit_camera_to_room()


func _limit_camera_to_room() -> void:
	if not is_instance_valid(floor_node) or not is_instance_valid(cam):
		return

	var room: Rect2 = _room_rect()
	if room.size == Vector2.ZERO:
		return

	var viewport_size: Vector2 = get_viewport_rect().size

	# Zoom minimal MIN_ZOOM. Zoom-in hanya bila ruangan lebih kecil dari layar,
	# sehingga ruangan tetap mengisi layar tanpa area kosong.
	var fit_zoom: float = maxf(
		viewport_size.x / room.size.x,
		viewport_size.y / room.size.y
	)
	var z: float = maxf(MIN_ZOOM, fit_zoom)
	cam.zoom = Vector2(z, z)

	var half_view: Vector2 = viewport_size / (2.0 * z)

	# Batas kamera = tepi ruangan (kamera tidak boleh melihat ke luar ruangan).
	cam.limit_left = floori(room.position.x)
	cam.limit_right = ceili(room.position.x + room.size.x)
	cam.limit_top = floori(room.position.y)
	cam.limit_bottom = ceili(room.position.y + room.size.y)

	# Bila ruangan lebih kecil dari pandangan di satu sumbu, pusatkan.
	if room.size.x <= half_view.x * 2.0:
		var cx: float = room.position.x + room.size.x / 2.0
		cam.limit_left = floori(cx - half_view.x)
		cam.limit_right = ceili(cx + half_view.x)

	if room.size.y <= half_view.y * 2.0:
		var cy: float = room.position.y + room.size.y / 2.0
		cam.limit_top = floori(cy - half_view.y)
		cam.limit_bottom = ceili(cy + half_view.y)

	cam.enabled = true
	cam.make_current()


func _room_rect() -> Rect2:
	# Mendukung lantai berupa TileMapLayer maupun Sprite2D (background ruangan).
	if floor_node is TileMapLayer:
		var layer := floor_node as TileMapLayer
		if not layer.tile_set:
			return Rect2()
		var used: Rect2i = layer.get_used_rect()
		if used.size == Vector2i.ZERO:
			return Rect2()

		var tile_size: Vector2 = (
			Vector2(layer.tile_set.tile_size) * layer.global_scale.abs()
		)
		var first_cell: Vector2 = layer.to_global(
			layer.map_to_local(used.position)
		)
		var last_cell: Vector2 = layer.to_global(
			layer.map_to_local(used.end - Vector2i.ONE)
		)

		var left: float = minf(first_cell.x, last_cell.x) - tile_size.x / 2.0
		var right: float = maxf(first_cell.x, last_cell.x) + tile_size.x / 2.0
		var top: float = minf(first_cell.y, last_cell.y) - tile_size.y / 2.0
		var bottom: float = maxf(first_cell.y, last_cell.y) + tile_size.y / 2.0
		return Rect2(left, top, right - left, bottom - top)
	elif floor_node is Sprite2D:
		var sprite := floor_node as Sprite2D
		if not sprite.texture:
			return Rect2()
		var size: Vector2 = sprite.texture.get_size() * sprite.global_scale.abs()
		var center: Vector2 = (
			sprite.global_position + sprite.offset * sprite.global_scale
		)
		return Rect2(center - size / 2.0, size)

	return Rect2()


# KARTU INTRO LEVEL
func _show_level_intro() -> void:
	if SceneTransition.level_intro_shown:
		return

	SceneTransition.level_intro_shown = true

	if not ResourceLoader.exists(LEVEL_INTRO_SCENE):
		return

	var intro_scene: PackedScene = load(LEVEL_INTRO_SCENE) as PackedScene
	if intro_scene == null:
		return

	# CanvasLayer memastikan overlay berada di atas dunia game.
	var overlay_layer := CanvasLayer.new()
	overlay_layer.name = "LevelIntroLayer"
	overlay_layer.layer = 100
	add_child(overlay_layer)

	var intro := intro_scene.instantiate() as Control
	overlay_layer.add_child(intro)


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
	if leave_button:
		leave_button.disabled = true

	if is_instance_valid(player):
		player.set_physics_process(false)
		player.velocity = Vector2.ZERO

	await fade_out(0.5)

	get_tree().change_scene_to_file(
		"res://scenes/world/world.tscn"
	)