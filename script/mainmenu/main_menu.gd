extends Control

@onready var background: ColorRect = $Background
@onready var menu: VBoxContainer = $Background/VBoxContainer
@onready var title: Label = $Background/VBoxContainer/Title
@onready var play_button: Button = $Background/VBoxContainer/PlayButton
@onready var stats_button: Button = $Background/VBoxContainer/StatsButton
@onready var settings_button: Button = $Background/VBoxContainer/SettingsButton
@onready var quit_button: Button = $Background/VBoxContainer/QuitButton


func _ready() -> void:
	# Background memenuhi seluruh layar
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.08, 0.12, 0.20)

	menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	menu.position = Vector2(460, 160)
	menu.custom_minimum_size = Vector2(360, 400)
	menu.add_theme_constant_override("separation", 18)
	
	# Judul game
	title.text = "MATHVENTURE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(360, 90)
	title.add_theme_font_size_override("font_size", 36)

	# Ukuran tombol
	for button in [play_button, stats_button, settings_button, quit_button]:
		button.custom_minimum_size = Vector2(320, 58)
		button.add_theme_font_size_override("font_size", 22)

	# Teks tombol
	play_button.text = "Mulai Petualangan"
	stats_button.text = "Statistik"
	settings_button.text = "Pengaturan"
	quit_button.text = "Keluar"

	# Hubungkan tombol
	if not play_button.pressed.is_connected(_on_play_pressed):
		play_button.pressed.connect(_on_play_pressed)

	if not stats_button.pressed.is_connected(_on_stats_pressed):
		stats_button.pressed.connect(_on_stats_pressed)

	if not settings_button.pressed.is_connected(_on_settings_pressed):
		settings_button.pressed.connect(_on_settings_pressed)

	if not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/mainmenu/level_select.tscn")


func _on_stats_pressed() -> void:
	get_tree().change_scene_to_file("res://script/statistic/statistics.tscn")


func _on_settings_pressed() -> void:
	print("Menu pengaturan belum dibuat.")


func _on_quit_pressed() -> void:
	get_tree().quit()
