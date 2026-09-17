extends CharacterBody2D

@export var speed: float = 150.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_direction: String = "Depan"  # animasi default saat idle

func _physics_process(delta: float) -> void:
	var input_vector = Vector2.ZERO

	if Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_vector.x += 1
	if Input.is_key_pressed(KEY_W):
		input_vector.y -= 1
	if Input.is_key_pressed(KEY_S):
		input_vector.y += 1

	input_vector = input_vector.normalized()
	velocity = input_vector * speed

	move_and_slide()

	update_animation(input_vector)


func update_animation(input_vector: Vector2) -> void:
	if input_vector != Vector2.ZERO:
		# tentukan arah dominan (horizontal vs vertikal)
		if abs(input_vector.x) > abs(input_vector.y):
			if input_vector.x > 0:
				last_direction = "Kanan"
			else:
				last_direction = "Kiri"
		else:
			if input_vector.y > 0:
				last_direction = "Depan"
			else:
				last_direction = "Belakang"

		animated_sprite.play("Jalan " + last_direction)
	else:
		animated_sprite.play("Idle " + last_direction)
