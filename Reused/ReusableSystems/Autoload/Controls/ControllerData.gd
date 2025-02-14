extends Reference
class_name ControllerData

var device_type: String = ""
var device_id: int = -1

func _init(value = ["", -1]):
	if value is InputEvent:
		device_type = Controls.get_input_device_type(value)
		device_id = value.device
	if value is Dictionary:
		if "device_type" in value:
			device_type = value[device_type]
		if "device_id" in value:
			device_id = value[device_id]
	if value is Array:
		if value.size() >= 1:
			device_type = value[0]
		if value.size() >= 2:
			device_id = value[1]

func event_matches(event: InputEvent) -> bool:
	# End if device doesn't match or isnt -1
	if event.device != device_id and (device_id >= 0 and event.device >= 0):
		return false
	var event_device_type: String = Controls.get_input_device_type(event)
	# Allow keyboard events to match mouse
	if event_device_type == "keyboard" and device_type == "mouse":
		return true
	if event_device_type == "mouse" and device_type == "keyboard":
		return true
	return event_device_type == device_type or device_type == ""

func _to_string() -> String:
	return device_type + " " + String(device_id)

func to_name() -> String:
	var name: String = "unknown"
	match device_type:
		"keyboard", "mouse":
			name = "Keyboard and Mouse"
		"joypad":
			var joypad_name: String = Input.get_joy_name(device_id)
			# Set default joypad name
			name = joypad_name
			# Name joypad based on special conditions
			if "GameCube" in joypad_name:
				name = "GameCube " + Controls.controller_abbreviation
			if "XInput" in joypad_name:
				name = "XInput " + Controls.controller_abbreviation
			# Add device id to end
			name += " " + String(device_id)
	return name

func can_use_mouse() -> bool:
	return "Mouse" in to_name() or "unknown" in to_name()
