extends Node
class_name FocusCursor

onready var visuals_node: = $Visuals
onready var cursor_node: = visuals_node.get_node("Cursor")
onready var selection_node: = visuals_node.get_node("Selection")
onready var position_transition_timer: = visuals_node.get_node("PositionTransition")

onready var up_node: = selection_node.get_node("Up")
onready var right_node: = selection_node.get_node("Right")
onready var down_node: = selection_node.get_node("Down")
onready var left_node: = selection_node.get_node("Left")
onready var prompt_nodes: = [up_node, right_node, down_node, left_node]

export var visual_position_curve: Curve

var previous_node: Node = null
var current_node: Node = null setget set_current_node
var controller_data: ControllerData = null

# An array of Strings of input_events not to be allowed
var forbidden_input_events: Array = []

var current_tab_container: TabContainer = null

var pressed_actions: Array = []

var button_normal_styles: Dictionary = {}

var enabled: bool = true setget set_enabled

var last_position: = Vector2.ZERO

var text_window = null setget set_text_window

# Script focus action guide:
# <> = name of action in the Input Map
# focus_entered : What to do once the focus_cursor has entered this node.
# focus_exited : What to do once the focus_cursor has left the last node.
# <>_action : What to do when the action is pressed when the node is being hovered.
#             Remember that set_specified_input_node needs to be called for the action to work.
# get_<>_node : Allow for a custom node to be returned when getting the node to focus.

func _ready():
	get_tree().connect("screen_resized", self, "update_visible_to_current_node")
	# Set text_window
	self.text_window = $EnglishTextWindow

## Debug current_node
#func _process(delta):
#	if is_instance_valid(current_node):
#		G.debug_value("Current node", current_node.name)
#	else:
#		G.debug_value("Current node", "false")
#	G.debug_value("Enabled", enabled)

func _input(event: InputEvent):
	# Hide if mouse input
	if event is InputEventMouseButton:
		set_visible(false)
	
	# Stop if event is forbidden
	if event.get_class() in forbidden_input_events:
		return
	
	# Stop if controller_data event doesn't match
	if is_instance_valid(controller_data):
		if not controller_data.event_matches(event):
			return
	
	# Yield a moment so this cursor can be disabled before the input is detected
	yield(get_tree(), "idle_frame")
	if not enabled:
		return
	else:
		# Show since the input type is valid now
		if not event is InputEventMouse:
			set_visible(true)
	
	# Store what actions are being pressed
	for action in InputMap.get_actions():
		if InputMap.event_is_action(event, action):
			if "pressed" in event:
				if event.pressed:
					if not action in pressed_actions:
						pressed_actions.append(action)
				else:
					if action in pressed_actions:
						pressed_actions.erase(action)
	
	if is_instance_valid(current_node):
		var input_response: Dictionary = {}
		
		input_response = set_specified_input_node(event, "ui_accept")
#		input_response = set_specified_input_node(event, "ui_accept", "released")
		if "pressed" in input_response.input_state:
			remove_text_popups()
			# Class based behavior if there was no specified_input_node set
			if not input_response.complete:
				match current_node.get_class():
					"Button", "CheckButton":
						current_node.pressed = not current_node.pressed
						current_node.emit_signal("pressed")
					"TextEdit", "LineEdit", "DTextInput":
						open_text_window(current_node)
					var current_node_class:
						move_cursor_in()
		
		input_response = set_specified_input_node(event, "ui_cancel")
		if "pressed" in input_response.input_state and not input_response.complete:
			remove_text_popups()
			match current_node.get_class():
				var current_node_class:
					move_cursor_out()
#		if "pressed" in input_response.input_state:
#			# Play move sound
#			CustomFocus.A.play_sound("Unselect1")
		
		input_response = set_specified_input_node(event, "ui_up")
		if "pressed" in input_response.input_state and not input_response.complete:
			var move_amount: int = -1
			var direction: Vector2 = Vector2.UP
			var parent_node: Node = current_node.get_parent()
			match parent_node.get_class():
				"VBoxContainer":
					move_cursor_child(move_amount)
				"HBoxContainer":
					pass
				_: # If no instructions for parent class
					var end: bool = false
					if "focus_neighbour_top" in current_node:
						var focus_neighbour = current_node.focus_neighbour_top
						if String(focus_neighbour).length() > 1:
							set_current_node(current_node.get_node(focus_neighbour))
							end = true
					if not end:
						match parent_node.get_class():
							_:
								var nearest_node: Control = get_nearest_control_in_direction(current_node, parent_node.get_children(), direction)
								if is_instance_valid(nearest_node):
									set_current_node(nearest_node)
		
		input_response = set_specified_input_node(event, "ui_down")
		if "pressed" in input_response.input_state and not input_response.complete:
			var move_amount: int = 1
			var direction: Vector2 = Vector2.DOWN
			var parent_node: Node = current_node.get_parent()
			match parent_node.get_class():
				"VBoxContainer":
					move_cursor_child(move_amount)
				"HBoxContainer":
					pass
				_: # If no instructions for parent class
					var end: bool = false
					if "focus_neighbour_bottom" in current_node:
						var focus_neighbour = current_node.focus_neighbour_bottom
						if String(focus_neighbour).length() > 1:
							set_current_node(current_node.get_node(focus_neighbour))
							end = true
					if not end:
						match parent_node.get_class():
							_:
								var nearest_node: Control = get_nearest_control_in_direction(current_node, parent_node.get_children(), direction)
								if is_instance_valid(nearest_node):
									set_current_node(nearest_node)
		
		input_response = set_specified_input_node(event, "ui_right")
		if "pressed" in input_response.input_state and not input_response.complete:
			var move_amount: int = 1
			var direction: Vector2 = Vector2.RIGHT
			var parent_node: Node = current_node.get_parent()
			match parent_node.get_class():
				"HBoxContainer":
					move_cursor_child(move_amount)
				"VBoxContainer":
					pass
#				"TabContainer":
#					var next_tab: int = parent_node.current_tab + move_amount
#					next_tab = posmod(next_tab, parent_node.get_child_count())
#					var move: bool = true
#					# don't move if is not displaying tabs
#					if not parent_node.tabs_visible:
#						move = false
#					if move:
#						parent_node.current_tab = next_tab
#						move_cursor_child(move_amount)
				_: # If no instructions for parent class
					var end: bool = false
					if "focus_neighbour_right" in current_node:
						var focus_neighbour = current_node.focus_neighbour_right
						if String(focus_neighbour).length() > 1:
							set_current_node(current_node.get_node(focus_neighbour))
							end = true
					if not end:
						match parent_node.get_class():
							_:
								var nearest_node: Control = get_nearest_control_in_direction(current_node, parent_node.get_children(), direction)
								if is_instance_valid(nearest_node):
									set_current_node(nearest_node)
		
		input_response = set_specified_input_node(event, "ui_left")
		if "pressed" in input_response.input_state and not input_response.complete:
			var move_amount: int = -1
			var direction: Vector2 = Vector2.LEFT
			var parent_node: Node = current_node.get_parent()
			match parent_node.get_class():
				"HBoxContainer":
					move_cursor_child(move_amount)
				"VBoxContainer":
					pass
#				"TabContainer":
#					var next_tab: int = parent_node.current_tab + move_amount
#					next_tab = posmod(next_tab, parent_node.get_child_count())
#					var move: bool = true
#					# don't move if is not displaying tabs
#					if not parent_node.tabs_visible:
#						move = false
#					if move:
#						parent_node.current_tab = next_tab
#						move_cursor_child(move_amount)
				_: # If no instructions for parent class
					var end: bool = false
					if "focus_neighbour_left" in current_node:
						var focus_neighbour = current_node.focus_neighbour_left
						if String(focus_neighbour).length() > 1:
							set_current_node(current_node.get_node(focus_neighbour))
							end = true
					if not end:
						match parent_node.get_class():
							_:
								var nearest_node: Control = get_nearest_control_in_direction(current_node, parent_node.get_children(), direction)
								if is_instance_valid(nearest_node):
									set_current_node(nearest_node)
		
		input_response = set_specified_input_node(event, "debug_1")
#		if "pressed" in input_response.input_state and not input_response.complete:
#			if current_node is Control:
#				print(G.get_parent_of_type(current_node, ScrollContainer))
		
		input_response = set_specified_input_node(event, "ui_next")
		if "released" in input_response.input_state:
			pass
			# Play sound
#			CustomFocus.A.play_sound("Select2")
		input_response = set_specified_input_node(event, "ui_previous")
		if "released" in input_response.input_state:
			pass
			# Play sound
#			CustomFocus.A.play_sound("Unselect1")
		
# 0 = Input and node delt with,
# 1 = action matched but no specified node,
# 2 = Input doesn't match
func set_specified_input_node(event: InputEvent, action_name: String, activate_on: String = "pressed") -> Dictionary:
	var return_info: Dictionary = {
		"input_state" : "none",
		"node" : null,
		"complete" : false
	}
	if event.is_action_released(action_name):
		return_info.input_state = "released"
#		pressed_actions.erase(action_name)
	if event.is_action_pressed(action_name):
		return_info.input_state = "pressed"
#		pressed_actions.append(action_name)
	# Add node to the return_info
	var node_get_node_method_name: String = "get_" + action_name + "_node"
	if current_node.has_method(node_get_node_method_name):
		return_info.node = current_node.call(node_get_node_method_name, self)
	# Run function and/or set current node if active on pressed/released
	if return_info.input_state == activate_on:
		var node_method_name: String = action_name + "_action"
		var nodes: Array = G.run_method_if_exists(current_node, node_method_name, [self], 2)
		if nodes.size() > 0:
			return_info.complete = true
#		if current_node.has_method(node_method_name):
#			# Call node method for input
#			current_node.call(node_method_name, self)
#			return_info.complete = true
#		# Run parent method if it exists
#		var parent: Node = current_node.get_parent()
#		var parent_method_name: String = node_method_name + "_parent"
#		if is_instance_valid(parent):
#			if parent.has_method(parent_method_name):
#				# Call node method for input
#				parent.call(parent_method_name, self)
#				return_info.complete = true
#			# Run parent of parent method if it exists (This does have a use case)
#			var parent_parent: Node = parent.get_parent()
#			var parent_parent_method_name: String = parent_method_name + "_parent"
#			if is_instance_valid(parent_parent):
#				if parent_parent.has_method(parent_parent_method_name):
#					# Call node method for input
#					parent_parent.call(parent_parent_method_name, self, parent)
#					return_info.complete = true
		# Set current node if the current_node had a special node for the input
		if is_instance_valid(return_info.node):
			set_current_node(return_info.node)
			return_info.complete = true
	return return_info

# If you make a function called <ACTION>_action in the current node,
# it'll do that action instead of the default behavior

func set_current_node(value: Node):
	previous_node = current_node
	current_node = value
	var parent: Node = current_node.get_parent()
	
	# Remove any previous text popups
	remove_text_popups()
	
	# Run current node function if it exists
	G.run_method_if_exists(current_node, "focus_entered", [self], 2)
	if current_node.has_signal("resized") and not current_node.is_connected("resized", self, "update_visible_to_current_node"):
		current_node.connect("resized", self, "update_visible_to_current_node")
	# Run leave node function if it exists
	if is_instance_valid(previous_node):
		G.run_method_if_exists(current_node, "focus_exited", [self], 2)
		if previous_node.is_connected("resized", self, "update_visible_to_current_node"):
			previous_node.disconnect("resized", self, "update_visible_to_current_node")
	
	# If parent is a TabContainer connect it to the tab_changed function
#	if G.get_parent_of_class_name(current_node, "DTabContainer"):
#		# Remove old connection the current tab_container in tab_changed
#		if is_instance_valid(current_tab_container):
#			current_tab_container.disconnect("tab_changed", self, "tab_changed")
#		parent.connect("tab_changed", self, "tab_changed")
#		current_tab_container = parent
	
	if current_node is Control:
		# If current node is a button or has buttons, set the node's theme to hover
		if current_node is Button:
			pass
		#
		var current_node_position: = Vector2.ZERO
		var current_node_size: = Vector2.ZERO
		
		# Cursor position
		var cursor_previous_position: Vector2 = cursor_node.position
		var cursor_next_position: Vector2 = current_node_position
		cursor_next_position.y += current_node_size.y / 2
		cursor_next_position.x += 10
		# Selection size and position
		var selection_previous_size: Vector2 = selection_node.rect_size
		var selection_next_size: Vector2 = current_node_size
		var selection_previous_position: Vector2 = selection_node.get_global_rect().position
		var selection_next_position: Vector2 = current_node_position
		
		# Adjust scroll container position if in a scroll container
		var scroll_container: ScrollContainer = G.get_parent_of_type(current_node, ScrollContainer)
		if is_instance_valid(scroll_container):
			var scroll_container_center = scroll_container.rect_size / 2
			var current_node_center: Vector2 = current_node.rect_size / 2
			var current_node_local_position: Vector2 = G.get_position_relative_to_parent(scroll_container, current_node)
			# Correct the position with the scroll_positions
			current_node_local_position.x += scroll_container.scroll_horizontal
			current_node_local_position.y += scroll_container.scroll_vertical
			var current_node_position_in_center: Vector2 = current_node_center + current_node_local_position
			scroll_container.scroll_horizontal = current_node_position_in_center.x - scroll_container_center.x
			scroll_container.scroll_vertical = current_node_position_in_center.y - scroll_container_center.y
		
		# Animate transition between two nodes
		position_transition_timer.start()
		while not position_transition_timer.is_stopped():
			# I want to update the next position and size in the loop incase it changes
			if is_instance_valid(current_node): # This is weird but sometimes current_node is null part way through
				current_node_position = current_node.get_global_rect().position
				current_node_size = current_node.get_global_rect().size
			# Add viewport container position if current_node is within another viewport
			if is_instance_valid(current_node):
				current_node_position += get_other_node_offsets()
					
			selection_next_size = current_node_size
			selection_next_position = current_node_position
			
			var timer_position: float = abs((position_transition_timer.time_left / position_transition_timer.wait_time) - 1)
			var interpolated_position: float = visual_position_curve.interpolate(timer_position)
			# lerp cursor position
			cursor_node.position = lerp(cursor_previous_position, cursor_next_position, interpolated_position)
			# lerp selection size and position
			selection_node.set_global_position(lerp(selection_previous_position, selection_next_position, interpolated_position))
			selection_node.rect_size = lerp(selection_previous_size, selection_next_size, interpolated_position)
			#
			yield(get_tree(), "idle_frame")
		
		# Set final position
		cursor_node.position = cursor_next_position
		selection_node.set_global_position(selection_next_position)
		selection_node.rect_size = selection_next_size
		
#		# Update selection input prompts
#		# Hide all prompts
#		for prompt_node in prompt_nodes:
#			prompt_node.visible = false
#		# Set visibility for prompt nodes
#		match parent.get_class():
#			"VBoxContainer":
#				up_node.visible = true
#				down_node.visible = true
#			"HBoxContainer", "TabContainer":
#				right_node.visible = true
#				left_node.visible = true
#			_: # Default is everything is visible
#				for prompt_node in prompt_nodes:
#					prompt_node.visible = true

func create_text_popup(params: Dictionary = {}):
	var defualt_rect: Rect2 = current_node.get_global_rect()
	defualt_rect.position += get_other_node_offsets()
	# Apply default values
	var default_params: Dictionary = {
		"rect" : defualt_rect,
		"direction" : G.DIR_UP,
		"text" : current_node.name
	}
	var final_params = G.overwrite_dic(default_params, params)
	# Create node
	var text_popup_node = CustomFocus.R.get_instance("text_popup_node")
	visuals_node.add_child(text_popup_node)
	# Setup node
	text_popup_node.set_params(final_params)
	text_popup_node.open()

func remove_text_popups():
	if is_instance_valid(visuals_node):
		for child in visuals_node.get_children():
			if child.get_class() == "TextPopup":
				child.close()

# Move cursor into first valid child
func move_cursor_in():
	for child in current_node.get_children():
		if CustomFocus.node_is_valid(child):
			set_current_node(child)
			return

func move_cursor_out():
	set_current_node(current_node.get_parent())

func move_cursor_child(amount: int = 1, from_node: Node = current_node) -> Dictionary:
	var looped: int = -1
	var next_child: Dictionary = G.get_next_child_ext(from_node, amount)
	looped = next_child.looped
	# Get the next next child if the first one is invalid
	while not CustomFocus.node_is_valid(next_child.node):
		next_child = G.get_next_child_ext(next_child.node, amount)
		# If looped, remember loop
		if next_child.looped >= 0:
			looped = next_child.looped
	# Set
	set_current_node(next_child.node)
	# Call looped functions if they exist
	var node: Node = next_child.node
	if looped >= 0:
		G.run_method_if_exists(from_node, "focus_looped", [self, looped], 2)
	
	return next_child
#		var method_name: String = "focus_looped"
#		if node.has_method(method_name):
#			node.call(method_name, self, looped)
#		var parent: Node = node.get_parent()
#		# Make this a method in general later
#		if is_instance_valid(parent):
#			var parent_method_name: String = method_name + "_parent"
#			if parent.has_method(parent_method_name):
#				parent.call(parent_method_name, self, looped)
#			var parent_parent: Node = parent.get_parent()
#			if is_instance_valid(parent_parent):
#				var parent_parent_method_name: String = parent_method_name + "_parent"
#				if parent_parent.has_method(parent_parent_method_name):
#					parent_parent.call(parent_parent_method_name, self, looped)

func get_control_point_datas(nodes: Array) -> Array:
	var point_datas: Array = []
	for node in nodes:
		if node is Control:
			var point_dictionary: Dictionary = {}
			point_dictionary.point = get_control_point(node)
			point_dictionary.node = node
			point_datas.append(point_dictionary)
	return point_datas

func get_nearest_control(node1: Control, nodes: Array) -> Control:
	var node1_point: Vector2 = get_control_point(node1)
	var nearest_point_data: Dictionary = { "point": Vector2(999999999, 999999999) }
	var point_datas: Array = get_control_point_datas(nodes)
	for point_data in point_datas:
		# If the distance to 
		if node1_point.distance_to(point_data.point) < node1_point.distance_to(nearest_point_data.point):
			nearest_point_data = point_data
	# Make sure the nearest_point_data has a node, otherwise it's my dummy data and should return null
	if "node" in nearest_point_data:
		return nearest_point_data.node
	return null

func get_control_point(node: Control) -> Vector2:
	var point: Vector2 = node.get_global_rect().position
	point += node.rect_size / 2
	return point

func get_controls_in_direction_of(node1: Control, nodes: Array, direction: Vector2) -> Array:
	# Get axis to compare from
	var axis: String = ""
	if abs(direction.x) > abs(direction.y):
		axis = "x"
	else:
		axis = "y"
	
	var filtered_nodes: Array = []
	var node1_point: Vector2 = get_control_point(node1)
	for node in nodes:
		if node is Control:
			# Make sure node is visible to count it
			if CustomFocus.node_is_valid(node):
				var node_point: Vector2 = get_control_point(node)
				var distance_vec2: Vector2 = node1_point - node_point
				var positive_distance_vec2: Vector2 = distance_vec2 * direction
				var distance: float = positive_distance_vec2[axis]
				# If distance is positive then consider the node in the direction of
				if distance < 0:
					filtered_nodes.append(node)
	return filtered_nodes

func get_nearest_control_in_direction(node1: Control, nodes: Array, direction: Vector2) -> Control:
	var nodes_in_direction: Array = get_controls_in_direction_of(node1, nodes, direction)
	var nearest_node: Control = get_nearest_control(node1, nodes_in_direction)
	return nearest_node

#func set_node_button_state_theme(node: Node, state: String):
#	# Create node_theme from node
#	if node is Control:
#		var new_theme: Theme = G.get_node_theme(current_node).duplicate()
#		var button_nodes: Array = []
#		# Add special button_nodes from node
#		if node.has_method("get_button_nodes"):
#			button_nodes.append_array(node.get_button_nodes())
#		# If this node is a button add this button
#		if node is Button:
#			button_nodes.append(node)
#
#		for button_node in button_nodes:
#			if state != "normal" and not button_node.get_path() in button_normal_styles:
#				# Save normal button styles if there isn't one already
#				button_normal_styles[button_node.get_path()] = G.get_node_theme(current_node).get_stylebox("normal", "Button").duplicate()
#			# Set theme to equal itself or what it's parent is
#			button_node.theme = G.get_node_theme(current_node).duplicate()
#			if state == "normal":
#				# Set the normal style from the button_normal_styles since the current normal isn't the theme's usual normal
#				if button_node.get_path() in button_normal_styles:
#					button_node.theme.set_stylebox(state, "Button", button_normal_styles[button_node.get_path()])
#				else:
#					print("Does not remember normal style")
#				# Remove style from button_normal_styles since it exists in the theme now
#				button_normal_styles.erase(button_node.get_path())
#			else:
#				var style: StyleBox = button_node.theme.get_stylebox(state, "Button").duplicate()
#				button_node.theme.set_stylebox("normal", "Button", style)

func set_enabled(value: bool):
	enabled = value
	# Don't allow input if disabled
	set_process_input(value)
	# Set visuals
	set_visible(value)

func set_visible(value: bool):
	cursor_node.visible = value
	selection_node.visible = value

func update_visible_to_current_node():
	if not is_instance_valid(current_node):
		return
	yield(get_tree(), "idle_frame")
	if not is_instance_valid(current_node):
		return
	var current_node_position: Vector2 = current_node.get_global_rect().position
	var current_node_size: Vector2 = current_node.get_global_rect().size
	
	# Add viewport container position if current_node is within another viewport
	if is_instance_valid(current_node):
		current_node_position += get_other_node_offsets()
	
	selection_node.set_global_position(current_node_position)
	selection_node.rect_size = current_node_size

func tab_changed(tab_id: int):
	# If the tab isn't the tab it's supposed to be, change it to the tab
	var tab_container: TabContainer = G.get_parent_of_type(current_node, TabContainer)
	if current_node.get_index() != tab_id:
		set_current_node(tab_container.get_children()[tab_container.current_tab])

func create_notification_popup(text: String):
	# Get viewport
	var viewport: Viewport = get_node_viewport()
	# Create popup
	var popup_node = CustomFocus.R.get_instance("notification_popup_node")
	viewport.add_child(popup_node)
	popup_node.open(self)
	popup_node.set_text(text)

func get_node_viewport(node: Node = current_node):
	return G.get_parent_of_type(node, Viewport)

var last_text_edit_node: Node = null

func open_text_window(text_edit_node: Node):
	# Open Text Window
	text_window.open(text_edit_node)

#func commit_text_window(text: String):
#	# Set text depending on the node
#	if "text" in last_text_edit_node:
#		last_text_edit_node.text = text
#	else:
#		G.debug_print("Can't commit text to %s" % last_text_edit_node)
#	
#	close_text_window()

func close_text_window():
	text_window.close()

# ===== setget

func set_text_window(value):
	text_window = value
	# Connect signals
	text_window.focus_cursor = self
#	text_window.connect("commit", self, "commit_text_window")
	text_window.connect("exit", self, "close_text_window")

func get_canvas_layers_offset() -> Vector2:
	var offset: = Vector2.ZERO
	var canvas_layer: CanvasLayer = G.get_parent_of_type(current_node, CanvasLayer)
	while is_instance_valid(canvas_layer):
		offset += canvas_layer.offset
		canvas_layer = G.get_parent_of_type(canvas_layer, CanvasLayer)
	return offset

func get_viewport_offsets() -> Vector2:
	var offset: = Vector2.ZERO
	var viewport_container: ViewportContainer = G.get_parent_of_type(current_node, ViewportContainer)
	while is_instance_valid(viewport_container):
		offset += viewport_container.get_global_rect().position
		viewport_container = G.get_parent_of_type(viewport_container, ViewportContainer)
	return offset

func get_other_node_offsets() -> Vector2:
	var offset: = Vector2.ZERO
	# Canvas Layers
	offset += get_canvas_layers_offset()
	# Viewports
	offset += get_viewport_offsets()
	return offset

# ===== Signals

# When position changes, update visuals to new position
func _on_Selection_item_rect_changed():
	if selection_node.rect_position != last_position:
		update_visible_to_current_node()
		last_position = selection_node.rect_position
