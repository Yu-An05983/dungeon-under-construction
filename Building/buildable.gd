extends Node
class_name Buildable

func rotate_clockwise():
	pass

func rotate_counter():
	pass

func can_place(location: Vector2):
	return !BuildingCoordinator.check_location(location)

func place(location: Vector2):
	pass
