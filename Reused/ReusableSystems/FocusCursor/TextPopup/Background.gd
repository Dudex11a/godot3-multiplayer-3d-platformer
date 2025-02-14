extends Control

onready var text_node: = get_node("../Text")

var padding: = Vector2(4.0, 4.0)

func _ready():
	resized()

func resized():
	rect_size = text_node.rect_size + padding
	rect_position = -(padding / 2)

func _on_Text_resized():
	resized()
