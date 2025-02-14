extends Control

onready var game_mode_container: = $GameMode
onready var actions_node: = $Actions

func call_game_mode_method(game_mode_type: String, method: String, args: Array = []):
	var game_mode_hud_node: Control = find_game_mode_hud(game_mode_type)
	if is_instance_valid(game_mode_hud_node):
		if game_mode_hud_node.has_method(method):
			game_mode_hud_node.callv(method, args)
	else:
		G.debug_print("HUD call_game_mode_method does not have game_mode_id \"%s\"" % game_mode_type)

func find_game_mode_hud(game_mode_id: String) -> Control:
	for child in game_mode_container.get_children():
		if "game_mode_id" in child:
			if child.game_mode_id == game_mode_id:
				return child
	return null
