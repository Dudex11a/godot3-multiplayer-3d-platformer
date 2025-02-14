extends OptionItem

onready var value_input_node: = $ValueInput

func set_value(new_value = value):
	# Set input if doesn't exist yet
	if not is_instance_valid(value_input_node):
		value_input_node = $ValueInput
	# Set value
	.set_value(new_value)
	# I have it check if the values are different because might be the
	# same since from this function being called in the function below
	# where the value in .text has already been changed. If I set the value
	# the cursor goes to the first character and that can be annoying when typing
	if value_input_node.text != String(new_value):
		value_input_node.text = String(new_value)

func _on_ValueInput_text_changed(new_text: String):
	if new_text != value:
		var old_pos: int = value_input_node.caret_position
		value_input_node.caret_position = min(old_pos, new_text.length())
	self.value = new_text
