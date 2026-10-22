extends Area2D

# Gunakan Unique Name (%) agar tidak error Node not found
@onready var songkok_button: Button = %SongkokButton
@onready var dialog: Control = %SongkokDialog
@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var close_button: Button = %SongkokCloseButton

var player_nearby := false

func _ready() -> void:
	if songkok_button: songkok_button.hide()
	if dialog: dialog.hide()

	if songkok_button:
		songkok_button.text = "Pelajari Songkok Recca"

	if title_label:
		title_label.text = "Songkok Recca"

	if description_label:
		description_label.text = """Songkok Recca merupakan penutup kepala tradisional masyarakat Bugis, khususnya yang dikenal dari Bone, Sulawesi Selatan.

Songkok ini dibuat secara tradisional dengan teknik menganyam serat daun lontar. Songkok Recca menjadi salah satu bagian dari warisan budaya Bugis.

Ayo, kenali dan lestarikan budaya daerah Indonesia!"""

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if songkok_button:
		songkok_button.pressed.connect(_on_songkok_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_nearby = true
		if dialog and not dialog.visible:
			if songkok_button: songkok_button.show()


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_nearby = false
		if songkok_button: songkok_button.hide()


func _on_songkok_pressed() -> void:
	if not player_nearby:
		return

	SceneTransition.mark_songkok_studied()
	if songkok_button: songkok_button.hide()
	if dialog: dialog.show()


func _on_close_pressed() -> void:
	if dialog: dialog.hide()

	if player_nearby and songkok_button:
		songkok_button.show()
