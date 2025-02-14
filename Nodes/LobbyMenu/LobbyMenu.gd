extends Control

onready var vbox_container: = $VBoxContainer
onready var game_mode_select_node: = vbox_container.get_node("GameModeSelect")

signal back

func create_and_set_game_mode(game_mode_name: String = game_mode_select_node.selected_option):
	# Create
	var game_mode: GameMode = O3DP.make_game_mode_from_name(game_mode_name)
	# Set
	if is_instance_valid(game_mode):
		get_tree().call_group("Game", "SetGameMode", game_mode)
	else:
		G.debug_print("create_and_set_game_mode: Invalid GameMode")

func focus_entered(focus: FocusCursor):
	focus.set_current_node(game_mode_select_node)

func ui_cancel_action_pp(focus: FocusCursor, parent: Node):
	emit_signal("back")

func _on_ExitButton_pressed():
	emit_signal("back")

func _on_LoadButton_pressed():
	create_and_set_game_mode()
