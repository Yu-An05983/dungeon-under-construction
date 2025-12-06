extends Node2D

<<<<<<< HEAD
=======
<<<<<<< HEAD
var save_path = "user://data.save"

func _ready():
	load_save_data()
	pass

func save():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	var save_data = $SavedNodes.get_save_data()
	file.store_string(JSON.stringify(save_data))

func load_save_data():
	if FileAccess.file_exists(save_path):
		print("loading save data")
		var file = FileAccess.open(save_path, FileAccess.READ)
		var save_data = JSON.parse_string(file.get_as_text())
		$SavedNodes.load_from_save_data(save_data)
	else:
		print("there was no save data to load")


func _on_save_pressed():
	save()

func _on_check_pressed():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var save_data = JSON.parse_string(file.get_as_text())
		print("checking save data")
		print(JSON.stringify(save_data))
	else:
		print("no save data")
=======
>>>>>>> 0e244fa
@onready var player: CharacterBody2D = $Player
@onready var button: Button = $GUI/HBoxContainer/Button

var duct = preload("res://duct.tscn")
var ductinst = null
var placing_duct = false

func _on_button_pressed() -> void:
	print("Starting duct placement")
	placing_duct = true

func _input(event: InputEvent) -> void:
	if placing_duct and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			ductinst = duct.instantiate()
			ductinst.position = get_global_mouse_position()
			add_child(ductinst)
			placing_duct = false

func _process(delta: float) -> void:
	if placing_duct:
		pass
<<<<<<< HEAD
=======
>>>>>>> 4f9051a (Local changes to main files)
>>>>>>> 0e244fa
