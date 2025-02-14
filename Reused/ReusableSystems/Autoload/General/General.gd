extends Node

# The key to be held while pressing a number to run a debug method
const debug_key: String = "Alt"
const input_image_path: String = "res://Reused/Resources/Icons/Input/"

var resources_path: String = ""
# Resources object
var R: Resources
var debug_text_node: DebugText

onready var input_images: Dictionary = directory_to_dictionary(input_image_path)

signal debug_method

enum {
	DIR_UP,
	DIR_RIGHT,
	DIR_DOWN,
	DIR_LEFT
}

func _init():
	load_resource_container(self, "Resources/Resources.tscn")

func _ready():
	debug_text_node = R.debug_text_res.instance()
	add_child(debug_text_node)

func _input(event):
	if event is InputEventKey:
		if event.is_pressed():
			# Get the keyboard character pressed in from the scancode
			var scancode_character: String = OS.get_scancode_string(event.scancode)
			# Check if the debug key is pressed
			var debug_key_pressed: bool = Input.is_key_pressed(OS.find_scancode_from_string(debug_key))
			# If the key pressed is a number and the debug key is being pressed
			if scancode_character.is_valid_integer() and debug_key_pressed:
				debug_method(int(scancode_character))

func get_script_directory(script: Reference) -> String:
	var directory: String = script.get_path()
	return directory.replace(directory.get_file(), "")

func load_resource_container(parent: Node = self, path: String = "Resources.tscn", property_name: String = "R"):
	# Get resources path dynamically
	var resource_container_path = get_script_directory(parent.get_script()) + path
	# Load resources into General
	var resource_container = load(resource_container_path).instance()
	parent[property_name] = resource_container
	parent.add_child(resource_container)

func debug_method(id: int):
	match id:
		# When the "1" key is pressed
#		1:
#			debug_print("Method 1")
		# Default behavior
		_:
			debug_print("There is no debug method for id: " + String(id))
	emit_signal("debug_method", id)

func debug_print(val, length: float = 3):
	if is_instance_valid(debug_text_node):
		debug_text_node.debug_print(val, length)
	else:
		print(val)

func debug_value(id: String, value):
	if is_instance_valid(debug_text_node):
		debug_text_node.debug_value(id, value)
	else:
		print(value)

# Write keys over another dictionary
func overwrite_dic(base: Dictionary, replacement: Dictionary, duplicate: bool = true) -> Dictionary:
	# Decouple base from it's reference
	if duplicate:
		base = base.duplicate(true)
	for key in replacement.keys():
		var val = replacement[key]
		base[key] = val
	return base

# Overwrite values in an object
# The difference in the from the function above is that this edits the
# original object, the one above creates a new dictionary
func overwrite_object(base: Object, replacement: Dictionary) -> Object:
	for key in replacement.keys():
		var val = replacement[key]
		if key in base:
			base[key] = val
	return base

# If point is within the box of 2 Vector2s
# point = Position to check if in box, pos = Position of box, size = Size of box
func within_box(point: Vector2, pos: Vector2, size: Vector2) -> bool:
	var val = true
	for axis in ["x", "y"]:
		var within : bool = (point[axis] >= pos[axis]) && (point[axis] <= pos[axis] + size[axis])
		if not within: val = false
	return val

func reparent_node(what: Node, where: Node):
	what.get_parent().remove_child(what)
	where.call_deferred("add_child", what)
# I'm unsure what usage 8912 and 8199 are right now but
# it's consistant with the properties I want when finding properties.
const valid_property_ids: = [ 8192, 8199 ] 

func get_property_names(object: Object, code: String = "") -> Array:
	var properties := []
	# This gets all the properties from this object
	# and puts the ones I want in a Dictionary.
	for property in object.get_property_list():
		# If the property.usage matches any of the ids
		# then set it to valid
		var is_valid: = false
		for id in valid_property_ids:
			if property.usage == id and not is_valid:
				is_valid = true
		# If it's valid and the name doesn't start with "_"
		if is_valid and property.name[0] != "_":
			if code == "" or property.name.find(code) > -1:
				# If the variable name has the code if there is one
				properties.append(property.name)
	return properties

func print_file_error(func_name: String, error, path: String):
	var error_string = func_name + "   Error: " + String(error) + "   Path: " + path
	push_error(error_string)

func get_file_paths(path: String, is_file: bool = true, get_full_path: bool = true) -> Array:
	var file_paths: Array = []
	var dir: = Directory.new()
	if dir.dir_exists(path):
		# Loop through the directory
		var error: = dir.open(path)
		if error == OK:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				# Append the file or directory path
				if ((is_file and not dir.current_is_dir()) or (not is_file and dir.current_is_dir())) and file_name[0] != ".":
					if get_full_path:
						file_paths.append(path + file_name)
					else:
						file_paths.append(file_name)
				file_name = dir.get_next()
		else:
			print_file_error("get_file_paths", error, path)
	else:
		# Create directory if it doesn't exist
		dir.make_dir_recursive(path)
	return file_paths

func save_json_file(path: String, dic: Dictionary):
	# Create directories leading up to path
	var dir: = Directory.new()
	dir.make_dir_recursive(path.trim_suffix(path.get_file()))
	# Save file
	var file: = File.new()
	var error = file.open(path, File.WRITE)
	if error == OK:
		file.store_line(JSON.print(dic, "\t"))
	else:
		print_file_error("save_json_file", error, path)
	file.close()

func load_json_file(path: String) -> Dictionary:
	# Exit if file doesn't exist
	var dir: = Directory.new()
	if not dir.file_exists(path):
		return {}
	# Load file
	var dic: Dictionary = {}
	var file: = File.new()
	var error = file.open(path, File.READ)
	if error == OK:
		var file_as_text: String = file.get_as_text()
		var json_result = JSON.parse(file_as_text).result
		if json_result:
			dic = json_result
		else:
			debug_print("Issue parsing json\nFile as text: " + file_as_text
			+ "\nJson Result: " + String(json_result),
			0)
	else:
		print_file_error("load_json_file", error, path)
	file.close()
	return dic

func get_project_path() -> String:
	# Use project path by default, this path is for in editor testing.
	var path: = ProjectSettings.globalize_path("res://")
	# If it didn't get a path prior, get the executable path.
	if path == "":
		path = OS.get_executable_path().get_base_dir() + "/"
	return path

func do_resources_match(res1, res2) -> bool:
	var value: bool = true
	if is_instance_valid(res1) and is_instance_valid(res2):
		if res1.resource_path != res2.resource_path:
			value = false
	else:
		value = false
	return value


# These functions are primarily used for serializing colors to be sent
# over a network as I can't send Color objects without it converting to
# a String.

const color_identifier: String = "<COLOR>"

func color_to_string(color: Color) -> String:
	return color_identifier + String(color)

func string_to_color(value) -> Color:
	if value is Color:
		return value
	elif value is String:
		var convertable_string: String = value.replace(color_identifier, "")
		var color_values: Array = convertable_string.split(",")
		var r: float = float(color_values[0])
		var g: float = float(color_values[1])
		var b: float = float(color_values[2])
		var a: float = float(color_values[3])
		return Color(r, g, b, a)
	return Color.magenta
	
func color_in_object_to_string(object) -> Dictionary:
	if object is Dictionary:
		for key in object.keys():
			object[key] = color_in_object_to_string(object[key])
	elif object is Array:
		for index in range(object.size()):
			object[index] = color_in_object_to_string(object[index])
	elif object is Color:
		object = color_to_string(object)
	return object

func string_in_object_to_color(object) -> Dictionary:
	if object is Dictionary:
		for key in object.keys():
			object[key] = string_in_object_to_color(object[key])
	elif object is Array:
		for index in range(object.size()):
			object[index] = string_in_object_to_color(object[index])
	elif object is String:
		if color_identifier in object:
			object = string_to_color(object)
	return object

func get_parent_theme_node(node: Node) -> Node:
	if is_instance_valid(node):
		if "theme" in node:
			if is_instance_valid(node.theme):
				return node
		return get_parent_theme_node(node.get_parent())
	return null

func get_node_theme(node: Node) -> Theme:
	var theme: Theme = null
	var node_with_theme: Node = get_parent_theme_node(node)
	if is_instance_valid(node_with_theme):
		theme = node_with_theme.theme
	else:
		theme = load(ProjectSettings.get("gui/theme/custom"))
	return theme

func get_parent_of_type(node: Node, type) -> Node:
	if is_instance_valid(node):
		var parent: = node.get_parent()
		if parent is type:
			return parent
		else:
			return get_parent_of_type(parent, type)
	else:
		return null

func get_parent_of_class_name(node: Node, type: String) -> Node:
	if is_instance_valid(node):
		var parent: = node.get_parent()
		if parent.to_class() == type:
			return parent
		else:
			return get_parent_of_class_name(parent, type)
	else:
		return null

# Return parent node with property if any have that property
func get_parent_with_property(node: Node, property_id: String):
	if is_instance_valid(node):
		var parent: = node.get_parent()
		if property_id in parent:
			return parent
		else:
			return get_parent_with_property(parent, property_id)
	else:
		return null

# TEMP, idk if I really use this
func create_popup_control(position: Vector2, node = R.get_instance("popup_control_node")):
	pass
#	get_viewport().add_child(node)
#	node.popup(position)

func directory_to_dictionary(path: String) -> Dictionary:
	var dictionary: Dictionary = {}
	# Check for files in directory
	var file_names: Array = get_file_paths(path, true, false)
	for file_name in file_names:
		var file_path: String = path + file_name
		var file_name_no_extention: String = file_name.split(".")[0]
		# Process file depending on file extentions
		if ".png.import" in file_name:
			file_path = file_path.replace(".import", "")
			var image = load(file_path)
			dictionary[file_name_no_extention] = image
#		elif not is_any_in_array_true([
#			".ini" in file_path,
#			".txt" in file_path,
#			".aseprite" in file_path,
#		]):
		elif is_any_in_array_true([
			".json" in file_path,
			".tres" in file_path,
		]):
			var object = load(file_path)
			dictionary[file_name_no_extention] = object
	# Get directories in path
	var dir_names: Array = get_file_paths(path, false, false)
	for dir_name in dir_names:
		# Add child directory to the dictionary
		dictionary[dir_name] = directory_to_dictionary(path + dir_name + "/")
	return dictionary

# Get a Controls position relative to a parent, particularly a parent more than
# one node up in the hierarchy.
func get_position_relative_to_parent(parent: Node, child: Node) -> Vector2:
	var position: Vector2 = Vector2.ZERO
	# Check if child is actually a child of the parent
	if parent.is_a_parent_of(child):
		var next_parent: Node = child
		# Run this until the next_parent is parent (the final parent)
		while next_parent != parent:
			# Add position if parent is Control node
			if next_parent is Control:
				position += next_parent.rect_position
			# Set the next_parent to the next parent
			next_parent = next_parent.get_parent()
	else:
		push_error("parent is not parent of child")
	return position

# Remove any characters that aren't valid in a filename from a String
func create_filename(string: String) -> String:
	var invalid_characters: Array = [":", "/", "\\", "?", "*", '"', "|", "%", "<", ">"]
	for character in invalid_characters:
		string.replace(character, "")
	return string

func get_all_viewports_of_world(world: World, node: Node = get_viewport()) -> Array:
	var viewports: Array = []
	# Check if node is viewport
	if node is Viewport:
		viewports.append(node)
	# Check the children if they have viewports
	for child in node.get_children():
		viewports.append_array(get_all_viewports_of_world(world, child))
	return viewports

func lerp_vec3_w_vec3(a: Vector3, b: Vector3, weight: Vector3):
	var product: = Vector3.ZERO
	for axis in ["x", "y", "z"]:
		product[axis] = lerp(a[axis], b[axis], weight[axis])
	return product

# Get all children of a node that match the type given
func get_children_of_type(node: Node, type) -> Array:
	var children: Array = []
	for child in node.get_children():
		if child is type:
			children.append(child)
		children.append_array(get_children_of_type(child, type))
	return children

# Get all children of a node that has the class
func get_children_of_class(node: Node, class_str: String) -> Array:
	var children: Array = []
	if class_str in node.get_class():
		children.append(node)
	for child in node.get_children():
		children.append_array(get_children_of_class(child, class_str))
	return children

# Credit : https://godotengine.org/qa/45609/how-do-you-rotate-spatial-node-around-axis-given-point-space
func rotate_around(obj: Spatial, point: Vector3, axis: Vector3, angle: float):
	var rot: float = angle + obj.rotation.y 
	var tStart: Vector3 = point
	obj.global_translate (-tStart)
	obj.transform = obj.transform.rotated(axis, -rot)
	obj.global_translate (tStart)

func vec2_clamp(value: Vector2, start: Vector2, end: Vector2) -> Vector2:
	var final_value: Vector2 = value
	for axis in ["x", "y"]:
		final_value[axis] = clamp(value[axis], start[axis], end[axis])
	return final_value

func get_next_child(node: Node, increment: int = 1) -> Node:
	var parent: Node = node.get_parent()
	return parent.get_children()[(node.get_index() + increment) % parent.get_child_count()]

enum {
	LOOPED_FORWARD,
	LOOPED_BACK
}

# The about function with more information returned
func get_next_child_ext(node: Node, increment: int = 1) -> Dictionary:
	var parent: Node = node.get_parent()
	var child_index: int = node.get_index() + increment
	# Return which way it looped if it did
	var looped: int = -1
	if child_index > (parent.get_child_count() - 1):
		looped = LOOPED_FORWARD
	if child_index < 0:
		looped = LOOPED_BACK
	return {
		"node" : parent.get_children()[(child_index) % parent.get_child_count()],
		"looped" : looped
		}

# Run a method in node if it exists
# I can also run "_parent" versions of the method with the parents if defined
# Return the nodes that ran the methods
func run_method_if_exists(node: Node, method_name: String, args: Array = [], parent_looped: int = 0) -> Array:
	var nodes_that_have_method: Array = []
	# Base node
	if node.has_method(method_name):
		nodes_that_have_method.append(node)
		# Call
		node.callv(method_name, args)
	# Call in parents
	var parent: Node = node
	var last_parent: Node = node
	var parent_method_name: String = method_name + "_"
	var parent_method_name_identifier: String = "p"
	for index in range(parent_looped):
		parent = parent.get_parent()
		if is_instance_valid(parent):
			# Create method name
			parent_method_name += parent_method_name_identifier
			# Run method
			if parent.has_method(parent_method_name):
				nodes_that_have_method.append(parent)
				# Add parent to parent_args
				var parent_args: Array = args.duplicate()
				parent_args.append(last_parent)
				# Call
				parent.callv(parent_method_name, parent_args)
				
			last_parent = parent
		else:
			# End if parent doesn't exist
			return nodes_that_have_method
	return nodes_that_have_method

func get_viewport_global_offset_in_node(node: Node) -> Vector2:
	# Add viewport container position if current_node is within another viewport
	var viewport_container: ViewportContainer = G.get_parent_of_type(node, ViewportContainer)
	if is_instance_valid(viewport_container):
		return viewport_container.get_global_rect().position
	return Vector2.ZERO

func array_is_true(array: Array) -> bool:
	for value in array:
		if not value:
			return false
	return true

func is_any_in_array_true(array: Array) -> bool:
	for value in array:
		if value:
			return true
	return false

func reverse_vec3(vec3: Vector3) -> Vector3:
	return ((vec3.abs() - Vector3(1, 1, 1)).abs()) * vec3.sign()

func is_node_network_master(node: Node, also_online: bool = true) -> bool:
	if get_tree().has_network_peer():
		return node.is_network_master()
	return not also_online

func get_node_network_master(node: Node) -> int:
	if get_tree().has_network_peer():
		return node.get_network_master()
	return 1

func set_node_network_master(node: Node, master_id: int):
	if get_tree().has_network_peer():
		node.set_network_master(master_id, true)

func go_back_directory(path: String) -> String:
	var split_dir_path: Array = path.split("/")
	split_dir_path.pop_back()
	path = ""
	for value in split_dir_path:
		path += value + "/"
	return path

func print_directory(dir_path: String):
	print(dictionary_to_string(directory_to_dictionary(dir_path)))

func dictionary_to_string(dic: Dictionary, string: String = "", indentation: int = 0):
	var final_string: String = ""
	for key in dic.keys():
		var value = dic[key]
		for index in range(indentation):
			final_string += "    "
		if value is Dictionary:
			final_string += key
			final_string += "\n"
			final_string += dictionary_to_string(value, final_string, indentation + 1)
		else:
			var value_as_string: String = ""
			if value == null:
				value_as_string = "null"
			elif value is Object:
				value_as_string = value.to_string()
			else:
				value_as_string = String(value)
			final_string += "%s : %s" % [key, value_as_string]
		final_string += "\n"
		
	return final_string

func dictionary_to_poolbytearray(value: Dictionary) -> PoolByteArray:
	return JSON.print(value).to_utf8()

func poolbytearray_to_dictionary(value: PoolByteArray) -> Dictionary:
	return JSON.parse(value.get_string_from_utf8()).result

func input_event_to_image(event: InputEvent, controller_type_override: String = "") -> StreamTexture:
	var controller_type: String = controller_type_override
	if controller_type == "":
		controller_type = get_controller_type_from_event(event)
	if event is InputEventJoypadButton or event is InputEventMouseButton:
		var file_name: String = "button_" + String(event.button_index)
		return input_images[controller_type][file_name]
	if event is InputEventJoypadMotion:
		var file_name: String = "axis_" + String(event.axis)
		return input_images[controller_type][file_name]
	return null

func get_controller_type_from_event(event: InputEvent) -> String:
	if "Joypad" in event.as_text():
		# Get event's joystick name
		var joy_name: String = Input.get_joy_name(event.device)
		# Check for different phrases in the joy names
		if is_any_in_array_true([
			"PS5" in joy_name,
			"PS4" in joy_name,
			"PS3" in joy_name,
			"PS2" in joy_name,
			"PS1" in joy_name,
			"PlayStation" in joy_name,
			"Play Station" in joy_name,
			"playstation" in joy_name,
			"play station" in joy_name
		]):
			return "PS"
		return "Xbox"
	if "Mouse" in event.as_text():
		return "Mouse"
	return "Keyboard"

func randomize_base_seed():
	seed((OS.get_ticks_msec() % 1000) + round(randi() % 1000))

# ===== COLOR STUFF

const color_scheme = [
	"Bright Bright",
	"Dark Bright",
	"Light Bright",
	"Dark Light"
]

func create_random_color_scheme(path: int = randi() % 4) -> Array:
	var colors: Array = []
	
	colors.append(create_dark_color())
	colors.append(create_light_color())
	
	match path:
		0:
			colors.append(create_bright_color())
			colors[2].h = colors[0].h
			colors.append(create_slight_color(colors[2]))
		1:
			colors.append(create_slight_color(colors[0]))
			colors.append(create_bright_color())
			colors[3].h = colors[2].h
		2:
			colors.append(create_slight_color(colors[1]))
			colors.append(create_bright_color())
			colors[3].h = colors[2].h
		3:
			colors.append(create_slight_color(colors[0]))
			colors.append(create_slight_color(colors[1]))
	
	colors.append(create_slight_color(colors[2]))
	
#	G.debug_print("Color Scheme: %s" % color_scheme[path])
	
	return colors

func create_random_color() -> Color:
	var color: = Color.white
	
	color.s = randf()
	color.v = randf()
	color.h = randf()
	
	return color

func create_bright_color() -> Color:
	var color: = Color.white
	
	color.v = 0.9 + get_random_slight_amount("v")
	color.s = 0.9 + get_random_slight_amount("s")
	color.h = randf()
	
	return color

func create_dark_color() -> Color:
	var color: = Color.white
	
	color.v = 0.15 + get_random_slight_amount("v")
	color.s = 0.95 + get_random_slight_amount("s")
	color.h = randf()
	
	return color

func create_light_color() -> Color:
	var color: = Color.white
	
	color.v = 0.9 + get_random_slight_amount("v")
	color.s = 0.1 + get_random_slight_amount("s")
	color.h = randf()
	
	return color

const slight_h_amount: float = 0.1
const slight_s_amount: float = 0.1
const slight_v_amount: float = 0.1
# This needs to be between 0.0 and 1.0
# This value makes sure this minimum distance is traveled when making a
# slight amount (examples:
# range is 0.4, the value will be within 0.6 - 1.0
# range is 0.8, the value will be within 0.2 - 1.0
const difference_range: float = 0.7

func get_random_slight_amount(type: String = "h", allow_negative: bool = true):
	var slight_amount: float = self["slight_%s_amount" % type]
	if randi() % 2 and allow_negative:
		slight_amount *= -1
	slight_amount *= (randf() * difference_range) + (1.0 - difference_range)
#	G.debug_print("Slight Amount   type: %s   value: %s" % [type, slight_amount])
	return slight_amount

func create_slight_color(color: Color) -> Color:
	var slight_color: Color = color
	
	slight_color.s = color.s + get_random_slight_amount("s", false)
	slight_color.v = color.v + get_random_slight_amount("v")
	slight_color.h = color.h + get_random_slight_amount("h")
	
	return slight_color

func create_different_hue_color(color: Color) -> Color:
	var different_hue: Color = color
	
	return color

func create_different_value_color(color: Color) -> Color:
	var different_value: Color = color
	
	return color
