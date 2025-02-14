extends Control
class_name FileItem
func get_class() -> String: return "FileItem"

onready var label_node: = $_Label

signal hovered
signal selected

var path: String = ""

func setup(file_name: String, file_path: String):
	name = file_name
	path = file_path
	label_node.text = file_name

func focus_entered(focus: FocusCursor):
	focus.set_current_node(CustomFocus.get_first_valid_node(self))

func focus_entered_p(focus: FocusCursor, parent: Node):
	hovered()
	focus.create_text_popup({ "direction" : G.DIR_DOWN })

func _on_FileItem_mouse_entered():
	hovered()

func hovered():
	emit_signal("hovered", name, path)

func _on_Load_pressed():
	emit_signal("selected", name, path)

func _on_Delete_pressed():
	# Add warning later
	# Delete file
	var dir: = Directory.new()
	dir.remove(path)
	# Remove node
	queue_free()
