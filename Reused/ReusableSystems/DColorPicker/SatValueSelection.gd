extends ColorRect

onready var color_picker: DColorPicker = get_parent().get_parent()

func ui_accept_action(focus: FocusCursor):
	focus.set_current_node(get_parent())

func ui_up_action(focus: FocusCursor):
	move_selection(focus, 1, "ui_up", "v")

func ui_down_action(focus: FocusCursor):
	move_selection(focus, -1, "ui_down", "v")
	
func ui_right_action(focus: FocusCursor):
	move_selection(focus, 1, "ui_right", "s")

func ui_left_action(focus: FocusCursor):
	move_selection(focus, -1, "ui_left", "s")

func move_selection(focus: FocusCursor, amount: float, action_name: String, param: String):
	while action_name in focus.pressed_actions:
		color_picker.color[param] += get_process_delta_time() * 0.4 * amount
		# Set focus position
		focus.set_current_node(self)
		focus.update_visible_to_current_node()
		yield(get_tree(), "idle_frame")
