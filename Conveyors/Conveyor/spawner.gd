extends Node2D

@onready var conveyor_system: Node = $"../ConveyorSystem"
@onready var tilemap: TileMap = $"../BeltMap"

@export var spawn_interval := 1.0
@export var item_texture := preload("res://Art/Resources/lithos.png")

var timer := 0.0
var directions := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

func _ready():
	await get_tree().process_frame
	setup_conveyor_path()

func setup_conveyor_path():
	var my_tile = tilemap.local_to_map(global_position / tilemap.scale.x)
	
	for dir in directions:
		var target_tile = my_tile + dir
		if conveyor_system.is_conveyor(target_tile):
			conveyor_system._generate_path_from_tiles(target_tile)
			return

func _process(delta):
	timer += delta
	if timer >= spawn_interval:
		if conveyor_system.spawn_item(item_texture):
			timer = 0.0
