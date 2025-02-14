extends DropDownItem

onready var label_node: = $Label

func set_text(value: String = text):
	.set_text()
	if is_instance_valid(label_node):
		label_node.text = value
