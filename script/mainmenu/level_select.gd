extends Control
 
const MAP_TEXTURE: Texture2D = preload("res://assets/images/mainmenu/map_level_select.png")
const LEVEL_UNLOCKED_TEXTURE: Texture2D = preload("res://assets/images/mainmenu/Unlocked.png")
const LEVEL_LOCKED_TEXTURE: Texture2D = preload("res://assets/images/mainmenu/Locked.png")
const STAR_ACTIVE_TEXTURE: Texture2D = preload("res://assets/images/mainmenu/Active.png")
const STAR_INACTIVE_TEXTURE: Texture2D = preload("res://assets/images/mainmenu/Unactive.png")
 
# Ukuran kartu level & bintang. Ubah di sini kalau mau lebih besar/kecil.
const CARD_SIZE := Vector2(130, 150)
# Gambar kartu punya ruang transparan di tepinya; ini porsi area yang benar-benar
# terlihat. Teks, bintang, panah, dan area klik dihitung dari area ini.
const CARD_VISIBLE_RATIO := 0.66
const STAR_DISPLAY_SIZE := Vector2(28, 28)
const STAR_SPACING := 25.0
# Titik tengah kartu relatif terhadap posisi asli marker di scene.
const CARD_CENTER_OFFSET := Vector2(20, 22)
 
const LEVELS := [
	{"id": 1, "title": "Peti Songkok", "shape": "Kubus", "place": "Sulawesi Selatan"},
	{"id": 2, "title": "Rumoh Aceh", "shape": "Balok", "place": "Aceh"},
	{"id": 3, "title": "Rumah Betang", "shape": "Prisma Segitiga", "place": "Kalimantan"},
	{"id": 4, "title": "Iwel-iwel", "shape": "Limas", "place": "Jawa Timur"},
]
 
var progress: Dictionary = {
	"unlocked": 1,
	"stars": {"1": 0, "2": 0, "3": 0, "4": 0}
}
 
var markers: Array[Button] = []
var arrow: Label
var info_panel: PanelContainer
var info_label: Label
var total_label: Label
var selected_level := 1
 
 
func _ready() -> void:
	# Peta level adalah hub antar-level: posisi spawn dari level sebelumnya tidak
	# boleh terbawa, kalau tidak pemain muncul di tempat yang salah di level baru.
	SceneTransition.reset_for_new_level()

	_build_ui()
	_collect_markers()
	_refresh_ui()
	_layout_markers()
 
	get_viewport().size_changed.connect(_layout_markers)
 
 
func _collect_markers() -> void:
	var marker_container := get_node_or_null("Markers")
 
	if marker_container == null:
		push_error("Node Markers tidak ditemukan di LevelSelect.")
		return
 
	markers.clear()
 
	for i in range(4):
		var marker := marker_container.get_node_or_null(
			"Level%d" % (i + 1)
		) as Button
 
		if marker == null:
			push_error(
				"Pastikan Markers memiliki Button Level1 sampai Level4."
			)
			return
 
		var original_position: Vector2 = marker.position
		marker.set_meta("original_position", original_position)
		marker.text = ""
		var marker_empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
		marker.add_theme_stylebox_override("normal", marker_empty_style)
		marker.add_theme_stylebox_override("hover", marker_empty_style)
		marker.add_theme_stylebox_override("pressed", marker_empty_style)
		marker.add_theme_stylebox_override("disabled", marker_empty_style)
		marker.add_theme_stylebox_override("focus", marker_empty_style)
		marker.pressed.connect(_on_level_pressed.bind(i + 1))
		marker.mouse_entered.connect(_on_level_hovered.bind(i + 1))
		marker.focus_entered.connect(_on_level_hovered.bind(i + 1))
		markers.append(marker)
 
	# Perbaikan: posisi marker Level 2 (Aceh) dan Level 3 (Kalimantan) tertukar
	# di scene -> tukar di sini supaya sesuai lokasi sebenarnya di peta.
	var pos2: Vector2 = markers[1].get_meta("original_position")
	var pos3: Vector2 = markers[2].get_meta("original_position")
	markers[1].set_meta("original_position", pos3)
	markers[2].set_meta("original_position", pos2)
 
 
func _build_ui() -> void:
	var map_view := TextureRect.new()
	map_view.texture = MAP_TEXTURE
	map_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_view.stretch_mode = TextureRect.STRETCH_SCALE
	map_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(map_view)
	move_child(map_view, 0)
 
	var dim := ColorRect.new()
	dim.color = Color(0.025, 0.08, 0.13, 0.13)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	move_child(dim, 1)
 
	var header := Label.new()
	header.text = "PILIH LEVEL  •  MATHVENTURE"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 30)
	header.add_theme_color_override("font_color", Color("fff1c4"))
	header.add_theme_color_override("font_shadow_color", Color("4b2412"))
	header.add_theme_constant_override("shadow_offset_x", 2)
	header.add_theme_constant_override("shadow_offset_y", 3)
	header.anchor_left = 0.25
	header.anchor_right = 0.75
	header.offset_top = 18
	header.offset_bottom = 65
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)
 
	var back := Button.new()
	back.text = "←  Kembali"
	back.position = Vector2(18, 18)
	back.custom_minimum_size = Vector2(160, 48)
	back.pressed.connect(_on_back_pressed)
	_style_button(back, Color("70401f"))
	add_child(back)
 
	total_label = Label.new()
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	total_label.add_theme_font_size_override("font_size", 21)
	total_label.add_theme_color_override("font_color", Color("fff4cf"))
	total_label.anchor_left = 0.78
	total_label.anchor_right = 0.98
	total_label.offset_top = 22
	total_label.offset_bottom = 56
	total_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(total_label)
 
	arrow = Label.new()
	arrow.text = "▼"
	arrow.size = Vector2(40, 34)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.add_theme_font_size_override("font_size", 28)
	arrow.add_theme_color_override("font_color", Color("ffcf35"))
	arrow.add_theme_color_override("font_shadow_color", Color("5b280b"))
	arrow.add_theme_constant_override("shadow_offset_x", 2)
	arrow.add_theme_constant_override("shadow_offset_y", 3)
	arrow.z_index = 10
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arrow)
 
	info_panel = PanelContainer.new()
	info_panel.anchor_left = 0.02
	info_panel.anchor_right = 0.34
	info_panel.anchor_top = 0.79
	info_panel.anchor_bottom = 0.96
 
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.07, 0.04, 0.94)
	panel_style.border_color = Color("e6b65b")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(14)
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
 
	info_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(info_panel)
 
	info_label = Label.new()
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.add_theme_color_override("font_color", Color("fff0cf"))
	info_panel.add_child(info_label)
 
	var reset_hint := Label.new()
	reset_hint.text = "Tip: selesaikan level untuk membuka lokasi berikutnya."
	reset_hint.anchor_left = 0.49
	reset_hint.anchor_right = 0.98
	reset_hint.anchor_top = 0.94
	reset_hint.anchor_bottom = 0.99
	reset_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reset_hint.add_theme_font_size_override("font_size", 14)
	reset_hint.add_theme_color_override("font_color", Color.WHITE)
	reset_hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	reset_hint.add_theme_constant_override("shadow_offset_x", 1)
	reset_hint.add_theme_constant_override("shadow_offset_y", 1)
	reset_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(reset_hint)
 
 
func _card_center(button: Button) -> Vector2:
	var origin: Vector2 = button.get_meta("original_position", button.position)
	return origin + CARD_CENTER_OFFSET
 
 
func _layout_markers() -> void:
	if markers.is_empty() or arrow == null:
		return
 
	# Tombol klik = persis seukuran kartu.
	for b in markers:
		var center := _card_center(b)
		var inner := CARD_SIZE * CARD_VISIBLE_RATIO
		b.size = inner
		b.custom_minimum_size = inner
		b.position = center - inner / 2.0
 
	# Panah di atas kartu yang dipilih.
	var active_center := _card_center(markers[selected_level - 1])
	arrow.visible = true
	var inner_h := CARD_SIZE.y * CARD_VISIBLE_RATIO
	arrow.position = Vector2(
		active_center.x - arrow.size.x / 2.0,
		active_center.y - inner_h / 2.0 - arrow.size.y + 4
	)
 
 
func _refresh_ui() -> void:
	if markers.size() != LEVELS.size():
		return
 
	progress.unlocked = ProgressManager.highest_unlocked_level
 
	for level_id in range(1, 5):
		progress.stars[str(level_id)] = int(
			ProgressManager.level_stars.get(level_id, 0)
		)
 
	var total := 0
 
	for i in range(LEVELS.size()):
		var data: Dictionary = LEVELS[i]
		var id := int(data.id)
		var stars := int(progress.stars.get(str(id), 0))
		total += stars
 
		var b: Button = markers[i]
		var unlocked := id <= int(progress.unlocked)
 
		b.disabled = not unlocked
		b.text = ""
		b.icon = null
		b.z_index = 0
 
		b.tooltip_text = "%s — %s%s" % [data.shape, data.place, " — Level terkunci" if not unlocked else ""]
		_update_marker_badge(b, id, unlocked)
 
	total_label.text = "⭐ %d / %d bintang" % [
		total,
		LEVELS.size() * 3
	]
 
	_update_info_panel()
	_layout_markers()
 
 
func _update_info_panel() -> void:
	var d: Dictionary = LEVELS[selected_level - 1]
	var state_text := "TERBUKA" if selected_level <= int(progress.unlocked) else "TERKUNCI"
 
	info_label.text = "LEVEL %d — %s (%s)\nLokasi: %s\n%s  •  %s" % [
		selected_level,
		d.title,
		d.shape,
		d.place,
		_star_text(int(progress.stars.get(str(selected_level), 0))),
		state_text
	]
 
 
func _update_marker_badge(button: Button, level_id: int, unlocked: bool) -> void:
	var data: Dictionary = LEVELS[level_id - 1]
	var center := _card_center(button)
	var card_top_left := center - CARD_SIZE / 2.0
 
	# --- Kartu ---
	var card: TextureRect = get_node_or_null("BadgeCard%d" % level_id) as TextureRect
	if card == null:
		card = TextureRect.new()
		card.name = "BadgeCard%d" % level_id
		add_child(card)
	card.texture = LEVEL_UNLOCKED_TEXTURE if unlocked else LEVEL_LOCKED_TEXTURE
	card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.size = CARD_SIZE
	card.position = card_top_left
	card.z_index = 1
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.modulate = Color.WHITE
 
	# --- Judul (di dalam kartu, bagian atas) ---
	var title: Label = get_node_or_null("BadgeText%d" % level_id) as Label
	if title == null:
		title = Label.new()
		title.name = "BadgeText%d" % level_id
		add_child(title)
	title.text = "LEVEL %d\n%s" % [level_id, str(data.title)]
	var inner := CARD_SIZE * CARD_VISIBLE_RATIO
	title.size = Vector2(inner.x, 34)
	title.position = center - inner / 2.0 + Vector2(0, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.clip_text = true
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color("fff2d2") if unlocked else Color("d5d0c4"))
	title.add_theme_color_override("font_shadow_color", Color(0.12, 0.08, 0.04, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	title.add_theme_constant_override("line_spacing", -2)
	title.z_index = 2
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
 
	# --- Bintang (rapi, sejajar, di dalam kartu bagian bawah) ---
	var level_stars: int = int(progress.stars.get(str(level_id), 0))
	# Punya bintang -> tampil kuning saja sebanyak yang didapat.
	# Belum punya / terkunci -> tampil 3 abu-abu saja.
	var has_stars := unlocked and level_stars > 0
	var shown_count := level_stars if has_stars else 3
	var stars_total_width := STAR_SPACING * float(shown_count - 1) + STAR_DISPLAY_SIZE.x
	var stars_start_x := center.x - stars_total_width / 2.0
	var stars_y := center.y + inner.y / 2.0 - STAR_DISPLAY_SIZE.y - 3
 
	for star_index: int in range(3):
		var star: TextureRect = get_node_or_null("BadgeStar%d_%d" % [level_id, star_index]) as TextureRect
		if star == null:
			star = TextureRect.new()
			star.name = "BadgeStar%d_%d" % [level_id, star_index]
			add_child(star)
		star.visible = star_index < shown_count
		star.texture = STAR_ACTIVE_TEXTURE if has_stars else STAR_INACTIVE_TEXTURE
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.size = STAR_DISPLAY_SIZE
		star.position = Vector2(stars_start_x + star_index * STAR_SPACING, stars_y)
		star.z_index = 3
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
 
 
func _star_text(count: int) -> String:
	var result := ""
 
	for i in range(3):
		result += "★ " if i < count else "☆ "
 
	return result.strip_edges()
 
 
func _style_button(button: Button, base_color: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.border_color = Color("f5ca70")
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(12)
	normal.content_margin_left = 7
	normal.content_margin_right = 7
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
 
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = base_color.lightened(0.18)
 
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = base_color.darkened(0.18)
 
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", Color("fff2d2"))
	button.add_theme_color_override("font_disabled_color", Color("c7c1b7"))
	button.add_theme_font_size_override("font_size", 15)
 
 
func _on_level_hovered(level_id: int) -> void:
	selected_level = level_id
	_update_info_panel()
	_layout_markers()
 
 
func _on_level_pressed(level_id: int) -> void:
	if level_id > int(ProgressManager.highest_unlocked_level):
		return

	get_tree().set_meta("selected_level", level_id)

	# Posisi spawn dari level sebelumnya tidak boleh terbawa ke level baru.
	SceneTransition.reset_for_new_level()

	# Tampilkan lagi intro level ini saat dimulai (bukan sekali per sesi).
	SceneTransition.level_intro_shown = false

	if level_id == 2:
		get_tree().change_scene_to_file("res://scenes/world/rumah_aceh.tscn")
	elif level_id == 3:
		get_tree().change_scene_to_file("res://scenes/world/rumah_betang.tscn")
	elif level_id == 4:
		get_tree().change_scene_to_file("res://scenes/world/pendopo_jawa_timur.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/world/world.tscn")
 
 
func complete_level(level_id: int, earned_stars: int) -> void:
	ProgressManager.complete_level(
		level_id,
		clampi(earned_stars, 0, 3)
	)
	_refresh_ui()
 
 
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/mainmenu/main_menu.tscn")
 
