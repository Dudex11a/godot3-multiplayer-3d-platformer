extends Node

var R: ResourceContainer
var A: LazyAudio

# Array of FocusCursors
var cursors: Array = []

# I need this here because sometimes when messing with viewports the mouse input gets consumed?
var mouse_inputs: Dictionary = {}

signal before_clear

func _ready():
	G.load_resource_container(self)
	A = R.get_instance("audio_player_node")
	add_child(A)
	get_tree().connect("node_added", self, "node_added")
	# Disable old focus within all nodes
	disable_focus_within(get_viewport())

func _process(delta):
	# Clear mouse inputs
	emit_signal("before_clear")
	mouse_inputs.clear()

# When a node is added disable the old focus
func node_added(node: Node):
	disable_focus_within(node, false)
#	if node is Button:
#		node.enabled_focus_mode = Button.FOCUS_NONE

func disable_focus_within(node: Node, recursive: bool = true):
	for child in node.get_children():
		if child is Control:
			match child.get_class():
#				"LineEdit", "TextEdit":
#					pass
				_:
					child.focus_mode = Control.FOCUS_NONE
#			child.focus_neighbour_top = child.get_path_to(child)
#			child.focus_neighbour_right = child.get_path_to(child)
#			child.focus_neighbour_bottom = child.get_path_to(child)
#			child.focus_neighbour_left = child.get_path_to(child)
#			child.focus_next = child.get_path_to(child)
#			child.focus_previous = child.get_path_to(child)
		if recursive:
			disable_focus_within(child)

func add_cursor(controller_data: ControllerData = null) -> FocusCursor:
	var cursor: FocusCursor = R.get_instance("focus_cursor_node")
	get_viewport().call_deferred("add_child", cursor)
	cursor.controller_data = controller_data
	cursors.append(cursor)
	return cursor

func get_cursor(controller_data: ControllerData) -> FocusCursor:
	for cursor in cursors:
		if cursor.controller_data.to_name() == controller_data.to_name():
			return cursor
	return null

func get_mouse_relative() -> Vector2:
	var mouse_relative: = Vector2.ZERO
	if mouse_inputs.size() > 0:
		var first_input: Vector2 = mouse_inputs[mouse_inputs.keys()[0]]
		mouse_relative = first_input
	return mouse_relative

func get_self() -> Node:
	return self

func add_mouse_input(event: InputEventMouseMotion, id: String):
	if id in mouse_inputs:
		mouse_inputs[id] += event.relative
	else:
		mouse_inputs[id] = event.relative

func node_is_valid(node: Control) -> bool:
	var checks: Array = [
		node.visible,
		node.name[0] != "_"
	]
	# Button is enabled
	if node is Button:
		checks.append(not node.disabled)
	var value: bool = true
	for check in checks:
		if not check:
			value = false
	return value

func get_first_valid_node(parent: Node) -> Node:
	for child in parent.get_children():
		if node_is_valid(child):
			return child
	return null

func get_last_valid_node(parent: Node) -> Node:
	var children: Array = parent.get_children()
	# Start from the back
	children.invert()
	for child in children:
		if node_is_valid(child):
			return child
	return null

func get_active_cursors() -> Array:
	var active_cursors: Array = []
	
	for cursor in cursors:
		if cursor.enabled:
			active_cursors.append(cursor)
	
	return active_cursors

func get_keyboard_cursors() -> Array:
	var keyboard_cursors: Array = []
	
	for cursor in cursors:
		if is_instance_valid(cursor):
			if is_instance_valid(cursor.controller_data):
				if "Keyboard" in cursor.controller_data.to_name():
					keyboard_cursors.append(cursor)
	
	return keyboard_cursors
