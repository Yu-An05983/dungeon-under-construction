extends Buildable

var to_direction: Enums.Direction = Enums.Direction.Left
var from_direction: Enums.Direction = Enums.Direction.Right
var trash = preload("res://Conveyors/trash.tscn")

func _ready():
	pass

func can_place(location: Vector2):
	return !BuildingCoordinator.check_location(location)

func place(location: Vector2):
	var delete = trash.instantiate()
	var directions: Array[Enums.Direction] = [to_direction]
	delete.global_position = location
	# do something different to control where it gets added
	get_tree().current_scene.add_child(delete)
	
func _on_direction_controller_directions_changed(to_directions: Array[Enums.Direction]):
	update_to_direction(to_directions)
	
func update_to_direction(to_directions: Array[Enums.Direction]):
	to_direction = to_directions[0]
	$ConveyorSpriteController.set_sprite_frame(to_direction, from_direction)

func rotate_clockwise():
	$DirectionController.rotate_right()

func rotate_counter():
	$DirectionController.rotate_left()
