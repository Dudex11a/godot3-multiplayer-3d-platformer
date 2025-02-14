extends Control
class_name OptionEditor
func get_class() -> String: return "OptionEditor"

export var file_location: String = "user://Example.json"

#signal looped(focus, loop)
signal save(save_dic)
signal option_changed(option_name, value)
signal cancel

var can_save: bool = false

func _ready():
	# Give a moment stuff to load in
	# Otherwise I'll get an empty dictionary with "get_options_dic()"
	yield(get_tree(), "idle_frame")
	var dir: = Directory.new()
	if file_location.length() > 0 and dir.file_exists(file_location):
		# Load if file exists
		load_options_dic()
	else:
		# Create file if doesn't exist
		save()
#		var options_dic: Dictionary = get_options_dic()
		load_options_dic({})
	# Hide back if not needed
#	back_button.visible = back_enabled
	# Connect children
	for child in get_children():
		connect_node(child)
	
	can_save = true

func add_child(node: Node, legible_unique_name: bool = false):
	.add_child(node, legible_unique_name)
	connect_node(node)

func connect_node(node: Node):
	if node.get_class() == "OptionContainer":
		node.connect("cancel", self, "cancel")

func get_options_dic(node: Node = get_children()[0]) -> Dictionary:
	var dic: Dictionary = {}
	for child in node.get_children():
		match child.get_class():
			"OptionItem":
				dic[child.name] = child.get_value()
			"OptionTabs", "OptionContainer":
				var child_dic: = get_options_dic(child)
				dic[child.name] = child_dic
	return dic

func load_options_dic(
		dic: Dictionary = G.load_json_file(file_location),
		node: Node = get_children()[0]):
	# Overwrite current settings with new ones
	# This ensures that default values correctly assign
	# when I add new options
	dic = G.overwrite_dic(get_options_dic(), dic)
	# Load options into nodes
	for child in node.get_children():
		if dic.has(child.name):
			match child.get_class():
				"OptionItem":
					child.set_value(dic[child.name])
					# Emit signal for setting it to option, this gets around
					# some default behavior of not emitting a signal if
					# the value is the default
					child.emit_signal("value_changed", child.value)
					# Allow it to emit a signal for value_change
					child.emit_value_change = true
				"OptionTabs", "OptionContainer":
					load_options_dic(dic[child.name], child)
	get_tree().call_group("OptionEditor", "set_options", name, get_options_dic())

func save():
	if get_child_count() > 0 and can_save:
		var save_dic: Dictionary = get_options_dic()
		if has_file_location():
			G.save_json_file(file_location, save_dic)
		emit_signal("save", save_dic)

func get_option_node() -> Node:
	for child in get_children():
		return child
	return null

func cancel():
	# Save on exit
	save()
	# Exit
	emit_signal("cancel")

func has_file_location() -> bool:
	return file_location.length() > 0

func option_changed(option_name: String, value):
	emit_signal("option_changed", option_name, value)
	# Save options
	save()

# ===== Focus

#func set_focus_to_visible_button(focus: FocusCursor):
#	var visible_button: Node = get_visible_button()
#	if is_instance_valid(visible_button):
#		focus.set_current_node(visible_button)

func focus_entered(focus: FocusCursor):
	# Focus options if exist
	var option_node: Node = get_option_node()
	if is_instance_valid(option_node):
		focus.set_current_node(option_node)
		return
	# Focus back or save if they're visible
#	set_focus_to_visible_button(focus)

#func focus_entered_p(focus: FocusCursor, parent: Node):
#	G.debug_print("options editor child focus entered")
#	if back_button.is_visible_in_tree() or save_button.is_visible_in_tree():
#		focus.set_current_node(parent.get_children()[0])

func ui_cancel_action_p(focus: FocusCursor, parent: Node):
	emit_signal("cancel")

func ui_cancel_action_pp(focus: FocusCursor, parent: Node):
	emit_signal("cancel")

# ===== Signals
