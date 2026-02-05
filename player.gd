extends CharacterBody2D

const SPEED = 2500.0
const ACCEL = 6.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var input: Vector2
var is_attacking := false

func get_input():
	input.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	return input.normalized()

func _process(delta):
	look_at(get_global_mouse_position())
	rotation_degrees -= 90
	var playerInput = get_input()

	velocity = lerp(velocity, playerInput * SPEED, delta * ACCEL)
	move_and_slide()

	if Input.is_action_just_pressed("left click") and not is_attacking:
		attack_loop()
	elif not is_attacking:
		if sprite.animation != "Default":
			sprite.play("Default")

func attack_loop():
	is_attacking = true

	while Input.is_action_pressed("left click"):
		sprite.play("Attack")
		await sprite.animation_finished

	sprite.play("Default")
	is_attacking = false
