extends Control
class_name Keyboard

signal key_pressed(key)
signal commit_pressed
signal backspace_pressed
signal right_pressed
signal left_pressed
signal exit

func connect_keys(keys: Array):
	# Connect keys to key_pressed
	for key in keys:
		if key is Key:
			key.connect("pressed", self, "key_pressed")

func key_pressed(key: String):
	emit_signal("key_pressed", key)
