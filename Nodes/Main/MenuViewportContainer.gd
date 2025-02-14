extends ViewportContainer

# Store mouse input because of bug
func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		CustomFocus.add_mouse_input(event, "MenuViewport")
