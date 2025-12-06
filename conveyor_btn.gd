extends Button
@onready var to_build = preload("res://Building/builder.tscn")
var is_pressed = false
var build_instance : Node2D = null
func _on_pressed() -> void:
	is_pressed = !is_pressed
	print(is_pressed)
	if is_pressed == true:
		build_instance = to_build.instantiate()
		get_tree().current_scene.add_child(build_instance)
	else:
		if build_instance:
			build_instance.queue_free()
			build_instance = null
	
