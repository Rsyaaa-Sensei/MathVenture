extends Area2D
## Pasang di node ChestInteraction (scene interior).
## Tombol "ChestButton" muncul saat pemain dekat; ditekan -> masuk scene 3D peti.

@export_file("*.tscn") var scene_3d := "res://scenes/peti/peti_3d.tscn"
@export var button_text := "Periksa Peti"
@export var fade_duration := 0.4

# Tambahkan Button baru "ChestButton" di InteractionUI, centang "Access as Unique Name".
@onready var chest_button: Button = %ChestButton

var player_nearby := false
var _opening := false


func _ready() -> void:
	chest_button.text = button_text
	chest_button.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	chest_button.pressed.connect(_open_chest)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_nearby = true
		if not _opening:
			chest_button.show()


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_nearby = false
		chest_button.hide()


func _open_chest() -> void:
	if not player_nearby or _opening:
		return
	_opening = true
	chest_button.hide()
	SceneTransition.mark_object_inspected(scene_3d)

	var scene := get_tree().current_scene
	# Simpan posisi pemain supaya kembali ke dekat peti, bukan ke pintu.
	var player := scene.get_node_or_null("%Player") as Node2D
	if player:
		SceneTransition.interior_return_position = player.global_position
		SceneTransition.pending_room_return = true

	if scene.has_method("fade_out"):
		await scene.fade_out(fade_duration)
	get_tree().change_scene_to_file(scene_3d)
