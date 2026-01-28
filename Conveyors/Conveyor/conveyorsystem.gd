extends Node2D

@onready var path: Path2D = $Path2D
@onready var tilemap: TileMap = $"../BeltMap"

@export var speed := 150.0        
@export var item_spacing := 40.0  

var items: Array = []

func _generate_path_from_tiles(start_tile: Vector2i):
	var curve = Curve2D.new()
	var current_tile = start_tile
	var visited = [] 
	var map_scale = tilemap.scale.x

	while is_conveyor(current_tile) and not current_tile in visited:
		visited.append(current_tile)
		var pos = tilemap.map_to_local(current_tile) * map_scale
		curve.add_point(pos)
		var data = tilemap.get_cell_tile_data(0, current_tile)
		if not data: break
		var raw_dir = data.get_custom_data("dir")
		var dir = Vector2i(raw_dir) if raw_dir != null else Vector2i.ZERO
		if dir == Vector2i.ZERO: break
		current_tile += dir
		
	path.curve = curve

func _process(delta):
	var path_length = path.curve.get_baked_length()
	if path_length <= 0: return
	for i in range(items.size()):
		var item = items[i]
		var can_move = true
		if i == 0:
			if item.follower.progress >= path_length:
				can_move = false
		else:
			var leader = items[i-1]
			if item.follower.progress + (speed * delta) > leader.follower.progress - item_spacing:
				can_move = false
				item.follower.progress = leader.follower.progress - item_spacing
		if can_move:
			item.follower.progress += speed * delta
		item.follower.progress = clamp(item.follower.progress, 0, path_length)

func spawn_item(texture: Texture2D) -> bool:
	if path.curve.get_baked_length() < 10: return false
	if items.size() > 0:
		if items[-1].follower.progress < item_spacing:
			return false 

	var follower = PathFollow2D.new()
	follower.loop = false
	follower.rotates = false
	follower.v_offset = 0.0
	follower.h_offset = 2.0
	path.add_child(follower)
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(3.0, 3.0) 
	
	sprite.centered = true
	sprite.offset = Vector2.ZERO 
	
	follower.add_child(sprite)
	items.append({"follower": follower})
	return true

func is_conveyor(tile: Vector2i) -> bool:
	var data := tilemap.get_cell_tile_data(0, tile) 
	return data != null and data.get_custom_data("type") == "conveyor"
