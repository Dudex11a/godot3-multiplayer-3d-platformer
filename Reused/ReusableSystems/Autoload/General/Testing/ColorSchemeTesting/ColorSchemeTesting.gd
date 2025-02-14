extends Control

export var color_res: PackedScene = null

onready var hbox_container: = $HBoxContainer

func _ready():
	randomize()

func _input(event: InputEvent):
	if event.is_action_pressed("ui_accept"):
		create_color_scheme()
	elif event is InputEventKey and event.is_pressed():
		create_color_scheme(int(OS.get_scancode_string(event.scancode)))

func create_color_scheme(path: int = -1):
	# Clear old colors
	for child in hbox_container.get_children():
		child.queue_free()
	# Create new colors
	var color_scheme: Array
	if path >= 0:
		color_scheme = G.create_random_color_scheme(path)
	else:
		color_scheme = G.create_random_color_scheme()
	
	for color in color_scheme:
		var color_node: ColorRect = color_res.instance()
		hbox_container.add_child(color_node)
		color_node.color = color
