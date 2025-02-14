extends Control

onready var action_container: = $ActionsContainer

func add_action_hud(action_node: Action):
	var action_hud_node = O3DP.R.get_instance("action_hud_node")
	action_container.add_child(action_hud_node)
	action_hud_node.action_node = action_node

func remove_action_hud(action_node: Action):
	var action_id: String = action_node.name
	var action_hud_node = action_container.get_node(action_id)
	# Sometimes it likes to delete the same action multiple times
	if is_instance_valid(action_hud_node):
		action_hud_node.delete()

func clear_actions_hud():
	for child in action_container.get_children():
		child.delete()
