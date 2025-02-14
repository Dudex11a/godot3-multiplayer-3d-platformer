extends Control
class_name TextWindow

onready var text_display_node: = $TextDisplay
var keyboard_node: Keyboard = null setget set_keyboard_node

var focus_cursor: FocusCursor = null setget set_focus_cursor

var accept_real_keyboard: bool = false

signal commit(text)
signal exit

var cursor_position: int = 0
var text: String = "" setget set_text

var last_text_edit_node: Node = null

func _input(event: InputEvent):
	# If menu button is pressed, commit and end
	var controller_data: ControllerData = focus_cursor.controller_data
	if is_instance_valid(controller_data):
		if controller_data.event_matches(event):
			if event.is_action_pressed("ui_menu") and is_visible_in_tree():
				# Wait a moment before commit so other ui_menu events happen before
				# this one (like closing menu checks).
				yield(get_tree(), "idle_frame")
				commit()
				return
	# Keyboard input
	if event is InputEventKey and accept_real_keyboard:
		if event.pressed:
			var scancode_string: String = OS.get_scancode_string(event.scancode)
			var scancode_with_modifiers: String = OS.get_scancode_string(event.get_scancode_with_modifiers())
			var unicode_string: String = char(event.unicode)
			# Scancode w/ modifiers
			match scancode_with_modifiers:
				"Control+V":
					key_pressed(OS.clipboard)
					return
				"Control+C":
					OS.clipboard = text
					return
			# Unicode
			if unicode_string.length() == 1:
				key_pressed(unicode_string)
				return
			# Scancode
			match scancode_string:
				"Enter":
					# Wait for input to pass in FocusCursor before committing
					yield(get_tree(), "idle_frame")
					commit()
					return
				"BackSpace":
					backspace()
					return
				"Right":
					move_cursor(1)
				"Left":
					move_cursor(-1)

func set_text(value: String):
	text = value
	update_text_display_node()

func update_text_display_node():
	if is_instance_valid(text_display_node):
		text_display_node.text = make_text_w_cursor()

func make_text_w_cursor() -> String:
	return text.insert(cursor_position, "|")

func move_cursor_to_end():
	cursor_position = text.length()
	update_text_display_node()

func backspace():
	if cursor_position > 0:
		text = text.left(cursor_position - 1) + text.right(cursor_position)
		cursor_position -= 1
		update_text_display_node()

func commit():
	if "text" in last_text_edit_node:
		last_text_edit_node.text = text
	if last_text_edit_node.has_signal("text_changed"):
		last_text_edit_node.emit_signal("text_changed", text)
	close()
	emit_signal("commit", text)

func move_cursor(amount: int):
	if text.length() > 0:
		cursor_position = posmod(cursor_position + amount, text.length() + 1)
	else:
		cursor_position = 0
	update_text_display_node()

func set_keyboard_node(value: Keyboard):
	keyboard_node = value
	# Connect signals from keyboard
	keyboard_node.connect("key_pressed", self, "key_pressed")
	keyboard_node.connect("commit_pressed", self, "commit")
	keyboard_node.connect("backspace_pressed", self, "backspace")
	keyboard_node.connect("right_pressed", self, "right_pressed")
	keyboard_node.connect("left_pressed", self, "left_pressed")
	keyboard_node.connect("exit", self, "exit")

func key_pressed(key_text: String):
	text = text.insert(cursor_position, key_text)
	cursor_position += key_text.length()
	update_text_display_node()

func right_pressed():
	move_cursor(1)

func left_pressed():
	move_cursor(-1)

func exit():
	emit_signal("exit")

func open(text_edit_node: Node):
	visible = true
	# Save text_edit
	last_text_edit_node = text_edit_node
	# Copy text over
	self.text = text_edit_node.text
	move_cursor_to_end()
	# Focus text_window
	focus_cursor.set_current_node(self)
	# Enable keyboard input if keyboard
#	if is_controller_keyboard(focus_cursor.controller_data):
	if CustomFocus.get_keyboard_cursors().size() == 0 or is_controller_keyboard():
		# Accept keyboard if is keyboard or there are no keyboards
		accept_real_keyboard = true
	
	# Disable focus if controller is keyboard
	focus_cursor.forbidden_input_events.append("InputEventKey")

func close():
	accept_real_keyboard = false
	
	# Return focus to last_text_edit_node
	if "InputEventKey" in focus_cursor.forbidden_input_events:
		focus_cursor.forbidden_input_events.erase("InputEventKey")
	focus_cursor.set_current_node(last_text_edit_node)
	last_text_edit_node = null
	# Hide keyboard
	visible = false

func is_controller_keyboard() -> bool:
	var controller_data: ControllerData = focus_cursor.controller_data
	if is_instance_valid(controller_data):
#		if controller_data.to_name() in ["Keyboard", "unknown"]:
		var cd_name: String = controller_data.to_name()
		if "Keyboard" in cd_name or "unknown" in cd_name:
			return true
		return false
	return true
	
#	if is_instance_valid(controller_data):
#		if "Keyboard" in controller_data.to_name():
#			return true
#	else:
#		return true
#	return false

# ===== setget

func set_focus_cursor(value: FocusCursor):
	focus_cursor = value

# ===== Focus

func focus_entered(focus: FocusCursor):
	if is_instance_valid(keyboard_node):
		focus.set_current_node(keyboard_node)
