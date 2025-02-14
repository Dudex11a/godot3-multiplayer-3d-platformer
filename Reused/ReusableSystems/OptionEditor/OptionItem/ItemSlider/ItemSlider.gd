extends OptionItem

onready var value_input_node: = $ValueInput
onready var slider_input_node: = $SliderInput

func set_value(new_value = value):
	if not is_instance_valid(value_input_node):
		value_input_node = $ValueInput
	if not is_instance_valid(slider_input_node):
		slider_input_node = $SliderInput
	.set_value(new_value)
	# I have it check if the values are different because might be the
	# same since from this function being called in the function below
	# where the value in .text has already been changed. If I set the value
	# the cursor goes to the first character and that can be annoying when typing
	if value_input_node.text != String(new_value):
		value_input_node.text = String(new_value)
	if slider_input_node.value != new_value:
		slider_input_node.value = new_value

func _on_ValueInput_text_changed(new_text: String):
	var new_value = float(new_text)
	self.value = new_value

func _on_SliderInput_value_changed(new_value: float):
	self.value = new_value
