extends Control
class_name DColorPicker

onready var hue_node: = $Hue
onready var hue_selection_node: = hue_node.get_node("Selection")
onready var sat_value_node: = $SatValue
onready var sat_value_selection_node: = sat_value_node.get_node("Selection")
onready var final_color_node: = $_FinalColor

export var color: = Color(1.0, 0, 0) setget set_color

signal color_changed(color)

#func _ready():
#	# Initialize
#	set_color()

func _input(event: InputEvent):
	# Mouse Input
	if event is InputEventMouseButton and is_visible_in_tree():
		var within_hue: bool = false
		var within_sat_value: bool = false
		while Input.is_mouse_button_pressed(1):
			var mouse_pos: Vector2 = get_global_mouse_position()
			var relative_mouse_pos: = Vector2.ZERO
			# Within Hue
			if within_hue:
				relative_mouse_pos = G.vec2_clamp(hue_node.get_local_mouse_position(), Vector2.ZERO, hue_node.rect_size)
				var hue_value: float = relative_mouse_pos.y / hue_node.rect_size.y
				self.color.h = hue_value
			within_hue = G.within_box(mouse_pos, hue_node.rect_global_position, hue_node.rect_size)
			# Within SatValue
			if within_sat_value:
				relative_mouse_pos = G.vec2_clamp(sat_value_node.get_local_mouse_position(), Vector2.ZERO, sat_value_node.rect_size)
				var sat_value: float = relative_mouse_pos.x / sat_value_node.rect_size.x
				var value_value: float = abs((relative_mouse_pos.y / sat_value_node.rect_size.y) - 1.0)
				self.color.s = sat_value
				self.color.v = value_value
			within_sat_value = G.within_box(mouse_pos, sat_value_node.rect_global_position, sat_value_node.rect_size)
			# I use update here so input doesn't get cut off before max value can be reached
			yield(get_tree(), "idle_frame")

func set_color(value: Color = color):
	# Clamp and set values
	color.h = clamp(value.h, 0.0000001, 0.9999999)
	color.s = clamp(value.s, 0.0000001, 0.9999999)
	color.v = clamp(value.v, 0.0000001, 0.9999999)
	# Set Hue Selection position
	update_hue_position()
	# Set Saturation and Value Selection position
	update_sat_position()
	update_value_position()
	# Set SatValue shader Hue value
	set_sat_value_hue(color.h)
	# Set final color
	update_final_color()
	emit_signal("color_changed", color)

func update_hue_position():
	if is_instance_valid(hue_node):
		# normalized value to node position
		var position: float = color.h * hue_node.rect_size.y
		# Center node to position
		position -= hue_selection_node.rect_size.y / 2
		hue_selection_node.rect_position.y = position

func update_sat_position():
	if is_instance_valid(sat_value_node):
		# normalized value to node position
		var position: float = color.s * sat_value_node.rect_size.x
		# Center node to position
		position -= sat_value_selection_node.rect_size.x / 2
		sat_value_selection_node.rect_position.x = position

func update_value_position():
	if is_instance_valid(sat_value_node):
		# normalized value to node position
		var position: float = abs(color.v - 1.0) * sat_value_node.rect_size.y
		# Center node to position
		position -= sat_value_selection_node.rect_size.y / 2
		sat_value_selection_node.rect_position.y = position

func set_sat_value_hue(hue: float):
	if is_instance_valid(sat_value_node):
		sat_value_node.material.set("shader_param/hue", hue)

func update_final_color():
	if is_instance_valid(final_color_node):
		final_color_node.color = color

# ===== Focus

func focus_entered(focus: FocusCursor):
	focus.set_current_node(sat_value_node)
