extends ColorRect
class_name EditorColor

onready var selection_node: = $Selection
onready var linked_node: = $Linked

var selected: bool = false setget set_selected
var linked: bool = false setget set_linked

var color_reference: Dictionary = {}

# TEMP I don't use this anymore
# remove this once I no longer use OldColorsEditor
var image_palette_index: int = -1
var linked_color_index: int = -1

signal pressed(focus)

func set_selected(value: bool):
	selected = value
	selection_node.visible = value

func set_linked(value: bool):
	linked = value
	linked_node.visible = value

func _on_Button_pressed(focus: FocusCursor = null):
	emit_signal("pressed", focus)

func ui_accept_action(focus: FocusCursor):
	_on_Button_pressed(focus)
