extends Buildable

var to_direction: Enums.Direction = Enums.Direction.Left
var from_direction: Enums.Direction = Enums.Direction.Right
var generator = preload("res://Conveyors/generator.tscn")

func _ready():
	pass

func can_place(location: Vector2):
	return !BuildingCoordinator.check_location(location)

func place(location: Vector2):
	var gen = generator.instantiate()
	var directions: Array[Enums.Direction] = [to_direction]
	gen.directions = directions
	gen.global_position = location
	# do something different to control where it gets added
	get_tree().current_scene.add_child(gen)

func _on_direction_controller_directions_changed(to_directions: Array[Enums.Direction]):
	update_to_direction(to_directions)
	
func update_to_direction(to_directions: Array[Enums.Direction]):
	to_direction = to_directions[0]
	$ConveyorSpriteController.has_sheet = false
	$ConveyorSpriteController.set_sprite_frame(to_direction, from_direction)

func rotate_clockwise():
	$DirectionController.rotate_right()

func rotate_counter():
	$DirectionController.rotate_left()
