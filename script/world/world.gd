
extends Node2D

const LEVEL_DATA := {
	1: {
		"background": "res://assets/images/buildings/background untuk level 1.jpeg",
		"interior": "res://scenes/interior/rumah_bugis_interior.tscn",
		"door_shapes": [Vector2(212.0, 469.0), Vector2(811.49, 506.94)],
		"narration": [],
	},
}

@onready var screen_fade: ColorRect = $InteractionUI/ScreenFade
@onready var enter_button: Button = $InteractionUI/EnterHouseButton
@onready var ground: Sprite2D = $Environment/Ground
@onready var cam: Camera2D = $Player/Camera2D
@onready var door_area: Area2D = $DoorArea

var _narration: Array[String] = []


func _ready() -> void:
	_apply_level()
	_setup_camera_limits()

	if SceneTransition.outside_spawn_position != Vector2.ZERO:
		$Player.global_position = SceneTransition.outside_spawn_position

	enter_button.hide()

	# Fade dari layar hitam saat memasuki dunia luar.
	screen_fade.color = Color(0, 0, 0, 1)
	screen_fade.show()
	screen_fade.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()
	tween.tween_property(screen_fade, "color:a", 0.0, 0.5)
	await tween.finished

	screen_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Intro hanya muncul sekali, tidak berulang saat keluar rumah.
	if not SceneTransition.level_intro_shown:
		SceneTransition.level_intro_shown = true
		_show_level_intro()
		if not _narration.is_empty():
			await get_tree().create_timer(6.6).timeout
			DialogBox.start(_narration)


func _apply_level() -> void:
	var level := int(get_tree().get_meta("selected_level", 1))
	if not LEVEL_DATA.has(level):
		level = 1

	var data: Dictionary = LEVEL_DATA[level]

	var bg_path: String = data["background"]
	if ResourceLoader.exists(bg_path):
		ground.texture = load(bg_path) as Texture2D

	var shapes: Array = data["door_shapes"]
	var cs1 := door_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var cs2 := door_area.get_node_or_null("CollisionShape2D2") as CollisionShape2D
	if cs1:
		cs1.position = shapes[0]
	if cs2:
		cs2.position = shapes[1]

	door_area.set("interior_scene_path", data["interior"])

	_narration.clear()
	for line in data["narration"]:
		_narration.append(line)


func _setup_camera_limits() -> void:
	if not ground or not ground.texture or not cam:
		return

	var half_size: Vector2 = (
		ground.texture.get_size() * ground.global_scale.abs()
	) / 2.0

	var center: Vector2 = ground.global_position

	cam.limit_left = int(center.x - half_size.x)
	cam.limit_right = int(center.x + half_size.x)
	cam.limit_top = int(center.y - half_size.y)
	cam.limit_bottom = int(center.y + half_size.y)


func _show_level_intro() -> void:
	var intro_scene: PackedScene = preload(
		"res://scenes/levelintro/level_intro.tscn"
	)

	# CanvasLayer memastikan overlay berada di atas dunia game.
	var overlay_layer := CanvasLayer.new()
	overlay_layer.name = "LevelIntroLayer"
	overlay_layer.layer = 100
	add_child(overlay_layer)

	var intro := intro_scene.instantiate() as Control
	overlay_layer.add_child(intro)
