extends Camera2D

var zoom_amount = Vector2(0.08,0.08)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("zoom in"):
		zoom += zoom_amount
	if Input.is_action_just_pressed("zoom out"):
		zoom -= zoom_amount
	if zoom <= Vector2(0.12,0.12):
		zoom = Vector2(0.12,0.12)
