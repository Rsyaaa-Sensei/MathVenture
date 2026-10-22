extends Node3D
## Level 3 (Prisma Segitiga - Rumah Betang, Kalimantan).
## Stage 1 (unsur prisma), Stage 2 (jaring-jaring + mini game susun pola),
## Stage 3 (tabel pola RME + rumus volume), lalu Evaluasi Akhir Level.

@export var prism_scene: PackedScene

const BACK_SCENE := "res://scenes/world/rumah_betang.tscn"
const MAIN_MENU_SCENE := "res://scenes/mainmenu/main_menu.tscn"
const LEVEL_SELECT_SCENE := "res://scenes/mainmenu/level_select.tscn"
const FONT_PATH := "res://assets/font/BoldPixels.ttf"
const LEVEL_ID := 3
const SCORE_COMPLETE := 100
# Arah pandang saat prisma tertutup (kamera menjauh sebesar _cam_scale * 3).
const CAMERA_DIR := Vector3(0.52, 0.46, 0.72)
const CAMERA_DISTANCE_SCALE := 3.45
const TAP_MAX_MOVE := 12.0

# Profil prisma diukur dari AABB model, sedikit di dalam siluet model.
const PROF_X := 0.97
const PROF_Y := 0.94
const PROF_Z := 0.99

enum Step { EXPLORE, ANIM, QUIZ_NET, STAGE3_RME, EVALUATION, DONE }

const PARTS: Array[String] = ["segitiga", "persegi", "panjang"]

const PART_LABEL := {
	"segitiga": "Segitiga",
	"persegi": "Persegi Panjang",
	"panjang": "Panjang",
}

const INSTRUKSI_1 := "Sentuh bagian-bagian penting dari struktur atap Rumah Betang untuk mengenali komponen pembentuknya."
const INSTRUKSI_2 := "Pilih bentangan lembaran datar yang bisa dilipat kembali menjadi prisma segitiga."
const INSTRUKSI_3 := "Cermati tabel pola susunan berikut untuk menemukan rumus volume prisma!"

const TEKS := {
	"segitiga": "Jati: Lihat bagian depan dan belakang atapnya, Kek. Bentuknya adalah dua buah segitiga yang identik dan saling berhadapan. Ini bisa kita sebut sebagai sisi alas dan sisi tutup prisma.",
	"panjang": "Jati: Lalu bentuk segitiga di depan itu ditarik memanjang secara sejajar ke arah belakang, membentuk ruang yang panjang. Sisi inilah yang menjadi tinggi atau panjang prismanya.",
	"persegi": "Jati: Serta bidang-bidang persegi panjang pada sisi miring atap dan bidang dasar yang menghubungkan bagian depan dan belakang.",
	"kesimpulan": "Tempong: Tepat sekali, Jati! Bangun ruang yang memiliki alas dan tutup berbentuk bangun datar yang kongruen serta sejajar, lalu dihubungkan oleh sisi tegak berbentuk persegi panjang, dinamakan PRISMA. Karena alasnya berbentuk segitiga, bangun ini disebut PRISMA SEGITIGA.\n\nTekan \"Bongkar Bangunan\" untuk melihat jaring-jaringnya.",
	"bongkar": "Jati: Wah, bangunannya terbuka menjadi lembaran datar! Kalau selimut dan tutup prisma ini direbahkan ke bidang datar, bentuknya langsung berubah menjadi jaring-jaring prisma segitiga, ya, Kek.\nTempong: Betul sekali, Nak. Sekarang coba uji ketelitianmu. Susunlah potongan bagian atap dan dinding itu agar kembali membentuk jaring-jaring prisma segitiga yang utuh!",
	"salah": "Tempong: Hmm, belum tepat, Nak. Bayangkan dilipat satu per satu \u2014 adakah sisi yang bertumpuk atau tidak punya pasangan?",
	"benar": "Tempong: Tepat sekali! Bentangan itu melipat kembali menjadi prisma segitiga yang utuh.",
	"stage3_intro": "Tempong: Nah, Jati, untuk mencari tahu berapa besar kapasitas ruangan di bawah atap ini, kita bisa melihat pola perkalian luas alas dan panjang ruangannya. Coba perhatikan tabel ini.\n\nBentuk Alas | Luas Alas (La) | Tinggi Prisma (t) | Bentuk Perkalian Volume (V)\nSegitiga kecil | 6 m\u00b2 | 5 m | 6 \u00d7 5 = 30 m\u00b3\nSegitiga sedang | 10 m\u00b2 | 5 m | 10 \u00d7 5 = 50 m\u00b3\nSegitiga standar | 12 m\u00b2 | 10 m | 12 \u00d7 10 = 120 m\u00b3\nSegitiga umum | Luas Alas | t | Luas Alas \u00d7 t",
	"stage3_benar": "Tempong: Hebat! Rumus umum untuk menghitung volume prisma selalu didapatkan dari perkalian antara luas bidang alasnya dengan tinggi prisma tersebut, jadi V = Luas Alas \u00d7 t.",
	"eval_intro": "Tempong: Sebelum acara musyawarah adat dimulai, coba selesaikan perhitungan ini untuk memastikan sirkulasi udara di dalam balai sudah pas."
}

@onready var _camera: Camera3D = $Camera3D
@onready var _light: DirectionalLight3D = $DirectionalLight3D
@onready var _pivot: Node3D = $PrismPivot
@onready var _net: Node3D = $Net
@onready var _hud: Control = %Hud
@onready var _title: Label = %TitleLabel
@onready var _progress: Label = %ProgressLabel
@onready var _dialog: Label = %DialogLabel
@onready var _quiz_row: HBoxContainer = %QuizRow
@onready var _btn_bongkar: Button = %BtnBongkar
@onready var _btn_selesai: Button = %BtnSelesai
@onready var _btn_kembali: Button = %BackButton
@onready var _dialog_panel: PanelContainer = %DialogPanel
@onready var _reward_layer: Control = %RewardLayer
@onready var _reward_panel: PanelContainer = %RewardPanel
@onready var _reward_title: Label = %RewardTitle
@onready var _reward_stars: Label = %RewardStars
@onready var _reward_info: Label = %RewardInfo
@onready var _reward_next: Button = %RewardNext
@onready var _reward_menu: Button = %RewardMenu

var _model: Node3D
var _half := Vector3.ONE
var _unit := 1.0
var _cam_scale := 1.0
var _cam_closed := Vector3(2.3, 1.8, 3.0)
var _cam_open := Vector3(0.0, 7.5, 2.7)
var _cam_look_closed := Vector3.ZERO
var _cam_look_open := Vector3(0.0, -0.5, 0.8)

# Profil prisma segitiga, diukur dari mesh terbesar model: alas di y = _base_y
# selebar 2*_bx, puncak/rusuk atas di y = _apex_y, memanjang 2*_hz pada sumbu Z.
var _bx := 1.0
var _base_y := -1.0
var _apex_y := 1.0
var _height := 2.0
var _hz := 1.0
var _plate_thick := 0.1
var _slope_len := 1.0
var _slope_dir := Vector3.RIGHT

var _active_root: Node3D
var _mats: Dictionary = {}
var _base_colors: Dictionary = {}
var _hi_colors: Dictionary = {}
var _flash_tw: Dictionary = {}
var _net_pivots: Dictionary = {}

var _seen := {"segitiga": false, "persegi": false, "panjang": false}
var _step := Step.EXPLORE
var _dragging := false
var _drag_dist := 0.0
var _press_pos := Vector2.ZERO
var _pending_tap := false
var _tap_pos := Vector2.ZERO
var _eval_index := 0


func _ready() -> void:
	_apply_theme()
	_light.rotation_degrees = Vector3(-45, 35, 0)
	_load_model()
	_measure_profile()
	_build_skeleton()
	_build_net()
	_active_root = _pivot

	_camera.near = 0.01 * _unit
	_camera.far = 200.0 * _unit
	_camera.position = _cam_closed
	_camera.look_at(_cam_look_closed)

	_btn_bongkar.text = "Bongkar Bangunan"
	_btn_bongkar.pressed.connect(_on_bongkar)
	_btn_selesai.pressed.connect(_on_kembali)
	_btn_kembali.pressed.connect(_on_kembali)
	_style_reward()
	_reward_next.text = "Menu Utama"
	_reward_next.pressed.connect(_on_reward_next)
	_reward_menu.text = "Pilih Level"
	_reward_menu.pressed.connect(_on_reward_menu)
	_reward_layer.hide()
	_title.text = INSTRUKSI_1
	_dialog.text = "Tempong: Jati, coba amati atap Rumah Betang ini. Sentuh bagian-bagiannya untuk mengenali unsur-unsur prisma segitiga, ya."
	_layout_bottom("default")
	_update_progress()


## Atur posisi baris pilihan. Panel dialog selalu mengecil/membesar mengikuti
## panjang teksnya sendiri (offset atasnya kecil + grow_vertical = BEGIN).
## "net": pilihan di atas (jaring-jaring terbentang) - "default": pilihan di bawah.
func _layout_bottom(mode: String) -> void:
	if mode == "net":
		_quiz_row.offset_top = -600.0
		_quiz_row.offset_bottom = -440.0
	else:
		_quiz_row.offset_top = -510.0
		_quiz_row.offset_bottom = -310.0


func _apply_theme() -> void:
	var th := Theme.new()
	if ResourceLoader.exists(FONT_PATH):
		th.default_font = load(FONT_PATH)
		th.default_font_size = 24
		th.set_color("font_color", "Label", Color(1.0, 1.0, 1.0, 1.0))
	_hud.theme = th
	_reward_layer.theme = th


# ------------------------------------------------------------ Model .glb
func _load_model() -> void:
	# Gunakan model yang sudah ada di scene terlebih dahulu agar tidak dobel.
	var existing: Node = get_node_or_null("prisma_objek")
	if existing is Node3D:
		_model = existing as Node3D
		if _model.get_parent() != _pivot:
			_model.reparent(_pivot, false)
	elif prism_scene:
		_model = prism_scene.instantiate() as Node3D
		if _model:
			_pivot.add_child(_model)
	else:
		var mi := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(6.0, 9.0, 3.0)
		mi.mesh = pm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.62, 0.40, 0.20)
		mi.material_override = m
		_model = mi
		_pivot.add_child(_model)

	if _model == null:
		push_error("Model prisma tidak ditemukan. Tambahkan prisma_objek ke scene atau isi prism_scene.")
		return

	_model.rotation_degrees = Vector3(-90, 0, 0)
	_fix_model_meshes()

	var box := _compute_aabb()
	if box.size == Vector3.ZERO:
		box = AABB(Vector3(-3.0, -1.5, -4.5), Vector3(6.0, 3.0, 9.0))
	_model.position -= box.get_center()
	_half = box.size / 2.0
	_unit = maxf((_half.x + _half.y + _half.z) / 3.0, 0.01)
	_cam_scale = maxf(maxf(_half.x, _half.y), maxf(_half.z, 0.01))


func _fix_model_meshes() -> void:
	# Pada model .glb, "Jalur jerami sisi -1 *" memiliki urutan indeks segitiga
	# terbalik sehingga ter-cull dari luar. Balik indeksnya dan aktifkan two-sided.
	var meshes: Array[Node] = _model.find_children("*", "MeshInstance3D", true, false)
	for n in meshes:
		var mi := n as MeshInstance3D
		if mi.mesh is ArrayMesh:
			var orig_mesh := mi.mesh as ArrayMesh
			if orig_mesh.get_surface_count() > 0:
				var mat: Material = orig_mesh.surface_get_material(0)
				if mat is StandardMaterial3D:
					(mat as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
				if mi.name.begins_with("Jalur jerami sisi -1"):
					var arr: Array = orig_mesh.surface_get_arrays(0)
					var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
					for i in range(0, idx.size(), 3):
						var tmp: int = idx[i + 1]
						idx[i + 1] = idx[i + 2]
						idx[i + 2] = tmp
					arr[Mesh.ARRAY_INDEX] = idx
					var fixed_mesh := ArrayMesh.new()
					fixed_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
					fixed_mesh.surface_set_material(0, mat)
					mi.mesh = fixed_mesh


func _compute_aabb() -> AABB:
	var inv := _pivot.global_transform.affine_inverse()
	var result := AABB()
	var first := true
	var meshes: Array[Node] = _model.find_children("*", "MeshInstance3D", true, false)
	if _model is MeshInstance3D:
		meshes.append(_model)
	for n in meshes:
		var mi := n as MeshInstance3D
		var a: AABB = (inv * mi.global_transform) * mi.get_aabb()
		if first:
			result = a
			first = false
		else:
			result = result.merge(a)
	return result


func _measure_profile() -> void:
	# Ukur badan prisma langsung dari mesh terbesar model supaya semua bidang
	# sorot (segitiga, sisi miring, alas) menempel tepat pada model.
	if not _measure_body():
		_bx = maxf(_half.x * PROF_X, 0.05)
		_base_y = -maxf(_half.y * PROF_Y, 0.05)
		_apex_y = -_base_y
		_hz = maxf(_half.z * PROF_Z, 0.05)

	_height = maxf(_apex_y - _base_y, 0.05)
	_plate_thick = maxf(0.05 * _unit, 0.02)

	# Arah sisi miring: dari tepi alas kiri menuju puncak prisma.
	_slope_dir = Vector3(_bx, _height, 0.0).normalized()
	_slope_len = _bx / maxf(_slope_dir.x, 0.0001)

	# Bingkai kamera saat prisma tertutup dan saat jaring-jaring terbentang.
	# Titik pandang digeser sedikit ke bawah/depan supaya model tidak tertutup
	# panel dialog di bagian bawah layar.
	_cam_closed = CAMERA_DIR.normalized() * (_cam_scale * CAMERA_DISTANCE_SCALE)
	_cam_look_closed = Vector3(0.0, -_cam_scale * 0.82, 0.0)

	var extent := maxf(_bx + _slope_len, _hz + _height)
	_cam_open = Vector3(0.0, extent * 3.4, 0.0)
	_cam_look_open = Vector3(0.0, _base_y, -extent * 0.5)


func _measure_body() -> bool:
	# Mesh terbesar pada model = badan prisma segitiga. AABB-nya dipakai untuk
	# menentukan lebar alas, tinggi, panjang, serta posisi alas dan puncak.
	if _model == null:
		return false

	var inv := _pivot.global_transform.affine_inverse()
	var best := AABB()
	var best_vol := 0.0
	var meshes: Array[Node] = _model.find_children("*", "MeshInstance3D", true, false)
	if _model is MeshInstance3D:
		meshes.append(_model)

	for n in meshes:
		var mi := n as MeshInstance3D
		var a: AABB = (inv * mi.global_transform) * mi.get_aabb()
		var vol: float = a.size.x * a.size.y * a.size.z
		if vol > best_vol:
			best_vol = vol
			best = a

	if best_vol <= 0.0:
		return false

	_bx = maxf(best.size.x / 2.0, 0.05)
	_base_y = best.position.y
	_apex_y = best.end.y
	_hz = maxf(best.size.z / 2.0, 0.05)
	return true


# ------------------------------------------------------------ Kerangka Sentuh
func _make_mat(color: Color, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _register_kind(kind: String, base: Color, hi: Color) -> void:
	_base_colors[kind] = base
	_hi_colors[kind] = hi
	_mats[kind] = _make_mat(base, true)


func _add_collider(mi: MeshInstance3D, kind: String, shape: Shape3D) -> void:
	var body := StaticBody3D.new()
	body.set_meta("kind", kind)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	mi.add_child(body)


func _triangle_mesh_xy(width: float, height: float) -> ArrayMesh:
	# Segitiga pada bidang XY: alas di bawah, puncak di atas.
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(-width / 2.0, -height / 2.0, 0.0),
		Vector3(width / 2.0, -height / 2.0, 0.0),
		Vector3(0.0, height / 2.0, 0.0),
	])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([
		Vector3.BACK, Vector3.BACK, Vector3.BACK,
	])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _triangle_mesh_xz(width: float, height: float) -> ArrayMesh:
	# Segitiga pada bidang XZ: alas di z = 0, puncak di z = height.
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(-width / 2.0, 0.0, 0.0),
		Vector3(width / 2.0, 0.0, 0.0),
		Vector3(0.0, 0.0, height),
	])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([
		Vector3.UP, Vector3.UP, Vector3.UP,
	])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _add_flat_quad(
	parent: Node3D, pos: Vector3, u: Vector3, v: Vector3, size: Vector2, kind: String
) -> void:
	# Bidang persegi panjang pada bidang datar yang dibentuk sumbu u dan v.
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	mi.material_override = _mats[kind]
	mi.transform = Transform3D(Basis(u, v, u.cross(v).normalized()), pos)
	parent.add_child(mi)

	var bs := BoxShape3D.new()
	bs.size = Vector3(size.x, size.y, 0.04 * _unit)
	_add_collider(mi, kind, bs)


func _build_skeleton() -> void:
	_register_kind("segitiga", Color(0.55, 0.85, 1.0, 0.0), Color(0.55, 0.85, 1.0, 0.55))
	_register_kind("persegi", Color(1.0, 0.85, 0.35, 0.0), Color(1.0, 0.85, 0.35, 0.5))
	_register_kind("panjang", Color(1.0, 0.45, 0.1, 0.0), Color(1.0, 0.45, 0.1, 0.9))

	var rangka := Node3D.new()
	rangka.name = "Kerangka"
	_pivot.add_child(rangka)

	# 1) Dua sisi segitiga (alas & tutup prisma) di depan dan belakang.
	var tri_center_y := (_base_y + _apex_y) / 2.0
	var front_z := maxf(_hz, _half.z) + 0.025 * _unit
	var back_z := -_hz - 0.025 * _unit
	for z in [back_z, front_z]:
		var mi := MeshInstance3D.new()
		mi.mesh = _triangle_mesh_xy(_bx * 2.0, _height)
		mi.material_override = _mats["segitiga"]
		mi.position = Vector3(0.0, tri_center_y, z)
		rangka.add_child(mi)

		var hy := _height / 2.0
		var shape := ConvexPolygonShape3D.new()
		# Dua segitiga tipis (bukan bidang rata) agar balok sinar tetap
		# mengenainya dengan andal saat disentuh pemain.
		var thin := 0.03 * _unit
		shape.points = PackedVector3Array([
			Vector3(-_bx, -hy, thin),
			Vector3(_bx, -hy, thin),
			Vector3(0.0, hy, thin),
			Vector3(-_bx, -hy, -thin),
			Vector3(_bx, -hy, -thin),
			Vector3(0.0, hy, -thin),
		])
		_add_collider(mi, "segitiga", shape)

	# 2) Tiga bidang persegi panjang: dua sisi miring atap + bidang dasar.
	# Geser sedikit keluar sepanjang normal masing-masing sisi agar berada
	# di atas jalur jerami/badan atap dan tidak mengalami z-fighting.
	var slope_off := 0.03 * _unit
	var left_normal := Vector3(-_height, _bx, 0.0).normalized()
	var right_normal := Vector3(_height, _bx, 0.0).normalized()
	var left_center := Vector3(-_bx / 2.0, tri_center_y, 0.0) + left_normal * slope_off
	var right_center := Vector3(_bx / 2.0, tri_center_y, 0.0) + right_normal * slope_off
	var right_slope_dir := Vector3(_bx, -_height, 0.0).normalized()
	_add_flat_quad(rangka, left_center, _slope_dir, Vector3.BACK, Vector2(_slope_len, _hz * 2.0), "persegi")
	_add_flat_quad(rangka, right_center, right_slope_dir, Vector3.BACK, Vector2(_slope_len, _hz * 2.0), "persegi")
	_add_flat_quad(
		rangka,
		Vector3(0.0, _base_y - 0.025 * _unit, 0.0),
		Vector3.RIGHT,
		Vector3.BACK,
		Vector2(_bx * 2.0, _hz * 2.0),
		"persegi"
	)

	# 3) Tiga rusuk panjang prisma (tinggi prisma).
	var t := 0.075 * _unit
	var edge_len := maxf(_hz * 2.0, _half.z * 2.0) + 0.02 * _unit
	for edge in [
		Vector3(0.0, _apex_y + 0.02 * _unit, 0.0),
		Vector3(-_bx, _base_y, 0.0),
		Vector3(_bx, _base_y, 0.0),
	]:
		_add_long_edge(rangka, edge, edge_len, t)


func _add_long_edge(parent: Node3D, pos: Vector3, length: float, t: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(t, t, length)
	mi.mesh = bm
	mi.material_override = _mats["panjang"]
	mi.position = pos
	parent.add_child(mi)

	var min_tap := 0.16 * _unit
	var bs := BoxShape3D.new()
	bs.size = Vector3(maxf(t, min_tap), maxf(t, min_tap), length)
	_add_collider(mi, "panjang", bs)


# ------------------------------------------------------------ Stage 1
func _on_part_touched(kind: String) -> void:
	if kind.is_empty() or not TEKS.has(kind):
		return
	_flash(kind)
	_seen[kind] = true
	_dialog.text = TEKS[kind]
	_update_progress()
	if _seen["segitiga"] and _seen["persegi"] and _seen["panjang"]:
		_dialog.add_theme_font_size_override("font_size", 22)
		_dialog.text += "\n\n" + TEKS["kesimpulan"]
		_btn_bongkar.show()


func _flash(kind: String) -> void:
	var m: StandardMaterial3D = _mats[kind]
	if _flash_tw.has(kind) and _flash_tw[kind]:
		(_flash_tw[kind] as Tween).kill()
	var tw := create_tween()
	_flash_tw[kind] = tw
	tw.tween_property(m, "albedo_color", _hi_colors[kind], 0.15)
	tw.tween_interval(1.0)
	tw.tween_property(m, "albedo_color", _base_colors[kind], 0.4)


func _update_progress() -> void:
	var parts: Array[String] = []
	for k in PARTS:
		parts.append(("● " if _seen[k] else "○ ") + str(PART_LABEL[k]))
	_progress.text = "   ".join(parts)


# ------------------------------------------------------------ Stage 2: Jaring-jaring
func _build_net() -> void:
	_net.scale = Vector3.ONE

	var base := Node3D.new()
	base.name = "AlasDatar"
	base.position = Vector3(0.0, _base_y, 0.0)
	_net.add_child(base)

	# Bidang dasar menjadi pusat bentangan.
	_add_flat_face(base, Vector3.ZERO, Vector2(_bx * 2.0, _hz * 2.0))

	var slope_deg := rad_to_deg(atan2(_slope_dir.y, _slope_dir.x))

	# Sisi miring kiri & kanan berengsel pada tepi panjang alas.
	_net_pivots["miring_kiri"] = [
		_make_pivot(
			base,
			Vector3(-_bx, 0.0, 0.0),
			Vector2(_slope_len, _hz * 2.0),
			Vector3(-_slope_len / 2.0, 0.0, 0.0)
		),
		"z",
		slope_deg - 180.0,
	]
	_net_pivots["miring_kanan"] = [
		_make_pivot(
			base,
			Vector3(_bx, 0.0, 0.0),
			Vector2(_slope_len, _hz * 2.0),
			Vector3(_slope_len / 2.0, 0.0, 0.0)
		),
		"z",
		180.0 - slope_deg,
	]
	# Segitiga alas & tutup berengsel pada tepi pendek alas.
	_net_pivots["segitiga_depan"] = [
		_make_triangle_pivot(base, Vector3(0.0, 0.0, _hz), _bx * 2.0, _height, 1.0),
		"x",
		-90.0,
	]
	_net_pivots["segitiga_belakang"] = [
		_make_triangle_pivot(base, Vector3(0.0, 0.0, -_hz), _bx * 2.0, _height, -1.0),
		"x",
		90.0,
	]


func _make_pivot(parent: Node3D, hinge_pos: Vector3, size: Vector2, face_off: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = hinge_pos
	parent.add_child(pivot)
	_add_flat_face(pivot, face_off, size)
	return pivot


func _make_triangle_pivot(
	parent: Node3D, hinge_pos: Vector3, width: float, height: float, apex_sign: float
) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = hinge_pos
	parent.add_child(pivot)
	_add_triangle_face(pivot, Vector3(0.0, 0.0, apex_sign * height / 3.0), width, height, apex_sign)
	return pivot


func _add_triangle_face(
	parent: Node3D, offset: Vector3, width: float, height: float, apex_sign: float
) -> void:
	var face := Node3D.new()
	face.position = offset
	parent.add_child(face)

	var mi := MeshInstance3D.new()
	mi.mesh = _triangle_mesh_xz(width, height)
	mi.material_override = _make_mat(Color(0.55, 0.29, 0.13))
	# Mesh dibuat dengan alas di z = 0 dan puncak di z = +height. Geser agar
	# titik berat segitiga berada di origin node face.
	if apex_sign < 0.0:
		mi.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	mi.position = Vector3(0.0, 0.0, -apex_sign * height / 3.0)
	face.add_child(mi)


func _add_flat_face(parent: Node3D, offset: Vector3, size: Vector2) -> void:
	# Satu bidang persegi panjang warna kayu, dengan bingkai gelap dan
	# ornamen emas agar diagram tetap terbaca saat dilipat dan dibentangkan.
	var face := Node3D.new()
	face.position = offset
	parent.add_child(face)

	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	mi.material_override = _make_mat(Color(0.55, 0.29, 0.13))
	mi.rotation_degrees = Vector3(-90, 0, 0)
	face.add_child(mi)

	var bw := minf(size.x, size.y)
	var edge := bw * 0.06
	var thick := bw * 0.10

	var border_mat := _make_mat(Color(0.20, 0.085, 0.025))
	_add_net_strip(face, Vector3(0, 0.012, -(size.y / 2.0 - edge)), Vector2(size.x - edge * 2.0, thick), border_mat)
	_add_net_strip(face, Vector3(0, 0.012, (size.y / 2.0 - edge)), Vector2(size.x - edge * 2.0, thick), border_mat)
	_add_net_strip(face, Vector3(-(size.x / 2.0 - edge), 0.012, 0), Vector2(thick, size.y - edge * 2.0), border_mat)
	_add_net_strip(face, Vector3((size.x / 2.0 - edge), 0.012, 0), Vector2(thick, size.y - edge * 2.0), border_mat)

	var gold := _make_mat(Color(0.95, 0.64, 0.20))
	var g := bw * 0.3
	_add_net_strip(face, Vector3.ZERO, Vector2(g, thick), gold)
	_add_net_strip(face, Vector3.ZERO, Vector2(thick, g), gold)


func _add_net_strip(parent: Node3D, pos: Vector3, size: Vector2, mat: Material) -> void:
	var strip := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, 0.025, size.y)
	strip.mesh = mesh
	strip.material_override = mat
	strip.position = pos
	parent.add_child(strip)


func _set_pivot_angle(pivot_name: String, t: float) -> void:
	var info: Array = _net_pivots[pivot_name]
	var pivot: Node3D = info[0]
	var angle: float = float(info[2]) * (1.0 - t)
	if info[1] == "x":
		pivot.rotation_degrees = Vector3(angle, 0, 0)
	else:
		pivot.rotation_degrees = Vector3(0, 0, angle)


func _net_step(t: float) -> void:
	for n in _net_pivots:
		_set_pivot_angle(n, clampf(t, 0.0, 1.0))
	_camera.position = _cam_closed.lerp(_cam_open, t)
	_camera.look_at(_cam_look_closed.lerp(_cam_look_open, t))


func _animate_net(opening: bool) -> void:
	_step = Step.ANIM
	if opening:
		_pivot.rotation = Vector3.ZERO
		_net.rotation = Vector3.ZERO
		_show_net(true)
		_net_step(0.0)
	var tw := create_tween()
	tw.tween_method(_net_step, 0.0 if opening else 1.0, 1.0 if opening else 0.0, 1.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	if not opening:
		_show_net(false)


func _show_net(show_net: bool) -> void:
	_net.visible = show_net
	_pivot.visible = not show_net
	_active_root = _net if show_net else _pivot


func _on_bongkar() -> void:
	if _step != Step.EXPLORE:
		return
	_btn_bongkar.hide()
	_progress.hide()
	_dialog.add_theme_font_size_override("font_size", 24)
	_title.text = INSTRUKSI_2
	_dialog.text = TEKS["bongkar"]
	_layout_bottom("net")
	await _animate_net(true)
	_build_quiz_net()
	_step = Step.QUIZ_NET


func _build_quiz_net() -> void:
	for c in _quiz_row.get_children():
		c.queue_free()
	var keys: Array[String] = ["valid", "samasisi", "empat"]
	keys.shuffle()
	var labels := ["A", "B", "C"]
	for i in keys.size():
		var o := PrismaNetOption.new()
		o.pieces = _net_option_pieces(keys[i])
		o.option_label = labels[i]
		o.custom_minimum_size = Vector2(172, 150)
		o.pressed.connect(_on_net_chosen.bind(o, keys[i] == "valid"))
		_quiz_row.add_child(o)
	_quiz_row.show()


func _net_option_pieces(kind: String) -> Array:
	# Tata letak baku prisma segitiga: deret 3 persegi panjang (panjang prisma
	# 3,2 ; sisi segitiga 2) lalu segitiga sama sisi (tinggi 1,73) ditempel pada
	# sisi-sisi persegi panjang. Sisi yang ditempeli menentukan pola itu benar.
	match kind:
		"valid":
			# Segitiga di sisi berlawanan: menutup kedua ujung prisma.
			return [
				{"t": "rect", "p": Vector2(0, 0), "s": Vector2(6.0, 3.2), "sep": [2.0, 4.0]},
				{"t": "tri", "b": Vector2(2, 0), "e": Vector2(4, 0), "a": Vector2(3, -1.73)},
				{"t": "tri", "b": Vector2(2, 3.2), "e": Vector2(4, 3.2), "a": Vector2(3, 4.93)},
			]
		"samasisi":
			# Dua segitiga sama-sama di sisi atas: saat dilipat keduanya bertumpuk.
			return [
				{"t": "rect", "p": Vector2(0, 0), "s": Vector2(6.0, 3.2), "sep": [2.0, 4.0]},
				{"t": "tri", "b": Vector2(2, 0), "e": Vector2(4, 0), "a": Vector2(3, -1.73)},
				{"t": "tri", "b": Vector2(4, 0), "e": Vector2(6, 0), "a": Vector2(5, -1.73)},
			]
		"empat":
			# Empat persegi panjang: keliling selimut (8) tidak sama dengan
			# keliling segitiga alas (6), jadi tidak bisa menutup prisma.
			return [
				{"t": "rect", "p": Vector2(0, 0), "s": Vector2(8.0, 3.2), "sep": [2.0, 4.0, 6.0]},
				{"t": "tri", "b": Vector2(2, 0), "e": Vector2(4, 0), "a": Vector2(3, -1.73)},
				{"t": "tri", "b": Vector2(2, 3.2), "e": Vector2(4, 3.2), "a": Vector2(3, 4.93)},
			]
	return []


func _on_net_chosen(option: Button, is_valid: bool) -> void:
	if _step != Step.QUIZ_NET:
		return
	if not is_valid:
		option.disabled = true
		_dialog.text = TEKS["salah"]
		return
	_quiz_row.hide()
	_dialog.text = TEKS["benar"]
	_layout_bottom("default")
	await _animate_net(false)
	_start_stage3_rme()


# ------------------------------------------------------------ Stage 3: Abstraksi Volume RME
func _start_stage3_rme() -> void:
	_step = Step.STAGE3_RME
	_title.text = INSTRUKSI_3
	# Tabel pola lebih rapat: perkecil sementara agar seluruh tabel terbaca.
	_dialog.add_theme_font_size_override("font_size", 22)
	_dialog.text = TEKS["stage3_intro"]

	for c in _quiz_row.get_children():
		c.queue_free()

	var options := [
		{"text": "A. V = Keliling Alas × t", "valid": false},
		{"text": "B. V = Luas Alas × t", "valid": true},
		{"text": "C. V = ⅓ × Luas Alas × t", "valid": false},
	]

	for opt in options:
		var btn := Button.new()
		btn.text = opt["text"]
		btn.custom_minimum_size = Vector2(260, 60)
		btn.pressed.connect(_on_stage3_chosen.bind(btn, opt["valid"]))
		_quiz_row.add_child(btn)
	_quiz_row.show()


func _on_stage3_chosen(btn: Button, is_valid: bool) -> void:
	if _step != Step.STAGE3_RME:
		return
	if not is_valid:
		btn.disabled = true
		_dialog.text = "Tempong: Belum tepat, Nak. Perhatikan baris terakhir tabel: volumenya selalu hasil kali luas alas dengan tinggi prisma."
		return
	_quiz_row.hide()
	_dialog.text = TEKS["stage3_benar"]
	await get_tree().create_timer(2.0).timeout
	_start_evaluation()


# ------------------------------------------------------------ Evaluasi Akhir Level 3
func _start_evaluation() -> void:
	_step = Step.EVALUATION
	_eval_index = 0
	_dialog.add_theme_font_size_override("font_size", 24)
	_dialog.text = TEKS["eval_intro"]
	await get_tree().create_timer(1.4).timeout
	_show_eval_question()


func _show_eval_question() -> void:
	for c in _quiz_row.get_children():
		c.queue_free()

	var opts: Array = []
	if _eval_index == 0:
		_title.text = "Evaluasi Level 3 - Soal 1 (Luas Alas)"
		_dialog.text = "Bagian depan atap Rumah Betang berbentuk segitiga dengan alas 8 meter dan tinggi 3 meter. Berapa luas alas segitiga tersebut?"
		opts = [
			{"text": "A. 11 m²", "valid": false},
			{"text": "B. 12 m²", "valid": true},
			{"text": "C. 24 m²", "valid": false},
		]
	elif _eval_index == 1:
		_title.text = "Evaluasi Level 3 - Soal 2 (Volume Ruang)"
		_dialog.text = "Jika panjang bangunan ke belakang adalah 20 meter, berapakah volume ruang di bawah atap tersebut?"
		opts = [
			{"text": "A. 120 m³", "valid": false},
			{"text": "B. 240 m³", "valid": true},
			{"text": "C. 480 m³", "valid": false},
		]

	for o in opts:
		var btn := Button.new()
		btn.text = o["text"]
		btn.custom_minimum_size = Vector2(220, 60)
		btn.pressed.connect(_on_eval_chosen.bind(btn, o["valid"]))
		_quiz_row.add_child(btn)
	_quiz_row.show()


func _on_eval_chosen(btn: Button, is_valid: bool) -> void:
	if _step != Step.EVALUATION:
		return
	if not is_valid:
		btn.disabled = true
		_dialog.text = "Tempong: Jawaban belum tepat, ayo hitung kembali dengan cermat!"
		return

	_eval_index += 1
	if _eval_index < 2:
		_show_eval_question()
	else:
		_quiz_row.hide()
		_step = Step.DONE
		_finish_level()


# ------------------------------------------------------------ Layar Level Selesai
func _finish_level() -> void:
	var stars := 3
	ProgressManager.complete_level(LEVEL_ID, stars, SCORE_COMPLETE)

	_title.hide()
	_progress.hide()
	_btn_selesai.hide()
	if _dialog_panel:
		_dialog_panel.hide()

	_reward_title.text = "Selamat Telah Menyelesaikan Level %d" % LEVEL_ID
	_reward_stars.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	_reward_info.text = (
		"Kamu berhasil menguasai bangun ruang Prisma Segitiga!\n"
		+ "Gelar terbuka: \"Arsitek Muda Arsitektur Dayak Nusantara\"\n"
		+ "Pencapaian: 3 Bintang Sempurna!"
	)

	_reward_layer.modulate.a = 0.0
	_reward_layer.show()
	var tween := create_tween()
	tween.tween_property(_reward_layer, "modulate:a", 1.0, 0.4)


func _on_reward_next() -> void:
	SceneTransition.reset_for_new_level()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_reward_menu() -> void:
	SceneTransition.reset_for_new_level()
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)


func _style_reward() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("382317")
	style.border_color = Color("e6b65b")
	style.set_border_width_all(4)
	style.set_corner_radius_all(20)
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	_reward_panel.add_theme_stylebox_override("panel", style)

	_reward_title.add_theme_font_size_override("font_size", 34)
	_reward_title.add_theme_color_override("font_color", Color("ffe2a1"))
	_reward_stars.add_theme_font_size_override("font_size", 64)
	_reward_stars.add_theme_color_override("font_color", Color("ffcf35"))
	_reward_info.add_theme_font_size_override("font_size", 22)
	_reward_info.add_theme_color_override("font_color", Color("fff4df"))


func _on_kembali() -> void:
	get_tree().change_scene_to_file(BACK_SCENE)


# ------------------------------------------------------------ Input & Touch
func _unhandled_input(event: InputEvent) -> void:
	if _step == Step.ANIM:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_press_pos = event.position
			_drag_dist = 0.0
		else:
			_dragging = false
			if (
				_step == Step.EXPLORE
				and event.position.distance_to(_press_pos) < TAP_MAX_MOVE
				and _drag_dist < TAP_MAX_MOVE
			):
				_pending_tap = true
				_tap_pos = event.position
	elif event is InputEventMouseMotion and _dragging:
		# Putar model hanya bila pemain benar-benar menyeret, bukan saat
		# sekadar menekan (sentuhan kecil) untuk memilih bagian.
		_drag_dist = maxf(_drag_dist, event.position.distance_to(_press_pos))
		if _drag_dist < TAP_MAX_MOVE:
			return
		_active_root.rotate_y(event.relative.x * 0.01)
		_active_root.rotate_object_local(Vector3.RIGHT, event.relative.y * 0.01)


func _physics_process(_delta: float) -> void:
	if not _pending_tap:
		return
	_pending_tap = false
	var from := _camera.project_ray_origin(_tap_pos)
	var to := from + _camera.project_ray_normal(_tap_pos) * 200.0 * _unit
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var kind: String = hit["collider"].get_meta("kind", "")
	if kind != "":
		_on_part_touched(kind)


# ------------------------------------------------------------ Net Option 2D
class PrismaNetOption extends Button:
	const UNIT := 16.0
	const ORIGIN := Vector2(26.0, 50.0)
	const WOOD := Color(0.62, 0.40, 0.20)
	const DARK := Color(0.16, 0.09, 0.03)
	const GOLD := Color(1.0, 0.9, 0.6)

	var pieces: Array = []
	var option_label := ""

	func _draw() -> void:
		for piece in pieces:
			if piece["t"] == "rect":
				var r := Rect2(
					ORIGIN + (piece["p"] as Vector2) * UNIT,
					(piece["s"] as Vector2) * UNIT
				)
				# Garis pemisah panel selalu tegak lurus sumbu panjang strip.
				var sep_vertical := (piece["s"] as Vector2).x >= (piece["s"] as Vector2).y
				draw_rect(r, WOOD)
				for sep in piece["sep"]:
					var off: float = float(sep) * UNIT
					if sep_vertical:
						var sx: float = r.position.x + off
						draw_line(
							Vector2(sx, r.position.y), Vector2(sx, r.end.y), DARK, 3.0
						)
					else:
						var sy: float = r.position.y + off
						draw_line(
							Vector2(r.position.x, sy), Vector2(r.end.x, sy), DARK, 3.0
						)
				draw_rect(r, DARK, false, 2.0)
			else:
				var pts := PackedVector2Array([
					ORIGIN + (piece["b"] as Vector2) * UNIT,
					ORIGIN + (piece["e"] as Vector2) * UNIT,
					ORIGIN + (piece["a"] as Vector2) * UNIT,
				])
				draw_colored_polygon(pts, WOOD)
				var outline := pts.duplicate()
				outline.append(pts[0])
				draw_polyline(outline, DARK, 2.0)

		var font := get_theme_font("font")
		if font == null:
			font = ThemeDB.fallback_font
		draw_string(
			font,
			Vector2(10.0, 18.0),
			option_label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			22,
			GOLD
		)
