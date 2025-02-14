extends ColorRect

onready var color_picker: DColorPicker = get_parent().get_parent()

func ui_accept_action(focus: FocusCursor):
	focus.set_current_node(get_parent())

func ui_up_action(focus: FocusCursor):
	move_selection(focus, -1, "ui_up")

func ui_down_action(focus: FocusCursor):
	move_selection(focus, 1, "ui_down")

func move_selection(focus: FocusCursor, amount: float, action_name: String):
	while action_name in focus.pressed_actions:
		color_picker.color.h += get_process_delta_time() * 0.4 * amount
		# Set focus position
		focus.set_current_node(self)
		focus.update_visible_to_current_node()
		yield(get_tree(), "idle_frame")
