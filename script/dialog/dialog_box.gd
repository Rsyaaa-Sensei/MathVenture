extends CanvasLayer

signal finished

const MARGIN := 12.0

@onready var panel: Control = $Panel
@onready var name_label: Label = $Panel/VBox/NameLabel
@onready var text_label: Label = $Panel/VBox/TextLabel
@onready var next_button: Button = $Panel/VBox/NextButton

var active := false
var _lines: Array[String] = []
var _index := 0
var _tween: Tween
var _speakers: Dictionary = {}
var _default_target: Node2D = null
var _target: Node2D = null


func _ready() -> void:
	panel.hide()
	next_button.pressed.connect(_on_next_pressed)


# speakers: {"Nama": node}, supaya bubble muncul di bawah node yang bicara
func start(lines: Array[String], speakers: Dictionary = {}) -> void:
	if active or lines.is_empty():
		return
	_lines = lines
	_index = 0
	_speakers = speakers
	_default_target = speakers.values()[0] if not speakers.is_empty() else null
	active = true
	panel.show()
	next_button.grab_focus()
	_show_line()


func _show_line() -> void:
	var parts := _lines[_index].split("|", true, 1)
	var speaker := parts[0] if parts.size() > 1 else ""
	name_label.text = speaker
	text_label.text = parts[parts.size() - 1]
	text_label.visible_ratio = 0.0
	_target = _speakers.get(speaker, _default_target)
	panel.reset_size()
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(text_label, "visible_ratio", 1.0, text_label.text.length() * 0.02)


func _process(_delta: float) -> void:
	if active:
		_update_position()


func _update_position() -> void:
	var vp := get_viewport().get_visible_rect().size
	if _target == null or not is_instance_valid(_target):
		panel.position = Vector2((vp.x - panel.size.x) / 2.0, vp.y - panel.size.y - 30.0)
		return
	var screen := get_viewport().get_canvas_transform() * _bottom_position(_target)
	
	# Posisi Y ditaruh tepat di bawah kaki/dasar target + MARGIN
	var pos := Vector2(screen.x - panel.size.x / 2.0, screen.y + MARGIN)
	
	# Clamp agar panel tidak terpotong di tepi layar (kiri, kanan, atas, bawah)
	pos.x = clampf(pos.x, 8.0, vp.x - panel.size.x - 8.0)
	pos.y = clampf(pos.y, 8.0, vp.y - panel.size.y - 8.0)
	panel.position = pos


func _bottom_position(target: Node2D) -> Vector2:
	var sprite := target.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite and sprite.sprite_frames:
		var tex := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		if tex:
			var h := tex.get_height() * absf(sprite.global_scale.y)
			# Mengambil posisi alas/kaki karakter (posisi pusat + setengah tinggi sprite)
			return sprite.global_position + Vector2(0, h / 2.0)
	# Jika tidak ada sprite, default menggunakan offset bawah
	return target.global_position + Vector2(0, 20)


func _on_next_pressed() -> void:
	if text_label.visible_ratio < 1.0:
		_tween.kill()
		text_label.visible_ratio = 1.0
		return
	_index += 1
	if _index >= _lines.size():
		panel.hide()
		active = false
		finished.emit()
	else:
		_show_line()
