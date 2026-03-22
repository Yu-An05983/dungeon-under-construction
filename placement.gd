extends Node2D

@onready var conveyor_system = $"../ConveyorSystem"
@onready var tilemap = $"../BeltMap"
@export var conveyor_source_id: int = 6
var to_build: PackedScene
var tile_incoming_dirs: Dictionary = {}
var active: bool = false

var hologram_node: Node2D = null

var current_dir: Vector2i = Vector2i(1, 0)
var cursor_sprite: Sprite2D = null  # Follows mouse always
var directions: Array = [
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0),
	Vector2i(0, -1)
]

#For Dragging
var last_tile: Vector2i
var last_tile_set: bool = false
var last_dir: Vector2i = Vector2i.ZERO
var is_dragging: bool = false
var is_hologram_mode: bool = false
var hologram_tiles: Array = []
var just_confirmed: bool = false

func _ready():
	hologram_node = Node2D.new()
	hologram_node.z_index = 10
	get_tree().current_scene.add_child(hologram_node)
	cursor_sprite = Sprite2D.new()
	cursor_sprite.z_index = 10
	hologram_node.add_child(cursor_sprite)
	await get_tree().process_frame
	active = true

func _process(_delta):
	if not active:
		return
	if is_hologram_mode:
		_update_drag_hologram_preview()
		cursor_sprite.visible = false
		if Input.is_action_just_pressed("left click"):
			_confirm_hologram()
			just_confirmed = true
		elif Input.is_action_just_pressed("right click"):
			_cancel_hologram()
		return

	if just_confirmed:
		if Input.is_action_just_released("left click"):
			just_confirmed = false
		return

	cursor_sprite.visible = not is_dragging
	_update_cursor_hologram()
	
	if Input.is_action_just_pressed("rotate"):
		_rotate_direction()

	if Input.is_action_just_pressed("left click"):
		var mouse_pos = tilemap.get_local_mouse_position()
		var tile = tilemap.local_to_map(mouse_pos)
		last_tile = tile
		last_tile_set = true
		last_dir = Vector2i.ZERO
		if is_conveyor(tile):
			var data: TileData = tilemap.get_cell_tile_data(0, tile)
			if data:
				last_dir = Vector2i(data.get_custom_data("dir"))
	
	if Input.is_action_pressed("left click") and last_tile_set: #Holding down
		var mouse_pos = tilemap.get_local_mouse_position()
		var tile = tilemap.local_to_map(mouse_pos)
		if tile != last_tile and not is_dragging:
			is_dragging = true
		if is_dragging:
			cursor_sprite.visible = false
			_build_hologram()
			_update_drag_hologram_preview()

	elif Input.is_action_just_released("left click"): #Release
		if is_dragging and hologram_tiles.size() > 0:
			# Enter hologram confirm mode
			is_hologram_mode = true
			cursor_sprite.visible = false
		elif not is_dragging and last_tile_set:
			_place_single_tile()
		is_dragging = false
		if not is_hologram_mode:
			_reset_drag()

func _rotate_direction():
	var idx = directions.find(current_dir)
	idx = (idx + 1) % directions.size()
	current_dir = directions[idx]

func _is_invalid_placement(tile: Vector2i) -> bool:
	var incoming = _get_external_incoming(tile)
	if incoming == Vector2i.ZERO:
		return false
	return incoming == -current_dir

func _update_cursor_hologram():
	var mouse_pos = tilemap.get_local_mouse_position()
	var tile = tilemap.local_to_map(mouse_pos)
	var world_pos = tilemap.to_global(tilemap.map_to_local(tile))
	cursor_sprite.global_position = world_pos

	var incoming = _get_external_incoming(tile)
	if incoming == Vector2i.ZERO or incoming == current_dir:
		incoming = current_dir
	elif incoming == -current_dir:
		incoming = current_dir

	if _is_invalid_placement(tile):
		_apply_sprite(cursor_sprite, incoming, current_dir, Color(1.0, 0.2, 0.2, 0.6))  #Red
	else:
		_apply_sprite(cursor_sprite, incoming, current_dir, Color(0.3, 0.7, 1.0, 0.6))  #Blue

func _place_single_tile():
	var mouse_pos = tilemap.get_local_mouse_position()
	var tile = tilemap.local_to_map(mouse_pos)

	if _is_invalid_placement(tile):
		return 

	var incoming = _get_external_incoming(tile)
	if incoming == Vector2i.ZERO or incoming == current_dir:
		incoming = current_dir

	set_conveyor_direction(tile, incoming, current_dir)
	tile_incoming_dirs[tile] = incoming
	update_neighbors(tile)

	var next_tile = tile + current_dir
	if is_conveyor(next_tile):
		var next_data: TileData = tilemap.get_cell_tile_data(0, next_tile)
		if next_data:
			var next_outgoing = Vector2i(next_data.get_custom_data("dir"))
			tile_incoming_dirs[next_tile] = current_dir
			set_conveyor_direction(next_tile, current_dir, next_outgoing)

func _build_hologram():
	var mouse_pos = tilemap.get_local_mouse_position()
	var end_tile = tilemap.local_to_map(mouse_pos)

	if not last_tile_set:
		last_tile = end_tile
		last_tile_set = true
		return

	if end_tile == last_tile:
		return

	var current = last_tile
	var diff = end_tile - last_tile
	var steps_x = abs(diff.x)
	var steps_y = abs(diff.y)
	var step_x = Vector2i(sign(diff.x), 0)
	var step_y = Vector2i(0, sign(diff.y))

	var path: Array = []
	var temp = last_tile
	while temp.x != end_tile.x:
		temp += step_x
		path.append(temp)
	while temp.y != end_tile.y:
		temp += step_y
		path.append(temp)

	for t in path:
		_add_hologram_tile(t)

func _add_hologram_tile(tile: Vector2i):
	if is_conveyor(tile):
		last_tile = tile
		return

	var dir = tile - last_tile
	if dir.x != 0:
		dir = Vector2i(sign(dir.x), 0)
	else:
		dir = Vector2i(0, sign(dir.y))

	if hologram_tiles.size() == 0:
		var first_incoming = last_dir if last_dir != Vector2i.ZERO else dir
		for offset in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var neighbor = last_tile + offset
			if not is_conveyor(neighbor):
				continue
			var ndata: TileData = tilemap.get_cell_tile_data(0, neighbor)
			if not ndata:
				continue
			var ndir = Vector2i(ndata.get_custom_data("dir"))
			if neighbor + ndir == last_tile:
				first_incoming = ndir
				break
		hologram_tiles = hologram_tiles.filter(func(e): return e.tile != last_tile)
		hologram_tiles.append({
			"tile": last_tile,
			"atlas": Vector2i(0, get_atlas_row(first_incoming, dir)),
			"alternative": 0,
			"dir": dir,
			"incoming": first_incoming,
			"invalid": false
		})
	else:
		var prev = hologram_tiles[-1]
		if prev["tile"] == last_tile:
			prev["dir"] = dir
			prev["atlas"] = Vector2i(0, get_atlas_row(prev["incoming"], dir))

	var incoming = dir
	for offset in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		var neighbor = tile + offset
		if not is_conveyor(neighbor):
			continue
		var ndata: TileData = tilemap.get_cell_tile_data(0, neighbor)
		if not ndata:
			continue
		var ndir = Vector2i(ndata.get_custom_data("dir"))
		if neighbor + ndir == tile:
			incoming = ndir
			break

	var invalid = false
	var ext_incoming = _get_external_incoming(tile)
	if ext_incoming != Vector2i.ZERO and ext_incoming == -dir:
		invalid = true

	hologram_tiles = hologram_tiles.filter(func(e): return e.tile != tile)
	hologram_tiles.append({
		"tile": tile,
		"atlas": Vector2i(0, get_atlas_row(incoming, dir)),
		"alternative": 0,
		"dir": dir,
		"incoming": incoming,
		"invalid": invalid
	})

	last_dir = dir
	last_tile = tile
func _update_drag_hologram_preview():
	for child in hologram_node.get_children():
		if child != cursor_sprite:
			child.queue_free()

	var source = tilemap.tile_set.get_source(conveyor_source_id) as TileSetAtlasSource
	if not source:
		return

	for entry in hologram_tiles:
		var sprite = Sprite2D.new()
		var world_pos = tilemap.to_global(tilemap.map_to_local(entry["tile"]))
		sprite.global_position = world_pos
		var color = Color(1.0, 0.2, 0.2, 0.5) if entry.get("invalid", false) else Color(0.3, 0.7, 1.0, 0.5)
		_apply_sprite(sprite, entry["incoming"], entry["dir"], color)
		hologram_node.add_child(sprite)

func _confirm_hologram():
	for entry in hologram_tiles:
		if entry.get("invalid", false):
			continue
		tilemap.set_cell(0, entry["tile"], conveyor_source_id, entry["atlas"], entry["alternative"])
		var data: TileData = tilemap.get_cell_tile_data(0, entry["tile"])
		if data:
			data.set_custom_data("type", "conveyor")
			data.set_custom_data("dir", entry["dir"])
			data.set_custom_data("incoming", entry["incoming"])
		tile_incoming_dirs[entry["tile"]] = entry["incoming"]

	for entry in hologram_tiles:
		if entry.get("invalid", false):
			continue
		update_neighbors(entry["tile"])
		var next_tile = entry["tile"] + entry["dir"]
		if is_conveyor(next_tile) and not _is_in_hologram(next_tile):
			var next_data: TileData = tilemap.get_cell_tile_data(0, next_tile)
			if next_data:
				var next_outgoing = Vector2i(next_data.get_custom_data("dir"))
				tile_incoming_dirs[next_tile] = entry["dir"]
				set_conveyor_direction(next_tile, entry["dir"], next_outgoing)

	_clear_hologram()

func _apply_sprite(sprite: Sprite2D, from_dir: Vector2i, to_dir: Vector2i, color: Color):
	var source = tilemap.tile_set.get_source(conveyor_source_id) as TileSetAtlasSource
	if not source:
		return
	var tile_size = tilemap.tile_set.tile_size
	var atlas = Vector2i(0, get_atlas_row(from_dir, to_dir))
	sprite.texture = source.texture
	sprite.region_enabled = true
	sprite.region_rect = Rect2(
		atlas.x * tile_size.x,
		atlas.y * tile_size.y,
		tile_size.x,
		tile_size.y
	)
	sprite.modulate = color
	sprite.scale = Vector2(tilemap.scale.x, tilemap.scale.y)

func _cancel_hologram():
	_clear_hologram()

func _clear_hologram():
	hologram_tiles.clear()
	for child in hologram_node.get_children():
		if child != cursor_sprite:
			child.queue_free()
	is_hologram_mode = false
	_reset_drag()

func _reset_drag():
	last_tile_set = false
	last_dir = Vector2i.ZERO

func _is_in_hologram(tile: Vector2i) -> bool:
	for entry in hologram_tiles:
		if entry.tile == tile:
			return true
	return false

func _get_external_incoming(tile: Vector2i) -> Vector2i:
	for offset in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		var neighbor = tile + offset
		if not is_conveyor(neighbor):
			continue
		var ndata: TileData = tilemap.get_cell_tile_data(0, neighbor)
		if not ndata:
			continue
		var ndir = Vector2i(ndata.get_custom_data("dir"))
		if neighbor + ndir == tile:
			return ndir
	return Vector2i.ZERO

func set_conveyor_direction(tile: Vector2i, from_dir: Vector2i, to_dir: Vector2i):
	var atlas_row = get_atlas_row(from_dir, to_dir)
	var atlas = Vector2i(0, atlas_row)
	tilemap.set_cell(0, tile, conveyor_source_id, atlas, 0)
	var data: TileData = tilemap.get_cell_tile_data(0, tile)
	if data == null:
		return
	data.set_custom_data("type", "conveyor")
	data.set_custom_data("dir", to_dir)
	data.set_custom_data("incoming", from_dir)

func get_atlas_row(from_dir: Vector2i, to_dir: Vector2i) -> int:
	if from_dir == to_dir:
		if to_dir == Vector2i(0, -1): return 8
		if to_dir == Vector2i(1, 0):  return 9
		if to_dir == Vector2i(0, 1):  return 10
		if to_dir == Vector2i(-1, 0): return 11
	if from_dir == Vector2i(0, -1) and to_dir == Vector2i(1, 0):  return 0
	if from_dir == Vector2i(1, 0)  and to_dir == Vector2i(0, 1):  return 1
	if from_dir == Vector2i(0, 1)  and to_dir == Vector2i(-1, 0): return 2
	if from_dir == Vector2i(-1, 0) and to_dir == Vector2i(0, -1): return 3
	if from_dir == Vector2i(-1, 0) and to_dir == Vector2i(0, 1):  return 4
	if from_dir == Vector2i(0, 1)  and to_dir == Vector2i(1, 0):  return 5
	if from_dir == Vector2i(1, 0)  and to_dir == Vector2i(0, -1): return 6
	if from_dir == Vector2i(0, -1) and to_dir == Vector2i(-1, 0): return 7
	return 9

func update_neighbors(tile: Vector2i):
	var tile_data: TileData = tilemap.get_cell_tile_data(0, tile)
	var tile_dir = Vector2i.ZERO
	if tile_data:
		tile_dir = Vector2i(tile_data.get_custom_data("dir"))

	for offset in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		var neighbor = tile + offset
		if not is_conveyor(neighbor):
			continue
		var data: TileData = tilemap.get_cell_tile_data(0, neighbor)
		if not data:
			continue
		var neighbor_dir = Vector2i(data.get_custom_data("dir"))
		var neighbor_incoming = get_incoming_dir(neighbor)

		if neighbor + neighbor_dir == tile:
			set_conveyor_direction(neighbor, neighbor_incoming, neighbor_dir)
			tile_incoming_dirs[neighbor] = tile_dir
			set_conveyor_direction(tile, neighbor_dir, tile_dir)

		if tile + tile_dir == neighbor:
			tile_incoming_dirs[neighbor] = tile_dir
			set_conveyor_direction(neighbor, tile_dir, neighbor_dir)

func get_incoming_dir(tile: Vector2i) -> Vector2i:
	var data: TileData = tilemap.get_cell_tile_data(0, tile)
	if data:
		var incoming = Vector2i(data.get_custom_data("incoming"))
		if incoming != Vector2i.ZERO:
			return incoming
	if tile in tile_incoming_dirs:
		return tile_incoming_dirs[tile]
	return Vector2i.ZERO

func is_conveyor(tile: Vector2i) -> bool:
	var data: TileData = tilemap.get_cell_tile_data(0, tile)
	return data != null and data.get_custom_data("type") == "conveyor"

func _exit_tree():
	if is_instance_valid(hologram_node):
		hologram_node.queue_free()

func deactivate():
	active = false
	if is_instance_valid(hologram_node):
		hologram_node.queue_free()
