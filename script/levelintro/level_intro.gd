
extends Control

const LEVELS := {
	1: {"title": "LEVEL 1 — PETI SONGKOK", "location": "Sulawesi Selatan"},
	2: {"title": "LEVEL 2 — RUMOH ACEH", "location": "Aceh"},
	3: {"title": "LEVEL 3 — RUMAH BETANG", "location": "Kalimantan"},
	4: {"title": "LEVEL 4 — IWEL-IWEL", "location": "Jawa Timur"}
}

@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Title
@onready var location_label: Label = $CenterContainer/PanelContainer/VBoxContainer/LocationLabel
@onready var background: ColorRect = $ColorRect
@onready var center_container: CenterContainer = $CenterContainer


func _ready() -> void:
	# Penuhi layar dengan overlay.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Redupkan gameplay di belakang panel.
	background.color = Color(0.02, 0.015, 0.01, 0.62)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Ambil level yang dipilih dari peta.
	var level_id := int(get_tree().get_meta("selected_level", 1))
	if not LEVELS.has(level_id):
		level_id = 1

	title_label.text = LEVELS[level_id]["title"]
	location_label.text = "📍 " + LEVELS[level_id]["location"]

	# Gaya panel.
	var panel := $CenterContainer/PanelContainer
	var style := StyleBoxFlat.new()
	style.bg_color = Color("382317")
	style.border_color = Color("e6b65b")
	style.set_border_width_all(4)
	style.set_corner_radius_all(20)
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", style)

	# Gaya teks.
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color("ffe2a1"))

	location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	location_label.add_theme_font_size_override("font_size", 23)
	location_label.add_theme_color_override("font_color", Color("fff4df"))

	# Fade in, diam 5 detik, lalu fade out.
	modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6)
	tween.tween_interval(5.0)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)
