
extends Control

const FONT_PATH := "res://assets/font/BoldPixels.ttf"

@onready var background: ColorRect = $Background
@onready var margin: MarginContainer = $MarginContainer
@onready var container: VBoxContainer = $MarginContainer/VBoxContainer
@onready var title: Label = $MarginContainer/VBoxContainer/Title
@onready var level_progress: Label = $MarginContainer/VBoxContainer/LevelProgress
@onready var stars_progress: Label = $MarginContainer/VBoxContainer/StarsProgress
@onready var score_progress: Label = $MarginContainer/VBoxContainer/ScoreProgress
@onready var level_list: VBoxContainer = $MarginContainer/VBoxContainer/LevelList
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton

const LEVEL_NAMES := [
	"Kubus - Peti Songkok",
	"Balok - Rumoh Aceh",
	"Prisma - Rumah Betang",
	"Limas - Iwel-iwel"
]


func _ready() -> void:
	# Memenuhi layar dan memberi jarak dari tepi
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Latar gelap agar teks terbaca (sebelumnya ColorRect putih -> teks putih tak terlihat).
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.08, 0.12, 0.20)

	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_apply_theme()

	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 35)
	margin.add_theme_constant_override("margin_bottom", 35)

	container.add_theme_constant_override("separation", 16)

	# Tampilan judul
	title.text = "STATISTIK PETUALANGAN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color("ffe2a1"))

	# Tampilan informasi
	for label in [level_progress, stars_progress, score_progress]:
		label.add_theme_font_size_override("font_size", 22)
		label.custom_minimum_size = Vector2(0, 35)

	back_button.text = "Kembali"
	back_button.custom_minimum_size = Vector2(0, 50)
	back_button.pressed.connect(_on_back_pressed)

	refresh_statistics()


func _apply_theme() -> void:
	var th := Theme.new()
	if ResourceLoader.exists(FONT_PATH):
		th.default_font = load(FONT_PATH)
	th.default_font_size = 24
	th.set_color("font_color", "Label", Color("fff4df"))
	theme = th


func refresh_statistics() -> void:
	var completed: Array = ProgressManager.completed_levels

	level_progress.text = "Level selesai: %d / 4" % completed.size()
	stars_progress.text = "Total bintang: %d / 12" % ProgressManager.get_total_stars()
	score_progress.text = "Total skor: %d" % ProgressManager.get_total_score()

	for i in range(mini(level_list.get_child_count(), LEVEL_NAMES.size())):
		var label := level_list.get_child(i) as Label
		var level := i + 1
		var stars := int(ProgressManager.level_stars.get(level, 0))

		label.add_theme_font_size_override("font_size", 20)

		if completed.has(level):
			label.add_theme_color_override("font_color", Color("a8e6a1"))
			label.text = "%d. %s — Selesai — %s" % [
				level,
				LEVEL_NAMES[i],
				"★".repeat(stars) + "☆".repeat(3 - stars)
			]
		elif level <= ProgressManager.highest_unlocked_level:
			label.add_theme_color_override("font_color", Color("ffe2a1"))
			label.text = "%d. %s — Terbuka" % [level, LEVEL_NAMES[i]]
		else:
			label.add_theme_color_override("font_color", Color("9aa0aa"))
			label.text = "%d. %s — Terkunci" % [level, LEVEL_NAMES[i]]


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/mainmenu/main_menu.tscn")
