extends Area2D

@export_file("*.tscn") var interior_scene_path: String
@export var fade_duration: float = 0.5

@onready var enter_button: Button = get_node("/root/World/InteractionUI/EnterHouseButton")
@onready var screen_fade: ColorRect = get_node("/root/World/InteractionUI/ScreenFade")

const SPAWN_MARGIN := 50.0

var player_nearby := false
var is_transitioning := false


func _ready() -> void:
	enter_button.text = "Masuk ke Rumah"
	enter_button.hide()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	enter_button.pressed.connect(_enter_house)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Player":
		player_nearby = true
		if not is_transitioning:
			enter_button.show()


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Player":
		player_nearby = false
		enter_button.hide()


func _unhandled_input(event: InputEvent) -> void:
	if player_nearby and not is_transitioning and event.is_action_pressed("interact"):
		_enter_house()


func _enter_house() -> void:
	if not player_nearby or is_transitioning or interior_scene_path.is_empty():
		return
	is_transitioning = true
	enter_button.hide()

	# Spawn di bawah pintu saat kembali ke luar
	var door_shape: CollisionShape2D = $CollisionShape2D
	var half_h: float = (door_shape.shape as RectangleShape2D).size.y / 2.0
	SceneTransition.outside_spawn_position = door_shape.global_position + Vector2(0, half_h + SPAWN_MARGIN)
	SceneTransition.entering_house = true

	# Layar menggelap dulu, baru pindah scene
	screen_fade.show()
	screen_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(screen_fade, "color:a", 1.0, fade_duration)
	await tween.finished

	get_tree().change_scene_to_file(interior_scene_path)
