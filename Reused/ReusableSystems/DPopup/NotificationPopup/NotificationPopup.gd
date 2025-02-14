extends DPopup

onready var text_container: = $TextContainer
onready var label_node: = $TextContainer/Label

func _input(event: InputEvent):
	var event_controller_data: = ControllerData.new(event)
	if is_instance_valid(focus_cursor.controller_data):
		if focus_cursor.controller_data.to_name() != event_controller_data.to_name():
			return
	
	if event is InputEventMouseButton:
		close()

func set_text(text: String):
	label_node.text = text

func focus_entered(focus: FocusCursor):
	focus.set_current_node(label_node)

func ui_accept_action_pp(_focus: FocusCursor, _parent: Node):
	close()

func ui_cancel_action_pp(_focus: FocusCursor, _parent: Node):
	close()
