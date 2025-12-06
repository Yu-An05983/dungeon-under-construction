extends Node2D

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
