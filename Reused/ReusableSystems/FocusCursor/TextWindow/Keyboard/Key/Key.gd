extends Control
class_name Key
tool

onready var character_node: = $Character
onready var button_node: = $Button

export var character: String = "a" setget set_character

signal pressed(character)

func _ready():
	set_character()

func set_character(value: String = character):
	character = value
	
	if is_instance_valid(character_node):
		character_node.text = character

func pressed():
	emit_signal("pressed", character)

# ===== Focus

func ui_accept_action(focus: FocusCursor):
	pressed()

# ===== Signals

func _on_Button_pressed():
	pressed()
