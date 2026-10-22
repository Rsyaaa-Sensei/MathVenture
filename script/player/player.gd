
extends CharacterBody2D

@export var speed: float = 180.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_direction: Vector2 = Vector2.DOWN

func _physics_process(_delta: float) -> void:
	if DialogBox.active:
		velocity = Vector2.ZERO
		update_idle_animation()
		return 
	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
        "move_down"
	)

	velocity = input_direction * speed
	move_and_slide()

	if input_direction.length_squared() > 0.0:
		last_direction = input_direction
		update_walk_animation(input_direction)
	else:
		update_idle_animation()

func update_walk_animation(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		sprite.play("walk_right")
		sprite.flip_h = dir.x < 0.0
	elif dir.y < 0.0:
		sprite.flip_h = false
		sprite.play("walk_up")
	else:
		sprite.flip_h = false
		sprite.play("walk_down")

func update_idle_animation() -> void:
	if abs(last_direction.x) > abs(last_direction.y):
		sprite.play("idle_right")
		sprite.flip_h = last_direction.x < 0.0
	elif last_direction.y < 0.0:
		sprite.flip_h = false
		sprite.play("idle_up")
	else:
		sprite.flip_h = false
		sprite.play("idle_down")
