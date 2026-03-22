extends Button
@onready var placement = preload("res://Building/placement.tscn")
@export var to_build: PackedScene

var switch = false
var placer = null

func _on_pressed() -> void:
	if is_instance_valid(placer) and placer.is_inside_tree():
		placer.deactivate()
		placer.queue_free()
		placer = null
	else:
		placer = placement.instantiate()
		#placer.to_build = to_build
		get_tree().current_scene.add_child(placer)
