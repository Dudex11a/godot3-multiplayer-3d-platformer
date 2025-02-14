extends WorldEnvironment
class_name LevelEnvironment
tool

var temp_environment: Environment = null
var enabled: bool = true

#func _ready():
#	# Disable visuals if Mac
#	match OS.get_name():
#		"Windows":
#			for child in get_children():
#				child.visible = true
#		"OSX":
#			for child in get_children():
#				child.visible = false

func set_enabled(value: bool):
	enabled = value
	# Enable or disable environment
	if enabled:
		if is_instance_valid(temp_environment):
			environment = temp_environment
	else:
		if is_instance_valid(environment):
			temp_environment = environment
			environment = null
	# Toggle lights
	set_light_visibility(value)

func set_light_visibility(value: bool):
	for child in get_children():
		if child is Light:
			child.visible = value
