extends Node2D

@onready var tilemap: TileMap = $"../BeltMap"
@export var move_interval := 0.3
var tile_items: Dictionary = {}
var moving_items: Array = []  # {sprite, from_pos, to_pos, progress}
var timer := 0.0

func tick():
	var ordered = get_tiles_ordered()
	for tile in ordered:
		if not tile in tile_items:
			continue

		# Skip if this item is still mid-movement
		var item = tile_items[tile]
		if item.get("moving", false):
			continue

		var data: TileData = tilemap.get_cell_tile_data(0, tile)
		if not data:
			continue
		var dir = Vector2i(data.get_custom_data("dir"))
		if dir == Vector2i.ZERO:
			continue
		var next_tile = tile + dir
		if is_conveyor(next_tile) and not next_tile in tile_items:
			var next_data: TileData = tilemap.get_cell_tile_data(0, next_tile)
			if next_data:
				var next_incoming = Vector2i(next_data.get_custom_data("incoming"))
				if next_incoming != Vector2i.ZERO and next_incoming != dir:
					continue
			move_item(tile, next_tile)

func move_item(from: Vector2i, to: Vector2i):
	var item = tile_items[from]
	tile_items.erase(from)
	tile_items[to] = item
	item["moving"] = true  # Mark as mid-movement

	var from_pos = tilemap.to_global(tilemap.map_to_local(from))
	var to_pos = tilemap.to_global(tilemap.map_to_local(to))
	moving_items.append({
		"sprite": item["sprite"],
		"from_pos": from_pos,
		"to_pos": to_pos,
		"progress": 0.0,
		"item": item  # Reference back to clear moving flag
	})

func _process(delta):
	var finished = []
	for entry in moving_items:
		entry["progress"] = min(entry["progress"] + delta / move_interval, 1.0)
		entry["sprite"].global_position = entry["from_pos"].lerp(entry["to_pos"], entry["progress"])
		if entry["progress"] >= 1.0:
			entry["item"]["moving"] = false  # Allow item to move again
			finished.append(entry)

	for f in finished:
		moving_items.erase(f)

	timer += delta
	if timer >= move_interval:
		timer = 0.0
		tick()

func get_tiles_ordered() -> Array:
	var all_tiles = tilemap.get_used_cells(0)
	var conveyor_tiles = []
	for tile in all_tiles:
		if is_conveyor(tile):
			conveyor_tiles.append(tile)
	conveyor_tiles.sort_custom(func(a, b):
		var a_data: TileData = tilemap.get_cell_tile_data(0, a)
		var b_data: TileData = tilemap.get_cell_tile_data(0, b)
		if not a_data or not b_data:
			return false
		var a_next = a + Vector2i(a_data.get_custom_data("dir"))
		var b_next = b + Vector2i(b_data.get_custom_data("dir"))
		var a_is_end = not is_conveyor(a_next)
		var b_is_end = not is_conveyor(b_next)
		if a_is_end != b_is_end:
			return a_is_end
		return false
	)
	return conveyor_tiles

func spawn_item(tile: Vector2i, texture: Texture2D) -> bool:
	if tile_items.has(tile):
		return false
	if not is_conveyor(tile):
		return false
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(3.0, 3.0)
	sprite.z_index = 1
	get_tree().current_scene.add_child(sprite)
	sprite.global_position = tilemap.to_global(tilemap.map_to_local(tile))
	tile_items[tile] = {"sprite": sprite, "texture": texture}
	return true

func remove_item(tile: Vector2i):
	if tile in tile_items:
		tile_items[tile]["sprite"].queue_free()
		tile_items.erase(tile)

func on_tile_removed(tile: Vector2i):
	remove_item(tile)

func is_conveyor(tile: Vector2i) -> bool:
	var data: TileData = tilemap.get_cell_tile_data(0, tile)
	return data != null and data.get_custom_data("type") == "conveyor"
