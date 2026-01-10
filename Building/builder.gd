extends Node2D
@export var available_color : Color = Color.GREEN
@export var taken_color : Color = Color.RED
@export var alpha = 128
@onready var to_build : PackedScene
@onready var buildable : Buildable
var last_location
var building
	
func _ready():
	building = to_build.instantiate() as Buildable
	add_child(building)
	available_color.a = alpha
	taken_color.a = alpha
	modulate = available_color

func _physics_process(_delta):
	var pos = get_global_mouse_position()
	var location = Vector2(int(pos.x/Constants.grid_size2), int(pos.y/Constants.grid_size2)) * Constants.grid_size2
	if last_location == location:
		return
	global_position = location
	if building.can_place(location):
		modulate = available_color
	else:
		modulate = taken_color
	if last_location == null:
		last_location = location
	if Input.is_action_just_pressed("rotate"):
		building.rotate_clockwise()
	if Input.is_action_pressed("left click"):
		if building.can_place(location):
			building.place(location)
	if Input.is_action_pressed("right click"):
		queue_free()
		BuildingCoordinator.is_pressed = false
