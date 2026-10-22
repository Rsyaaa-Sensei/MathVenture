extends Area2D

@export_file("*.tscn") var interior_scene_path: String

@onready var exit_button: Button = get_node_or_null("../InteractionUI/LeaveHouseButton") as Button

var player_nearby: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if exit_button:
		exit_button.text = "Keluar dari Rumah"
		exit_button.hide()
		exit_button.pressed.connect(_enter_house)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Player":
		player_nearby = true
		if exit_button:
			exit_button.show()


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Player":
		player_nearby = false
		if exit_button:
			exit_button.hide()


func _unhandled_input(event: InputEvent) -> void:
	if player_nearby and event.is_action_pressed("interact"):
		_enter_house()


func _enter_house() -> void:
	if not player_nearby or interior_scene_path.is_empty():
		return
	SceneTransition.entering_house = false
	get_tree().change_scene_to_file(interior_scene_path)
