extends OptionItem

export(Array, String) var list_items: = []

onready var value_input_node: = $ValueInput

func _ready():
	value_input_node.values = list_items
	value_input_node.add_list_items()
	value_input_node.update_list()

#func _input(event):
#	if event.is_action_pressed("debug_1"):
#		print(value_input_node.current_value)

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
	if value_input_node.current_value != String(value):
		value_input_node.current_value = String(value)

func _on_ValueInput_value_changed(new_text: String):
	if new_text != "":
		self.value = new_text
