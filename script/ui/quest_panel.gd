class_name QuestPanel
extends PanelContainer
## Panel Objektif Misi (Quest Objective) tepat di bawah tombol "Peta Level".
## Menampilkan panduan langkah demi langkah agar pemain tidak tersesat.

const FONT_PATH := "res://assets/font/BoldPixels.ttf"
const LEVEL_SELECT_SCENE := "res://scenes/mainmenu/level_select.tscn"

@export_enum("level1_outside", "level1_interior", "level2", "level3", "level4")
var scene_id: String = "level1_outside"

@onready var header_label: Label = get_node_or_null("VBox/HeaderLabel") as Label
@onready var body_label: Label = get_node_or_null("VBox/ObjectivesLabel") as Label


func _ready() -> void:
	_apply_style()
	_wire_map_button()
	if not SceneTransition.quest_updated.is_connected(_refresh):
		SceneTransition.quest_updated.connect(_refresh)
	if not DialogBox.finished.is_connected(_refresh):
		DialogBox.finished.connect(_refresh)
	_refresh()


func _apply_style() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.18, 0.11, 0.07, 0.90)
	panel_style.border_color = Color("e6b65b")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 14
	panel_style.content_margin_right = 14
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
	add_theme_stylebox_override("panel", panel_style)

	var font: Font = null
	if ResourceLoader.exists(FONT_PATH):
		font = load(FONT_PATH) as Font

	if header_label:
		if font:
			header_label.add_theme_font_override("font", font)
		header_label.add_theme_font_size_override("font_size", 20)
		header_label.add_theme_color_override("font_color", Color("ffe2a1"))

	if body_label:
		if font:
			body_label.add_theme_font_override("font", font)
		body_label.add_theme_font_size_override("font_size", 16)
		body_label.add_theme_color_override("font_color", Color("fff4df"))
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _wire_map_button() -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return
	var map_btn := parent_node.get_node_or_null("MapButton") as Button
	if map_btn == null:
		return
	map_btn.text = "Peta Level"
	if ResourceLoader.exists(FONT_PATH):
		map_btn.add_theme_font_override("font", load(FONT_PATH) as Font)
		map_btn.add_theme_font_size_override("font_size", 20)
	if not map_btn.pressed.is_connected(_on_map_button_pressed):
		# Hanya sambungkan bila script scene belum menyambungkannya.
		if map_btn.pressed.get_connections().is_empty():
			map_btn.pressed.connect(_on_map_button_pressed)


func _on_map_button_pressed() -> void:
	SceneTransition.reset_for_new_level()
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)


func _mark(done: bool) -> String:
	return "[v]" if done else "[ ]"


func _refresh() -> void:
	if body_label == null:
		return

	var lines: PackedStringArray = PackedStringArray()
	match scene_id:
		"level1_outside":
			var entered: bool = SceneTransition.outside_spawn_position != Vector2.ZERO
			lines.append("%s 1. Jalan ke atas menuju tangga pintu Rumah Bugis" % _mark(entered))
			lines.append("%s 2. Tekan tombol \"Masuk Rumah\"" % _mark(entered))
		"level1_interior":
			var talked: bool = SceneTransition.is_npc_talked("Amure")
			var songkok: bool = SceneTransition.songkok_studied
			var done1: bool = SceneTransition.is_object_inspected("res://scenes/peti/peti_3d.tscn")
			lines.append("%s 1. Bicara dengan Kakek Amure (pojok kiri atas)" % _mark(talked))
			lines.append("%s 2. Pelajari Songkok Recca di meja kiri atas" % _mark(songkok))
			lines.append("%s 3. Dekati peti kayu lalu tekan \"Periksa Peti\"" % _mark(done1))
		"level2":
			var talked: bool = SceneTransition.is_npc_talked("Cut Nyak")
			var done2: bool = SceneTransition.is_object_inspected("res://scenes/peti/balok_3d.tscn")
			lines.append("%s 1. Bicara dengan Cut Nyak di tengah ruangan" % _mark(talked))
			lines.append("%s 2. Dekati peti kayu di samping lalu tekan \"Periksa Peti\"" % _mark(done2))
		"level3":
			var talked: bool = SceneTransition.is_npc_talked("Tempong")
			var done3: bool = SceneTransition.is_object_inspected("res://scenes/peti/prisma_3d.tscn")
			lines.append("%s 1. Bicara dengan Kakek Tempong di tengah halaman" % _mark(talked))
			lines.append("%s 2. Jalan ke kanan rumah lalu tekan \"Amati Atap Rumah\"" % _mark(done3))
		"level4":
			var talked: bool = SceneTransition.is_npc_talked("Mbok Ratih")
			var done4: bool = SceneTransition.is_object_inspected("res://scenes/peti/limas_3d.tscn")
			lines.append("%s 1. Bicara dengan Mbok Ratih di dekat meja kanan" % _mark(talked))
			lines.append("%s 2. Dekati meja kue lalu tekan \"Periksa Kue Iwel-iwel\"" % _mark(done4))

	body_label.text = "\n".join(lines)
