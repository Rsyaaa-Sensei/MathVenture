extends CharacterBody2D
 
@export var npc_name := "Amure"
@export var player_name := "Tari"
@export var sprite_frames: SpriteFrames
@export var lines: Array[String] = []
@export_file("*.tscn") var next_scene: String
@export var speed := 60.0
@export var wander_radius := 150.0  # batas jauh NPC dari titik awalnya
 
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var talk_area: Area2D = $TalkArea
@onready var talk_button: Button = get_tree().current_scene.get_node("InteractionUI/TalkButton")
@onready var home := global_position
 
var player: Node2D = null
var player_nearby := false
var direction := Vector2.ZERO
var facing := Vector2.DOWN
var timer := 0.0
 
 
func _ready() -> void:
	if sprite_frames:
		sprite.sprite_frames = sprite_frames
	talk_button.hide()
	talk_area.body_entered.connect(_on_body_entered)
	talk_area.body_exited.connect(_on_body_exited)
	talk_button.pressed.connect(_talk)
	_pick_next()
 
 
func _physics_process(delta: float) -> void:
	# Berhenti dan menghadap pemain saat dekat atau sedang dialog
	if DialogBox.active or player_nearby:
		velocity = Vector2.ZERO
		if player_nearby and player:
			facing = player.global_position - global_position
		_play("idle")
		return
 
	timer -= delta
	if timer <= 0.0 or (is_on_wall() and direction != Vector2.ZERO):
		_pick_next()
 
	velocity = direction * speed
	move_and_slide()
	_play("walk" if direction != Vector2.ZERO else "idle")
 
 
func _pick_next() -> void:
	timer = randf_range(1.0, 2.5)
	if global_position.distance_to(home) > wander_radius:
		direction = (home - global_position).normalized()
	elif randf() < 0.4:
		direction = Vector2.ZERO  # diam sebentar
	else:
		direction = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT].pick_random()
	if direction != Vector2.ZERO:
		facing = direction
 
 
func _play(state: String) -> void:
	var suffix := "down"
	if abs(facing.x) > abs(facing.y):
		suffix = "right" if facing.x > 0 else "left"
	elif facing.y < 0:
		suffix = "up"
 
	var directional := "%s_%s" % [state, suffix]
	if sprite.sprite_frames.has_animation(directional):
		sprite.play(directional)
	elif sprite.sprite_frames.has_animation(state):
		sprite.play(state)
		sprite.flip_h = facing.x < 0  # fallback kalau cuma ada 1 arah
 
 
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		player_nearby = true
		talk_button.show()
 
 
func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_nearby = false
		talk_button.hide()
 
 
func _talk() -> void:
	if not player_nearby or DialogBox.active:
		return
	talk_button.hide()
	SceneTransition.mark_npc_talked(npc_name)
	DialogBox.start(lines, {npc_name: self, player_name: player})
	await DialogBox.finished
	SceneTransition.mark_npc_talked(npc_name)
	if not next_scene.is_empty():
		get_tree().change_scene_to_file(next_scene)
	elif player_nearby:
		talk_button.show()
 
