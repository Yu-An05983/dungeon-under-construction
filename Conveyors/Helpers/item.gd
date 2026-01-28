extends RefCounted
class_name Item

var follower: PathFollow2D
var itemdata: String

func _init(path_node: Path2D, texture: Texture2D, itemdata: String):
	var follower = PathFollow2D.new()
	follower.offset = 0

	var sprite = Sprite2D.new()
	sprite.texture = texture
	follower.add_child(sprite)
	sprite.scale = Vector2(3.0, 3.0)
	
	path_node.add_child(follower)
	follower.add_child(sprite)
	self.itemdata = itemdata
