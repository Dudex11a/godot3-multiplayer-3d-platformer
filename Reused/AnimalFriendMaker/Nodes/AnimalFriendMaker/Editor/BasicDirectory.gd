extends Control
class_name BasicDirectory

onready var vbox_container: = $ScrollContainer/HBoxContainer/VBoxContainer

onready var editor_node: = get_parent().get_parent().get_parent()
onready var af_maker_node: = editor_node.get_parent()

func _ready():
	# Connect VBox looped
	vbox_container.connect("looped", self, "_on_VBoxContainer_looped")

# ===== setget

func get_last_node() -> Node:
	return CustomFocus.get_last_valid_node(vbox_container)

# ===== Focus

func focus_entered(focus: FocusCursor):
	focus.set_current_node(CustomFocus.get_first_valid_node(vbox_container))

# ===== Signals

func _on_VBoxContainer_looped(focus: FocusCursor, looped: int):
	match looped:
		0: # Down
			focus.set_current_node(editor_node.controls_bottom_node)
		1: # Up
			focus.set_current_node(editor_node.path_node)
