extends Control

onready var player_menus: = get_parent().get_parent()

onready var file_selector: = $FileSelector
onready var new_game_button: = $NewGameButton
onready var exit_button: = $ExitButton

signal loaded_save(player_save)
signal exit

#export var export_button_visible: bool = true setget set_export_button_visible
#
#func set_export_button_visible(value: bool):
#	export_button_visible = value
#	# Wait for button to be valid
#	if not is_instance_valid(exit_button):
#		yield(get_tree(), "idle_frame")
#	exit_button.visible = export_button_visible

func open():
	file_selector.refresh_file_list()

func create_new_game():
	# Create new PlayerSave
	var new_player_save: = PlayerSave.new()
	# Create new af_info within new save
	new_player_save.character_info.af_info = AnimalFriendInfo.new()
	new_player_save.file_name = new_player_save.get_new_filename()
	new_player_save.save_to_file()
	# Set player save in client
	var player = player_menus.player_node.get_player()
	player.player_save = new_player_save
	
	load_file(new_player_save.make_path_from_name(), player)

func exit():
	emit_signal("exit")

func load_file(file_path: String, player: Player):
	# Add to files loaded
	O3DP.get_main().loaded_save_files.append(file_path)
	# Send signal that save is loaded
	emit_signal("loaded_save", player.player_save)
	get_tree().call_group("Game", "LocalPlayerLoadedSave", player)
	# Remove file from other save selects
	get_tree().call_group("Game", "RemoveSaveFile", file_path)

# ===== SIGNALS

func _on_NewGameButton_pressed():
	# New Game
	create_new_game()
	# Exit
	exit()

func _on_FileSelector_focus_cursor_exit_file_list():
	exit()

func _on_ExitButton_pressed():
	exit()

func _on_FileSelector_file_selected(file_name: String, file_path: String):
	# Make save
	var new_player_save: = PlayerSave.new()
	new_player_save.from_dictionary(G.load_json_file(file_path))
	# Set player save in client
	var player = player_menus.player_node.get_player()
	player.player_save = new_player_save
	load_file(file_path, player)
	# Exit
	exit()

func _on_FileSelector_list_looped(focus: FocusCursor, looped: int):
	focus.set_current_node(new_game_button)
	
# ===== FOCUS

func focus_entered(focus: FocusCursor):
	focus.set_current_node(new_game_button)

func ui_cancel_action_p(focus: FocusCursor, parent: Node):
	# Exit if cancel if can exit
	if exit_button.visible:
		exit()

func ui_up_action_p(focus: FocusCursor, parent: Node):
	match focus.current_node.name:
		"NewGameButton", "ExitButton":
			file_selector.focus_goto_files(focus, false)
		"FileSelector":
			focus.set_current_node(new_game_button)

# ===== GAME GROUP

func RemoveSaveFile(file_path: String):
	# Move focus cursor if hovering that save
	var focus: FocusCursor = player_menus.focus_cursor
	if is_instance_valid(focus.current_node):
		var file_item_node: Node = focus.current_node.get_parent()
		if file_item_node.get_class() == "FileItem":
			if file_item_node.path == file_path:
				focus.set_current_node(new_game_button)
	# Remove file item
	file_selector.remove_file_item(file_path)
