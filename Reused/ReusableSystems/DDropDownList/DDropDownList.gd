extends Control
class_name DDropDownList

onready var background_node: = $_Background
onready var list_container: = $ListContainer
onready var open_button: = $OpenButton
onready var down_arrow_texture: = $DownArrow/TextureRect
onready var canvas_layer: = $CanvasLayer

export(Array, String) var values = []
export var dd_list_item_res: PackedScene

var current_value: String setget set_current_value
var current_node: Control = null

signal value_changed(value)

func _ready():
	add_list_items()
	update_list()

#func _input(event: InputEvent):
#	if event.is_action_pressed("debug_2"):
#		print(current_node.rect_position.y)
#	# Close if mouse input outside of dropdown
#	if event is InputEventMouseButton:
#		if event.button_index == 1 and is_open():
#			if not G.within_box(event.position, list_container.rect_global_position, list_container.rect_size):
#				close_drop_down()

func update_list():
	# Connect already existing items in list
	for child in list_container.get_children():
		connect_list_item(child)
	
	if list_container.get_child_count() > 0:
		# Don't use the set_current_value method
		current_value = list_container.get_children()[0].name
		current_node = list_container.get_node_or_null(current_value)
		adjust_container_position()
		
	update_list_container_size()
	update_min_y_size()
	close_drop_down()

func add_list_items():
	# Create new text items for values
	for value in values:
		# Create item
		var dd_list_item = dd_list_item_res.instance()
		list_container.add_child(dd_list_item)
		dd_list_item.text = value
		dd_list_item.name = value
		connect_list_item(dd_list_item)

func connect_list_item(node: Control):
	if not node.is_connected("pressed", self, "item_pressed"):
		node.connect("pressed", self, "item_pressed", [node])
	if not node.is_connected("cancel", self, "item_cancel"):
		node.connect("cancel", self, "item_cancel", [node])

func empty_list():
	# Remove old list items
	for child in list_container.get_children():
		child.queue_free()

func update_list_container_size():
	var size_y: float = get_list_container_contents_y_size()
	list_container.rect_size.y = size_y
#	background_node.rect_size.y = list_container.rect_size.y

func update_min_y_size():
	if is_instance_valid(current_node):
		rect_min_size.y = current_node.rect_size.y

func get_list_container_contents_y_size() -> float:
	var combined_list_item_height: float = 0.0
	if list_container.get_child_count() > 0:
		for list_item in list_container.get_children():
			combined_list_item_height += list_item.rect_size.y
	else:
		combined_list_item_height = rect_size.y
	return combined_list_item_height

func open_drop_down(focus: FocusCursor = null):
	# Move ListContainer to CanvasLayer so it's visible over other Control nodes
	if list_container.get_parent() != canvas_layer:
		list_container.visible = false
		update_canvas_layer_rect()
		var old_rect_size: Vector2 = list_container.rect_size
		G.reparent_node(list_container, canvas_layer)
		yield(get_tree(), "idle_frame")
		list_container.rect_size = old_rect_size
		list_container.visible = true
	#
	rect_clip_content = false
	open_button.visible = false
	# Set position depending if list is hanging out of viewport
	var viewport: Viewport = G.get_parent_of_type(self, Viewport)
	if ((rect_global_position.y + list_container.rect_size.y) + list_container.rect_size.y) < viewport.size.y:
		list_container.rect_position.y = 0
	else:
		var last_node_size_y: float = list_container.get_children()[list_container.get_child_count() - 1].rect_size.y
		set_list_container_y_position(last_node_size_y - list_container.rect_size.y)
		down_arrow_texture.flip_v = true
	if is_instance_valid(focus):
		focus.set_current_node(current_node)

func close_drop_down(focus: FocusCursor = null):
	# Move ListContainer back down a level
	if list_container.get_parent() != self:
		var old_rect_size: Vector2 = list_container.rect_size
		G.reparent_node(list_container, self)
		yield(get_tree(), "idle_frame")
		move_child(list_container, 1)
		list_container.rect_size = old_rect_size
	#
	rect_clip_content = true
	open_button.visible = true
	down_arrow_texture.flip_v = false
	if is_instance_valid(focus):
		focus.set_current_node(self)

func is_open() -> bool:
	return not rect_clip_content

func update_canvas_layer_rect():
	canvas_layer.offset = rect_global_position

# ===== Focus

func ui_accept_action(focus: FocusCursor):
	open_drop_down(focus)

# ===== setget

func set_current_value(value: String = current_value):
	current_value = value
	# Set node
	current_node = list_container.get_node_or_null(current_value)
	adjust_container_position()
	
	emit_signal("value_changed", current_value)

func adjust_container_position():
	# Set list container position so the current value is visible
	if is_instance_valid(current_node):
		list_container.rect_position.y = -current_node.rect_position.y

func set_list_container_y_position(value: float):
	list_container.rect_position.y = value
#	background_node.rect_position.y = list_container.rect_position.y

# ===== Signals

func item_pressed(focus: FocusCursor, node: Control):
	self.current_value = node.name
	close_drop_down(focus)

func item_cancel(focus: FocusCursor, node: Control):
	close_drop_down(focus)
	adjust_container_position()

func _on_OpenButton_pressed():
	open_drop_down()

# Update container_position if visible and closed
func _on_DDropDownList_visibility_changed():
	if is_visible_in_tree() and not is_open():
		yield(get_tree(), "idle_frame")
		adjust_container_position()

# Change CanvasLayer offset when rect changed
func _on_DDropDownList_item_rect_changed():
	if is_instance_valid(canvas_layer):
		update_canvas_layer_rect()
