extends OptionItem

onready var bool_input: = $BoolInput

# ===== setget

func set_value(new_value = value):
	if not is_instance_valid(bool_input):
		bool_input = $BoolInput
	bool_input.pressed = new_value
	.set_value(new_value)

# ===== Signals

func _on_BoolInput_pressed():
	set_value(bool_input.pressed)
