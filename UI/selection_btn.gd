extends Button
@onready var builder = preload("res://Building/builder.tscn")
@export var to_build: PackedScene
var build_instance
func _on_pressed() -> void:
	if BuildingCoordinator.is_pressed == false:
		BuildingCoordinator.is_pressed = !BuildingCoordinator.is_pressed
		print(BuildingCoordinator.is_pressed)
		build_instance = builder.instantiate()
		build_instance.to_build = to_build
		get_tree().current_scene.add_child(build_instance)
	else:
		if build_instance:
			BuildingCoordinator.is_pressed = !BuildingCoordinator.is_pressed
			print(BuildingCoordinator.is_pressed)
			build_instance.queue_free()
			build_instance = null
	
