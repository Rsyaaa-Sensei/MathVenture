extends Node3D
## Level 2 (Balok - Rumoh Aceh) - Selesai.
## Mengakomodasi Stage 1 (Unsur), Stage 2 (Jaring-jaring),
## Stage 3 (RME Volume), dan Evaluasi Akhir.

@export var box_scene: PackedScene

const BACK_SCENE := "res://scenes/world/rumah_aceh.tscn"
const MAIN_MENU_SCENE := "res://scenes/mainmenu/main_menu.tscn"
const LEVEL_SELECT_SCENE := "res://scenes/mainmenu/level_select.tscn"
const FONT_PATH := "res://assets/font/BoldPixels.ttf"
const LEVEL_ID := 2
const SCORE_COMPLETE := 100
const CAM_CLOSED := Vector3(2.3, 1.8, 3.0)
const CAM_OPEN := Vector3(0.0, 7.5, 2.7)
const TAP_MAX_MOVE := 12.0

enum Step { EXPLORE, ANIM, QUIZ_NET, STAGE3_RME, EVALUATION, DONE }

const INSTRUKSI_1 := "Sentuh bagian-bagian kotak balok untuk meneliti komponen pembentuknya."
const INSTRUKSI_2 := "Pilih pola lembaran kayu yang bisa dilipat kembali menjadi kotak balok."
const INSTRUKSI_3 := "Analisis pola susunan kotak untuk menemukan rumus volume balok!"

const TEKS := {
	"sisi": "Cut Nyak: Peti ini dibatasi oleh 6 bidang persegi panjang. Sisi-sisi yang berhadapan memiliki bentuk dan ukuran yang sama persis (kongruen).",
	"rusuk": "Cut Nyak: Terdapat 12 rusuk, namun tidak semuanya sama panjang! Rusuk dikelompokkan menjadi tiga ukuran: Panjang (p), Lebar (l), dan Tinggi (t).",
	"sudut": "Arka: Terdapat 8 titik sudut pertemuan kerangka di setiap pojok peti.",
	"kesimpulan": "Cut Nyak: Luar biasa, Arka! Berbeda dengan kubus yang semua rusuknya sama, bangun ruang dengan sisi berhadapan sama panjang dan memiliki unsur Panjang, Lebar, dan Tinggi ini disebut BALOK.\n\nTekan \"Bongkar Kotak\" untuk melihat jaring-jaringnya.",
	"bongkar": "Arka: Wah, kotaknya terbuka menjadi lembaran-lembaran persegi panjang! Kalau semua sisinya direbahkan ke bidang datar tanpa terlepas, terbentuklah jaring-jaring balok.\nCut Nyak: Benar, Nak. Sekarang pilih pola yang bisa dilipat kembali menjadi balok yang utuh.",
	"salah": "Cut Nyak: Hmm, belum tepat. Bayangkan melipatnya satu per satu \u2014 adakah sisi yang bertumpuk atau tidak punya pasangan?",
	"benar": "Cut Nyak: Tepat sekali! Pola itu melipat menjadi kotak balok yang utuh.",
	"stage3_intro": "Cut Nyak: Jika panjang kotak p, lebarnya l, dan tingginya t, berapakah total volume di dalamnya?",
	"stage3_benar": "Cut Nyak: Tepat sekali! Volume balok adalah V = p \u00d7 l \u00d7 t.",
	"eval_intro": "Cut Nyak: Coba selesaikan dua perhitungan terakhir ini sebelum kotak ini kita kirim."
}

const NETS := {
	"valid": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(1, 2)],
	"blok": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
	"lurus": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1)],
}

@onready var _camera: Camera3D = $Camera3D
@onready var _light: DirectionalLight3D = $DirectionalLight3D
@onready var _pivot: Node3D = $BoxPivot
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
var _active_root: Node3D
var _mats: Dictionary = {}
var _base_colors: Dictionary = {}
var _hi_colors: Dictionary = {}
var _flash_tw: Dictionary = {}
var _net_pivots: Dictionary = {}

var _seen := {"sisi": false, "rusuk": false, "sudut": false}
var _step := Step.EXPLORE
var _dragging := false
var _press_pos := Vector2.ZERO
var _pending_tap := false
var _tap_pos := Vector2.ZERO
var _eval_index := 0


func _ready() -> void:
	_apply_theme()
	_light.rotation_degrees = Vector3(-45, 35, 0)
	_load_model()
	_build_skeleton()
	_build_net()
	_active_root = _pivot

	_camera.near = 0.01 * _unit
	_camera.far = 200.0 * _unit
	_camera.position = CAM_CLOSED * _cam_scale
	_camera.look_at(Vector3.ZERO)

	_btn_bongkar.text = "Bongkar Kotak"
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
	_dialog.text = "Cut Nyak: Arka, coba amati peti kayu ini. Sentuh bagian-bagiannya untuk mengenali unsur-unsur balok, ya."
	_update_progress()


func _apply_theme() -> void:
	var th := Theme.new()
	if ResourceLoader.exists(FONT_PATH):
		th.default_font = load(FONT_PATH)
		th.default_font_size = 32
		th.set_color("font_color", "Label", Color(1.0, 1.0, 1.0, 1.0))
	_hud.theme = th
	_reward_layer.theme = th


# ------------------------------------------------------------ Model .glb
func _load_model() -> void:
	# Gunakan model yang sudah ada di scene terlebih dahulu agar tidak dobel.
	var existing: Node = get_node_or_null("balok_objek")
	if existing is Node3D:
		_model = existing as Node3D
		if _model.get_parent() != _pivot:
			_model.reparent(_pivot, false)
	elif box_scene:
		_model = box_scene.instantiate() as Node3D
		if _model:
			_pivot.add_child(_model)
	else:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(3, 2, 2)
		mi.mesh = bm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.62, 0.40, 0.20)
		mi.material_override = m
		_model = mi
		_pivot.add_child(_model)

	if _model == null:
		push_error("Model balok tidak ditemukan. Tambahkan balok_objek ke scene atau isi box_scene.")
		return

	var box := _compute_aabb()
	if box.size == Vector3.ZERO:
		box = AABB(Vector3(-1.5, -1, -1), Vector3(3, 2, 2))
	_model.position -= box.get_center()
	_half = box.size / 2.0
	_unit = maxf((_half.x + _half.y + _half.z) / 3.0, 0.01)
	_cam_scale = maxf(maxf(_half.x, _half.y), maxf(_half.z, 0.01))


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


func _build_skeleton() -> void:
	_register_kind("sisi", Color(1.0, 0.85, 0.35, 0.0), Color(1.0, 0.85, 0.35, 0.55))
	_register_kind("rusuk", Color(0.85, 0.85, 0.92, 0.55), Color(1.0, 0.45, 0.1, 1.0))
	_register_kind("sudut", Color(1.0, 0.8, 0.2, 0.75), Color(1.0, 0.2, 0.35, 1.0))

	var rangka := Node3D.new()
	_pivot.add_child(rangka)
	var h := _half * 1.005

	var faces := [
		[Vector3(0, 0, h.z), Vector3(0, 0, 0), Vector2(h.x * 2, h.y * 2)],
		[Vector3(0, 0, -h.z), Vector3(0, 180, 0), Vector2(h.x * 2, h.y * 2)],
		[Vector3(h.x, 0, 0), Vector3(0, 90, 0), Vector2(h.z * 2, h.y * 2)],
		[Vector3(-h.x, 0, 0), Vector3(0, -90, 0), Vector2(h.z * 2, h.y * 2)],
		[Vector3(0, h.y, 0), Vector3(-90, 0, 0), Vector2(h.x * 2, h.z * 2)],
		[Vector3(0, -h.y, 0), Vector3(90, 0, 0), Vector2(h.x * 2, h.z * 2)],
	]
	for f in faces:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = f[2]
		mi.mesh = q
		mi.material_override = _mats["sisi"]
		mi.position = f[0]
		mi.rotation_degrees = f[1]
		rangka.add_child(mi)
		var bs := BoxShape3D.new()
		bs.size = Vector3(q.size.x, q.size.y, 0.04 * _unit)
		_add_collider(mi, "sisi", bs)

	var t := 0.05 * _unit
	for a in [-1.0, 1.0]:
		for b in [-1.0, 1.0]:
			_add_edge(rangka, Vector3(h.x * 2, t, t), Vector3(0, a * h.y, b * h.z))
			_add_edge(rangka, Vector3(t, h.y * 2, t), Vector3(a * h.x, 0, b * h.z))
			_add_edge(rangka, Vector3(t, t, h.z * 2), Vector3(a * h.x, b * h.y, 0))

	for x in [-1.0, 1.0]:
		for y in [-1.0, 1.0]:
			for z in [-1.0, 1.0]:
				var mi := MeshInstance3D.new()
				var s := SphereMesh.new()
				s.radius = 0.07 * _unit
				s.height = 0.14 * _unit
				mi.mesh = s
				mi.material_override = _mats["sudut"]
				mi.position = Vector3(x * h.x, y * h.y, z * h.z)
				rangka.add_child(mi)
				var ss := SphereShape3D.new()
				ss.radius = 0.22 * _unit
				_add_collider(mi, "sudut", ss)


func _add_edge(parent: Node3D, size: Vector3, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mats["rusuk"]
	mi.position = pos
	parent.add_child(mi)
	var min_tap := 0.16 * _unit
	var bs := BoxShape3D.new()
	bs.size = Vector3(maxf(size.x, min_tap), maxf(size.y, min_tap), maxf(size.z, min_tap))
	_add_collider(mi, "rusuk", bs)


# ------------------------------------------------------------ Stage 1
func _on_part_touched(kind: String) -> void:
	_flash(kind)
	_seen[kind] = true
	_dialog.text = TEKS[kind]
	_update_progress()
	if _seen["sisi"] and _seen["rusuk"] and _seen["sudut"]:
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
	for k in ["sisi", "rusuk", "sudut"]:
		parts.append(("● " if _seen[k] else "○ ") + k.capitalize())
	_progress.text = " ".join(parts)


# ------------------------------------------------------------ Stage 2: Jaring-jaring
func _build_net() -> void:
	_net.scale = Vector3.ONE
	var hx := _half.x
	var hy := _half.y
	var hz := _half.z

	var base := Node3D.new()
	base.position = Vector3(0, -hy, 0)
	_net.add_child(base)
	_add_flat_face(base, Vector3.ZERO, Vector2(hx * 2, hz * 2))

	_net_pivots["depan"] = [_make_pivot(base, Vector3(0, 0, hz), Vector2(hx * 2, hy * 2), Vector3(0, 0, hy)), "x", -90.0]
	_net_pivots["belakang"] = [_make_pivot(base, Vector3(0, 0, -hz), Vector2(hx * 2, hy * 2), Vector3(0, 0, -hy)), "x", 90.0]
	_net_pivots["kanan"] = [_make_pivot(base, Vector3(hx, 0, 0), Vector2(hy * 2, hz * 2), Vector3(hy, 0, 0)), "z", 90.0]
	_net_pivots["kiri"] = [_make_pivot(base, Vector3(-hx, 0, 0), Vector2(hy * 2, hz * 2), Vector3(-hy, 0, 0)), "z", -90.0]
	var depan: Node3D = _net_pivots["depan"][0]
	_net_pivots["atas"] = [_make_pivot(depan, Vector3(0, 0, hy * 2), Vector2(hx * 2, hz * 2), Vector3(0, 0, hz)), "x", -90.0]


func _make_pivot(parent: Node3D, hinge_pos: Vector3, size: Vector2, face_off: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = hinge_pos
	parent.add_child(pivot)
	_add_flat_face(pivot, face_off, size)
	return pivot


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
		if n == "atas":
			_set_pivot_angle(n, clampf((t - 0.3) / 0.7, 0.0, 1.0))
		else:
			_set_pivot_angle(n, clampf(t / 0.7, 0.0, 1.0))
	_camera.position = CAM_CLOSED.lerp(CAM_OPEN, t) * _cam_scale
	_camera.look_at(Vector3(0, -0.5 * t, 0.8 * t) * _cam_scale)


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
	await _animate_net(true)
	_build_quiz_net()
	_step = Step.QUIZ_NET


func _build_quiz_net() -> void:
	for c in _quiz_row.get_children():
		c.queue_free()
	var keys: Array = NETS.keys()
	keys.shuffle()
	var labels := ["A", "B", "C"]
	for i in keys.size():
		var o := NetOption.new()
		o.cells = NETS[keys[i]]
		o.text = labels[i]
		o.alignment = HORIZONTAL_ALIGNMENT_LEFT
		o.custom_minimum_size = Vector2(150, 90)
		o.pressed.connect(_on_net_chosen.bind(o, keys[i] == "valid"))
		_quiz_row.add_child(o)
	_quiz_row.show()


func _on_net_chosen(option: Button, is_valid: bool) -> void:
	if _step != Step.QUIZ_NET:
		return
	if not is_valid:
		option.disabled = true
		_dialog.text = TEKS["salah"]
		return
	_quiz_row.hide()
	_dialog.text = TEKS["benar"]
	await _animate_net(false)
	_start_stage3_rme()


# ------------------------------------------------------------ Stage 3: Abstraksi Volume RME
func _start_stage3_rme() -> void:
	_step = Step.STAGE3_RME
	_title.text = INSTRUKSI_3
	_dialog.text = TEKS["stage3_intro"]

	for c in _quiz_row.get_children():
		c.queue_free()

	var options := [
		{"text": "A. V = 6 × s", "valid": false},
		{"text": "B. V = p × l × t", "valid": true},
		{"text": "C. V = 12 × (p + l + t)", "valid": false}
	]

	for opt in options:
		var btn := Button.new()
		btn.text = opt["text"]
		btn.custom_minimum_size = Vector2(220, 60)
		btn.pressed.connect(_on_stage3_chosen.bind(btn, opt["valid"]))
		_quiz_row.add_child(btn)
	_quiz_row.show()


func _on_stage3_chosen(btn: Button, is_valid: bool) -> void:
	if _step != Step.STAGE3_RME:
		return
	if not is_valid:
		btn.disabled = true
		_dialog.text = "Cut Nyak: Kurang tepat, Nak. Ingat, balok punya panjang, lebar, dan tinggi yang berbeda."
		return
	_quiz_row.hide()
	_dialog.text = TEKS["stage3_benar"]
	await get_tree().create_timer(2.0).timeout
	_start_evaluation()


# ------------------------------------------------------------ Evaluasi Akhir Level 2
func _start_evaluation() -> void:
	_step = Step.EVALUATION
	_eval_index = 0
	_show_eval_question()


func _show_eval_question() -> void:
	for c in _quiz_row.get_children():
		c.queue_free()

	if _eval_index == 0:
		_title.text = "Evaluasi Level 2 - Soal 1 (Kerangka Rusuk)"
		_dialog.text = "Sebuah kotak balok memiliki panjang 8 m, lebar 5 m, dan tinggi 3 m. Berapa panjang total seluruh 12 rusuknya?"
		var opts := [
			{"text": "A. 32 meter", "valid": false},
			{"text": "B. 64 meter", "valid": true},
			{"text": "C. 80 meter", "valid": false}
		]
		for o in opts:
			var btn := Button.new()
			btn.text = o["text"]
			btn.pressed.connect(_on_eval_chosen.bind(btn, o["valid"]))
			_quiz_row.add_child(btn)
	elif _eval_index == 1:
		_title.text = "Evaluasi Level 2 - Soal 2 (Kapasitas Volume)"
		_dialog.text = "Sebuah balok berukuran panjang 6 m, lebar 4 m, dan tinggi 3 m. Jika setiap 1 m³ dapat memuat 20 buah, berapa jumlah maksimal yang bisa dimuat?"
		var opts := [
			{"text": "A. 720 buah", "valid": false},
			{"text": "B. 1.440 buah", "valid": true},
			{"text": "C. 2.160 buah", "valid": false}
		]
		for o in opts:
			var btn := Button.new()
			btn.text = o["text"]
			btn.pressed.connect(_on_eval_chosen.bind(btn, o["valid"]))
			_quiz_row.add_child(btn)
	_quiz_row.show()


func _on_eval_chosen(btn: Button, is_valid: bool) -> void:
	if _step != Step.EVALUATION:
		return
	if not is_valid:
		btn.disabled = true
		_dialog.text = "Cut Nyak: Jawaban belum tepat, ayo hitung kembali dengan cermat!"
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
		"Kamu berhasil menguasai bangun ruang Balok!\n"
		+ "Level berikutnya telah terbuka di peta."
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
		else:
			_dragging = false
			if _step == Step.EXPLORE and event.position.distance_to(_press_pos) < TAP_MAX_MOVE:
				_pending_tap = true
				_tap_pos = event.position
	elif event is InputEventMouseMotion and _dragging:
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
class NetOption extends Button:
	const UNIT := 20
	var cells: Array = []

	func _draw() -> void:
		for c in cells:
			var r := Rect2(Vector2(44, 12) + Vector2(c) * UNIT, Vector2(UNIT, UNIT)).grow(-1.0)
			draw_rect(r, Color(0.62, 0.40, 0.20))
			draw_rect(r, Color(0.2, 0.1, 0.0), false, 1.0)
