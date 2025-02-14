extends Control

onready var main_node: = get_node("..")
onready var preview_viewport_container: = get_node("../PreviewViewportContainer")
onready var title_screen_node: = preview_viewport_container.get_node("Viewport/TitleScreen")
onready var transition_anim_player: = get_node("../AnimationPlayer")

func add_child(node: Node, legible_unique_name: bool = false):
	.add_child(node, legible_unique_name)
	if node is PlayerNode:
		sort()
		# When is_local is set, update the viewport sizes
		node.connect("set_is_local", self, "sort")
		node.connect("tree_exited", self, "sort")

func sort():
	var current_x: float = 0
	var current_y: float = 0
	var viewport_size: Vector2 = calculate_viewport_size()
	var count: int = 0
	# Viewport size and child position
	for child in get_children():
		if child is PlayerNode:
			if child.is_local:
				# Size
				child.set_viewport_size(viewport_size)
				# Position
				var x_pos: int = count % calculate_column_amount()
				var y_pos: int = count / calculate_column_amount()
				child.rect_position.x = float(x_pos) * viewport_size.x
				child.rect_position.y = float(y_pos) * viewport_size.y
				count += 1
			else:
				child.set_viewport_size(Vector2.ZERO)
	
	# Hide preview viewport when a player is in the game
	if is_instance_valid(preview_viewport_container):
		var local_child_amount: int = main_node.get_local_players().size()
		var is_visible: bool = local_child_amount == 0
		preview_viewport_container.visible = is_visible
		title_screen_node.visible = is_visible

func get_active_viewport_amount() -> int:
	var amount: int = 0
	for child in get_children():
		if child.is_local:
			amount += 1
	return amount

func calculate_viewport_size() -> Vector2:
	var size: Vector2 = rect_size
	var viewport_amount: int = get_active_viewport_amount()
	size.y /= calculate_row_amount()
	size.x /= calculate_column_amount()
	return size

func calculate_column_amount() -> int:
	var column_amount: int = 1
	if get_active_viewport_amount() >= 3:
		column_amount = 2
	return column_amount

func calculate_row_amount() -> int:
	var viewport_amount: int = get_active_viewport_amount()
	var amount: int = 1
	if viewport_amount >= 2:
		amount = 2
#	if viewport_amount >= 3:
#		amount = ceil((float(amount) / 2.0) + 0.001)
	return amount

# Resize viewports on screen resize
func _on_Characters_resized():
	sort()
	rect_size = OS.window_size
