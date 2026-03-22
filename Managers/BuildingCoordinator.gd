extends Node
class Buildable:
	pass

var buildings = {}
var is_pressed = false

func check_location(location: Vector2) -> bool:
	return buildings.has(location)

func add_building(location: Vector2, building: Node2D) -> void:
	print("AHHH")
	buildings[location] = building
