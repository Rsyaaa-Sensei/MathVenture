extends Node3D
## Level 4 (Limas Segiempat - Kue Iwel-iwel, Jawa Timur).
## Stage 1 (unsur limas), Stage 2 (jaring-jaring + mini game pilih bentangan),
## Stage 3 (percobaan menuang takaran RME + rumus volume), lalu Evaluasi Akhir.

@export var limas_scene: PackedScene

const BACK_SCENE := "res://scenes/world/pendopo_jawa_timur.tscn"
const MAIN_MENU_SCENE := "res://scenes/mainmenu/main_menu.tscn"
const LEVEL_SELECT_SCENE := "res://scenes/mainmenu/level_select.tscn"
const FONT_PATH := "res://assets/font/BoldPixels.ttf"
const LEVEL_ID := 4
const SCORE_COMPLETE := 100
const CAMERA_DIR := Vector3(0.55, 0.5, 0.66)
const CAMERA_DISTANCE_SCALE := 3.4
const TAP_MAX_MOVE := 12.0

enum Step { EXPLORE, ANIM, QUIZ_NET, STAGE3_POUR, STAGE3_FORMULA, EVALUATION, DONE }

const PARTS: Array[String] = ["sisi_alas", "sisi_tegak", "titik_puncak"]

const PART_LABEL := {
	"sisi_alas": "Sisi Alas",
	"sisi_tegak": "Sisi Tegak",
	"titik_puncak": "Titik Puncak",
}

const INSTRUKSI_1 := "Klik bagian-bagian Kue Iwel-iwel untuk mengidentifikasi unsur limas!"
const INSTRUKSI_2 := "Pilih bentangan lembaran datar yang bisa dilipat kembali menjadi limas segiempat."
const INSTRUKSI_3 := "Cermati percobaan menuang takaran berikut untuk menemukan rumus volume limas!"

const TEKS := {
	"sisi_alas": "Mbok Ratih: Bagian bawah kue ini berbentuk bidang datar (bisa persegi atau segitiga) yang menjadi fondasi dasar bentuknya. Inilah SISI ALAS.",
	"sisi_tegak": "Mbok Ratih: Sisi-sisi selimutnya berbentuk segitiga yang miring dan bertemu pada satu titik di bagian atas. Inilah SISI TEGAK, yaitu bidang miringnya.",
	"titik_puncak": "Mbok Ratih: Dan ini TITIK PUNCAK, yaitu titik pertemuan paling atas tempat seluruh sisi tegak segitiga bersatu.",
	"kesimpulan": "Arka: Luar biasa! Berbeda dengan prisma yang punya alas dan tutup yang sama, bangun ruang yang sisi tegaknya mengerucut ke satu titik puncak ini disebut LIMAS.\n\nTekan \"Bongkar Kue\" untuk melihat jaring-jaringnya.",
	"bongkar": "Arka: Wah, pembungkus daun pisangnya terbuka menjadi lembaran datar! Jika seluruh sisi limas direbahkan ke bidang datar, terbentuklah jaring-jaring limas.\nMbok Ratih: Benar, Nak. Sekarang uji ketelitianmu. Pilih bentangan yang bisa dilipat kembali menjadi limas segiempat yang utuh!",
	"salah": "Mbok Ratih: Hmm, belum tepat, Nak. Ingat, limas segiempat butuh satu alas persegi dan empat sisi tegak segitiga. Tidak boleh ada yang kurang atau saling bertumpuk.",
	"benar": "Mbok Ratih: Tepat sekali! Bentangan itu melipat kembali menjadi limas segiempat yang utuh.",
	"stage3_intro": "Mbok Ratih: Arka, jika kita mengisi cetakan limas iwel-iwel ini dengan beras ketan, kira-kira berapa kali lipat cetakan limas harus dituangkan untuk mengisi penuh cetakan balok/prisma yang ukurannya sama?",
	"pour_1": "Arka: Baru 1 takaran limas. Wadah balok baru terisi sebagian, belum penuh.",
	"pour_2": "Arka: 2 takaran limas. Masih ada ruang kosong di dalam wadah balok.",
	"pour_3": "Arka: Pas 3 takaran limas, wadah balok terisi penuh tanpa sisa!",
	"stage3_table": "Arka: Ternyata butuh 3 kali volume limas untuk memenuhi 1 volume prisma yang alas dan tingginya sama.\n\nPerbandingan Wadah | Hubungan Matematis\nVolume Prisma vs Limas | 3 \u00d7 VolumeLimas = VolumePrisma, sehingga VolumeLimas = 1/3 \u00d7 VolumePrisma\nRumus Akhir | VolumeLimas = 1/3 \u00d7 LuasAlas \u00d7 Tinggi",
	"stage3_benar": "Arka: Tepat sekali! Karena volume limas adalah sepertiga dari prisma dengan alas dan tinggi yang sama, maka rumus volume limas adalah V = 1/3 \u00d7 Luas Alas \u00d7 Tinggi.",
	"eval_intro": "Mbok Ratih: Matur nuwun, Nak Arka! Sekarang, bantu saya menghitung kapasitas wadah besar penampung adonan kue iwel-iwel yang berbentuk limas segiempat ini sebelum festival dimulai."
}

@onready var _camera: Camera3D = $Camera3D
@onready var _light: DirectionalLight3D = $DirectionalLight3D
@onready var _pivot: Node3D = $LimasPivot
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
var _cam_open := Vector3(0.0, 7.5, 0.02)
var _cam_look_closed := Vector3.ZERO
var _cam_look_open := Vector3.ZERO

# Profil limas segiempat: alas persegi selebar 2*_bx pada y = _base_y,
# puncak di y = _apex_y.
var _bx := 1.0
var _bz := 1.0
var _base_y := -1.0
var _apex_y := 1.0
var _height := 2.0
var _slant := 1.0

var _active_root: Node3D
var _mats: Dictionary = {}
var _base_colors: Dictionary = {}
var _hi_colors: Dictionary = {}
var _flash_tw: Dictionary = {}

var _flaps: Array = []
var _flap_index: Dictionary = {}
var _net_base_pts := PackedVector3Array()

var _seen := {"sisi_alas": false, "sisi_tegak": false, "titik_puncak": false}
var _step := Step.EXPLORE
var _dragging := false
var _drag_dist := 0.0
var _press_pos := Vector2.ZERO
var _pending_tap := false
var _tap_pos := Vector2.ZERO
var _eval_index := 0
var _pour_count := 0
var _wadah: WadahDraw


func _ready() -> void:
	_apply_theme()
	_light.rotation_degrees = Vector3(-40, 35, 0)
	_load_model()
	_measure_profile()
	_build_skeleton()
	_build_net()
	_active_root = _pivot

	_camera.near = 0.01 * _unit
	_camera.far = 200.0 * _unit
	_camera.position = _cam_closed
	_camera.look_at(_cam_look_closed)

	_wadah = WadahDraw.new()
	_wadah.visible = false
	_wadah.position = Vector2(70, 150)
	_wadah.size = Vector2(240, 380)
	_wadah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_wadah)

	_btn_bongkar.text = "Bongkar Kue"
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
	_dialog.text = "Mbok Ratih: Arka, coba amati kue Iwel-iwel berbungkus daun pisang ini. Sentuh bagian-bagiannya untuk mengenali unsur-unsur limas, ya."
	_layout_bottom("default")
	_update_progress()


## Atur posisi baris pilihan. Panel dialog selalu mengecil/membesar mengikuti
## panjang teksnya sendiri. "net": pilihan di atas - "default": pilihan di bawah.
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
	var existing: Node = get_node_or_null("limas_objek")
	if existing is Node3D:
		_model = existing as Node3D
		if _model.get_parent() != _pivot:
			_model.reparent(_pivot, false)
	elif limas_scene:
		_model = limas_scene.instantiate() as Node3D
		if _model:
			_pivot.add_child(_model)
	else:
		_model = _make_fallback_limas()
		_pivot.add_child(_model)

	if _model == null:
		push_error("Model limas tidak ditemukan. Tambahkan limas_objek ke scene atau isi limas_scene.")
		return

	# Model iwel-iwel diekspor Z-up (alas di bidang XY). Putar agar puncaknya
	# menghadap ke atas (+Y) seperti bangun limas yang berdiri.
	_model.rotation_degrees = Vector3(-90, 0, 0)

	var box := _compute_aabb()
	if box.size == Vector3.ZERO:
		box = AABB(Vector3(-1.25, -1.1, -1.25), Vector3(2.5, 2.2, 2.5))
	_model.position -= box.get_center()
	_half = box.size / 2.0
	_unit = maxf((_half.x + _half.y + _half.z) / 3.0, 0.01)
	_cam_scale = maxf(maxf(_half.x, _half.y), _half.z)


func _make_fallback_limas() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(2.5, 0.01, 2.5)
	mi.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.62, 0.40, 0.20)
	mi.material_override = m
	return mi


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
	_bx = maxf(_half.x, 0.05)
	_bz = maxf(_half.z, 0.05)
	_base_y = -maxf(_half.y, 0.05)
	_apex_y = -_base_y
	_height = maxf(_apex_y - _base_y, 0.05)
	_slant = sqrt(_height * _height + _bx * _bx)

	# Bingkai kamera saat limas berdiri dan saat jaring-jaring terbentang.
	_cam_closed = CAMERA_DIR.normalized() * (_cam_scale * CAMERA_DISTANCE_SCALE)
	_cam_look_closed = Vector3(0.0, -_cam_scale * 0.35, 0.0)

	var extent := maxf(_bx + _slant, _bz + _slant)
	_cam_open = Vector3(0.0, extent * 2.9, 0.02)
	_cam_look_open = Vector3(0.0, _base_y, 0.0)


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


func _add_tri(parent: Node3D, a: Vector3, b: Vector3, c: Vector3, kind: String) -> void:
	var normal := (b - a).cross(c - a).normalized()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([a, b, c])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([normal, normal, normal])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mats[kind]
	parent.add_child(mi)

	var t := 0.02 * _unit
	var pts := PackedVector3Array([
		a + normal * t, b + normal * t, c + normal * t,
		a - normal * t, b - normal * t, c - normal * t,
	])
	var shape := ConvexPolygonShape3D.new()
	shape.points = pts
	_add_collider(mi, kind, shape)


func _add_quad(parent: Node3D, a: Vector3, b: Vector3, c: Vector3, d: Vector3, kind: String) -> void:
	_add_tri(parent, a, b, c, kind)
	_add_tri(parent, a, c, d, kind)


func _build_skeleton() -> void:
	_register_kind("sisi_alas", Color(1.0, 0.85, 0.35, 0.0), Color(1.0, 0.85, 0.35, 0.6))
	_register_kind("sisi_tegak", Color(0.45, 0.75, 1.0, 0.0), Color(0.45, 0.75, 1.0, 0.6))
	_register_kind("titik_puncak", Color(1.0, 0.55, 0.2, 0.7), Color(1.0, 0.25, 0.2, 1.0))

	var rangka := Node3D.new()
	rangka.name = "Kerangka"
	_pivot.add_child(rangka)

	var apex := Vector3(0.0, _apex_y, 0.0)
	var p0 := Vector3(-_bx, _base_y, -_bz)
	var p1 := Vector3(_bx, _base_y, -_bz)
	var p2 := Vector3(_bx, _base_y, _bz)
	var p3 := Vector3(-_bx, _base_y, _bz)

	# Sisi alas: persegi di dasar limas.
	_add_quad(rangka, p0, p1, p2, p3, "sisi_alas")

	# Empat sisi tegak: segitiga dari tiap rusuk alas menuju titik puncak.
	_add_tri(rangka, p0, p1, apex, "sisi_tegak")
	_add_tri(rangka, p1, p2, apex, "sisi_tegak")
	_add_tri(rangka, p2, p3, apex, "sisi_tegak")
	_add_tri(rangka, p3, p0, apex, "sisi_tegak")

	# Titik puncak.
	var mi := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.09 * _unit
	sph.height = 0.18 * _unit
	mi.mesh = sph
	mi.material_override = _mats["titik_puncak"]
	mi.position = apex
	rangka.add_child(mi)
	var ss := SphereShape3D.new()
	ss.radius = 0.3 * _unit
	_add_collider(mi, "titik_puncak", ss)


# ------------------------------------------------------------ Stage 1
func _on_part_touched(kind: String) -> void:
	if kind.is_empty() or not TEKS.has(kind):
		return
	_flash(kind)
	_seen[kind] = true
	_dialog.text = TEKS[kind]
	_update_progress()
	if _seen["sisi_alas"] and _seen["sisi_tegak"] and _seen["titik_puncak"]:
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
	_flaps.clear()
	_flap_index.clear()

	var base := Node3D.new()
	base.name = "AlasDatar"
	_net.add_child(base)

	var q0 := Vector3(-_bx, _base_y, -_bz)
	var q1 := Vector3(_bx, _base_y, -_bz)
	var q2 := Vector3(_bx, _base_y, _bz)
	var q3 := Vector3(-_bx, _base_y, _bz)
	_net_base_pts = PackedVector3Array([q0, q1, q2, q3])
	_add_net_quad(base, Color(0.45, 0.28, 0.13))

	# Definisi tiap sisi tegak: rusuk engsel (a,b), sumbu, arah keluar, dan
	# titik-titik sisanya. Puncak dihitung sebagai fungsi lipatan.
	_add_flap(base, q3, q2, "z", 1.0)
	_add_flap(base, q1, q0, "z", -1.0)
	_add_flap(base, q2, q1, "x", 1.0)
	_add_flap(base, q0, q3, "x", -1.0)

	_set_net_fold(1.0)


func _add_flap(parent: Node3D, a: Vector3, b: Vector3, axis: String, out_dir: float) -> void:
	var mi := MeshInstance3D.new()
	mi.material_override = _make_mat(Color(0.62, 0.40, 0.20))
	parent.add_child(mi)

	var d := _slant
	if axis == "x":
		d = sqrt(_height * _height + _bx * _bx)
	else:
		d = sqrt(_height * _height + _bz * _bz)
	var hinge := _height
	if axis == "x":
		hinge = atan2(_height, -_bx)
	else:
		hinge = atan2(_height, -_bz)

	_flaps.append({
		"mi": mi,
		"a": a,
		"b": b,
		"axis": axis,
		"sign": out_dir,
		"d": d,
		"phi": hinge,
	})


func _net_tip(flap: Dictionary, fold: float) -> Vector3:
	var phi: float = float(flap["phi"]) * fold
	var d: float = float(flap["d"])
	var s: float = float(flap["sign"])
	var y: float = _base_y + d * sin(phi)
	if flap["axis"] == "z":
		return Vector3(0.0, y, s * (_bz + d * cos(phi)))
	return Vector3(s * (_bx + d * cos(phi)), y, 0.0)


func _set_net_fold(fold: float) -> void:
	for flap in _flaps:
		var a: Vector3 = flap["a"]
		var b: Vector3 = flap["b"]
		var tip := _net_tip(flap, fold)
		var mi: MeshInstance3D = flap["mi"]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([a, b, tip])
		var n := (b - a).cross(tip - a).normalized()
		arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([n, n, n])
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mi.mesh = mesh


func _add_net_quad(parent: Node3D, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		_net_base_pts[0], _net_base_pts[1], _net_base_pts[2],
		_net_base_pts[0], _net_base_pts[2], _net_base_pts[3],
	])
	var normals := PackedVector3Array()
	for i in 6:
		normals.append(Vector3.UP)
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mi.mesh = mesh
	mi.material_override = _make_mat(color)
	parent.add_child(mi)


func _net_step(t: float) -> void:
	_set_net_fold(1.0 - t)
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
	_title.text = INSTRUKSI_2
	_dialog.text = TEKS["bongkar"]
	_layout_bottom("net")
	await _animate_net(true)
	_build_quiz_net()
	_step = Step.QUIZ_NET


func _build_quiz_net() -> void:
	for c in _quiz_row.get_children():
		c.queue_free()
	var keys: Array[String] = ["valid", "kurang", "segitiga"]
	keys.shuffle()
	var labels := ["A", "B", "C"]
	for i in keys.size():
		var o := LimasNetOption.new()
		o.pieces = _net_option_pieces(keys[i])
		o.option_label = labels[i]
		o.custom_minimum_size = Vector2(190, 158)
		o.pressed.connect(_on_net_chosen.bind(o, keys[i] == "valid"))
		_quiz_row.add_child(o)
	_quiz_row.show()


func _net_option_pieces(kind: String) -> Array:
	# Tata letak dalam satuan sel (persegi alas sisi 3). Sisi tegak berupa
	# segitiga dengan alas 3 dan tinggi 2,6.
	var top := [
		Vector2(0, 0), Vector2(3, 0), Vector2(1.5, -2.6),
	]
	var bottom := [
		Vector2(0, 3), Vector2(3, 3), Vector2(1.5, 5.6),
	]
	var left := [
		Vector2(0, 0), Vector2(0, 3), Vector2(-2.6, 1.5),
	]
	var right := [
		Vector2(3, 0), Vector2(3, 3), Vector2(5.6, 1.5),
	]
	var square := [
		Vector2(0, 0), Vector2(3, 0), Vector2(3, 3), Vector2(0, 3),
	]
	var center_tri := [
		Vector2(0, 0), Vector2(3, 0), Vector2(1.5, 2.6),
	]
	var tri_bottom := [
		Vector2(0, 0), Vector2(3, 0), Vector2(1.5, -2.6),
	]
	var tri_left := [
		Vector2(0, 0), Vector2(1.5, 2.6), Vector2(-1.5, 2.6),
	]
	var tri_right := [
		Vector2(3, 0), Vector2(1.5, 2.6), Vector2(4.5, 2.6),
	]
	match kind:
		"valid":
			return [square, top, bottom, left, right]
		"kurang":
			# Hanya 3 sisi tegak: satu sisi tidak punya penutup.
			return [square, top, left, right]
		"segitiga":
			# Alas diganti segitiga (jaring limas segitiga, bukan segiempat).
			return [center_tri, tri_bottom, tri_left, tri_right]
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
	_start_stage3_pour()


# ------------------------------------------------------------ Stage 3: Percobaan Menuang RME
func _start_stage3_pour() -> void:
	_step = Step.STAGE3_POUR
	_title.text = INSTRUKSI_3
	_dialog.add_theme_font_size_override("font_size", 22)
	_dialog.text = TEKS["stage3_intro"]
	_pour_count = 0
	_wadah.filled = 0
	_wadah.visible = true
	_wadah.queue_redraw()

	for c in _quiz_row.get_children():
		c.queue_free()

	for i in range(3):
		var btn := Button.new()
		btn.text = "Tuang Takaran %d" % (i + 1)
		btn.custom_minimum_size = Vector2(210, 60)
		btn.disabled = i > 0
		btn.pressed.connect(_on_pour.bind(i))
		_quiz_row.add_child(btn)
	_quiz_row.show()


func _on_pour(index: int) -> void:
	if _step != Step.STAGE3_POUR or index != _pour_count:
		return
	_pour_count += 1
	_wadah.filled = _pour_count
	_wadah.queue_redraw()

	for c in _quiz_row.get_children():
		var btn := c as Button
		if btn and btn.text == "Tuang Takaran %d" % (_pour_count + 1):
			btn.disabled = false

	if _pour_count == 1:
		_dialog.text = TEKS["pour_1"]
	elif _pour_count == 2:
		_dialog.text = TEKS["pour_2"]
	else:
		_dialog.text = TEKS["pour_3"]
		for c in _quiz_row.get_children():
			(c as Button).disabled = true
		await get_tree().create_timer(1.6).timeout
		_start_stage3_formula()


func _start_stage3_formula() -> void:
	_step = Step.STAGE3_FORMULA
	_dialog.text = TEKS["stage3_table"]

	for c in _quiz_row.get_children():
		c.queue_free()

	var options := [
		{"text": "A. V = \u2153 \u00d7 Luas Alas \u00d7 t", "valid": true},
		{"text": "B. V = Luas Alas \u00d7 t", "valid": false},
		{"text": "C. V = 3 \u00d7 Luas Alas \u00d7 t", "valid": false},
	]
	for opt in options:
		var btn := Button.new()
		btn.text = opt["text"]
		btn.custom_minimum_size = Vector2(240, 60)
		btn.pressed.connect(_on_stage3_formula_chosen.bind(btn, opt["valid"]))
		_quiz_row.add_child(btn)
	_quiz_row.show()


func _on_stage3_formula_chosen(btn: Button, is_valid: bool) -> void:
	if _step != Step.STAGE3_FORMULA:
		return
	if not is_valid:
		btn.disabled = true
		_dialog.text = "Arka: Belum tepat. Ingat, 3 takaran limas baru bisa memenuhi 1 wadah prisma, jadi volume limas = 1/3 volume prisma."
		return
	_quiz_row.hide()
	_wadah.visible = false
	_dialog.text = TEKS["stage3_benar"]
	await get_tree().create_timer(2.0).timeout
	_start_evaluation()


# ------------------------------------------------------------ Evaluasi Akhir Level 4
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
		_title.text = "Evaluasi Level 4 - Soal 1 (Unsur & Rusuk)"
		_dialog.text = "Sebuah cetakan kue berbentuk limas dengan alas persegi memiliki panjang sisi alas 6 cm dan panjang rusuk tegaknya 5 cm. Berapa total jumlah seluruh rusuk pada limas segiempat tersebut? (Ingat: limas segiempat punya 4 rusuk alas dan 4 rusuk tegak.)"
		opts = [
			{"text": "A. 24 cm", "valid": false},
			{"text": "B. 40 cm", "valid": false},
			{"text": "C. 44 cm", "valid": true},
		]
	elif _eval_index == 1:
		_title.text = "Evaluasi Level 4 - Soal 2 (Volume Realistis)"
		_dialog.text = "Sebuah wadah adonan kue tradisional berbentuk limas segiempat memiliki luas alas 30 cm\u00b2 dan tinggi wadah 12 cm. Berapa volume maksimal adonan yang dapat ditampung wadah tersebut?"
		opts = [
			{"text": "A. 120 cm\u00b3", "valid": true},
			{"text": "B. 360 cm\u00b3", "valid": false},
			{"text": "C. 720 cm\u00b3", "valid": false},
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
		_dialog.text = "Mbok Ratih: Jawaban belum tepat, ayo hitung kembali dengan cermat!"
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
		"Kamu berhasil menguasai bangun ruang Limas Segiempat!\n"
		+ "Lencana Utama Dibuka: \"Grand Master Arsitek & Budayawan Bangun Ruang Sisi Datar Nusantara\"\n"
		+ "Rating Sempurna: 3 Bintang di Semua Level!\n"
		+ "\"Selamat! Kamu telah menyelesaikan petualangan MathVenture menjelajahi kekayaan budaya Indonesia melalui matematika!\""
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
	_reward_info.add_theme_font_size_override("font_size", 20)
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


# ------------------------------------------------------------ Visual Wadah (Stage 3)
class WadahDraw extends Control:
	var filled := 0

	const FRAME := Color(0.16, 0.09, 0.03)
	const EMPTY := Color(0.24, 0.16, 0.09, 0.65)
	const FILL := Color(0.96, 0.72, 0.26, 0.95)
	const LABEL := Color(1.0, 0.94, 0.82)

	func _draw() -> void:
		var box := Rect2(Vector2(30, 60), Vector2(180, 270))
		draw_rect(box, EMPTY)
		var band_h := box.size.y / 3.0
		for i in range(filled):
			var y := box.position.y + box.size.y - float(i + 1) * band_h
			draw_rect(Rect2(box.position.x, y, box.size.x, band_h), FILL)
		for i in range(4):
			var y := box.position.y + box.size.y - float(i) * band_h
			draw_line(Vector2(box.position.x, y), Vector2(box.end.x, y), FRAME, 2.0)
		draw_rect(box, FRAME, false, 4.0)
		var font := ThemeDB.fallback_font
		draw_string(
			font, Vector2(30, 40), "Wadah Prisma (Balok)",
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, LABEL
		)
		draw_string(
			font, Vector2(30, 360), "Terisi: %d/3 takaran limas" % filled,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, LABEL
		)


# ------------------------------------------------------------ Net Option 2D
class LimasNetOption extends Button:
	const UNIT := 15.0
	const ORIGIN := Vector2(30.0, 96.0)
	const WOOD := Color(0.62, 0.40, 0.20)
	const DARK := Color(0.16, 0.09, 0.03)
	const GOLD := Color(1.0, 0.9, 0.6)

	var pieces: Array = []
	var option_label := ""

	func _draw() -> void:
		for piece in pieces:
			var pts := PackedVector2Array()
			for p in piece:
				pts.append(ORIGIN + (p as Vector2) * UNIT)
			if pts.size() >= 3:
				draw_colored_polygon(pts, WOOD)
				var outline := pts.duplicate()
				outline.append(pts[0])
				draw_polyline(outline, DARK, 2.0)

		var font := get_theme_font("font")
		if font == null:
			font = ThemeDB.fallback_font
		draw_string(
			font,
			Vector2(10.0, 24.0),
			option_label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			22,
			GOLD
		)
