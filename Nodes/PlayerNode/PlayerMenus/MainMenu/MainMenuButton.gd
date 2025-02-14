extends Control
class_name MainMenuButton
func get_class() -> String: return "MainMenuButton"
tool

onready var visual_node: = $Visual
onready var label_node: = visual_node.get_node("Label")
onready var anim_player: = $AnimationPlayer

export var button_name: String = "Option" setget set_button_name
#export var anim_selected_x: float = 73.0
#export var anim_base_x: float = 13.0

var hovering_focus_cursor: FocusCursor = null

var allow_anim: bool = false

signal pressed

func _ready():
	# Wait for label_node to exist
	while not is_instance_valid(label_node):
		yield(get_tree(), "idle_frame")
	label_node.text = button_name

func ui_accept_action(focus_cursor: FocusCursor):
	_on_Button_pressed()

func set_button_name(value: String):
	button_name = value
	if is_instance_valid(label_node):
		label_node.text = button_name

func button_hover():
	if allow_anim:
		anim_player.play("Selected")

func button_unhover():
	if not is_instance_valid(hovering_focus_cursor) and allow_anim:
		anim_player.play("Unselected")

func focus_entered(focus_cursor: FocusCursor):
	hovering_focus_cursor = focus_cursor
	button_hover()
	
func focus_exited(focus_cursor: FocusCursor):
	hovering_focus_cursor = null
	button_unhover()

func open_anim_end():
	allow_anim = true
	if is_instance_valid(hovering_focus_cursor):
		if hovering_focus_cursor.current_node == self:
			button_hover()

func _on_Button_pressed():
	emit_signal("pressed")

func _on_Button_mouse_entered():
	button_hover()

func _on_Button_mouse_exited():
	button_unhover()
