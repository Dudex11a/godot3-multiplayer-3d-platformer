extends Control
class_name DTab
tool

onready var label_node: = $Label
onready var button_node: = $Button

var associated_node: Node = null

signal pressed
signal ui_up_action(focus)
signal ui_down_action(focus)

func _ready():
	set_name()

func pressed():
	if button_node.disabled:
		return
	button_node.pressed = true
	emit_signal("pressed")

func set_name(value: String = name):
	name = value
	if is_instance_valid(label_node):
		label_node.text = name

func set_name_by_node(node: Node):
	set_name(node.name)

func delete():
	queue_free()

func disable(value: bool):
	button_node.disabled = value
	if value:
		label_node.self_modulate.a = 0.5
	else:
		label_node.self_modulate.a = 1.0

func set_button_pressed(value: bool):
	button_node.pressed = value

func is_disabled() -> bool:
	return button_node.disabled

# ===== Focus

func ui_accept_action(focus: FocusCursor):
	pressed()

func ui_up_action(focus: FocusCursor):
	emit_signal("ui_up_action", focus)

func ui_down_action(focus: FocusCursor):
	emit_signal("ui_down_action", focus)

# ===== Signals

func _on_Button_pressed():
	pressed()
