extends Control

onready var player_menus: = get_node("../..")
onready var dtab_container: = $DTabContainer
onready var tab_hbox_container: = dtab_container.get_node("TabScrollContainer/TabHBoxContainer")
onready var content_node: = dtab_container.get_node("Content")
onready var general_node: = content_node.get_node("General")
onready var back_button: = $BackButton

signal exit

func get_player_save() -> PlayerSave:
	return player_menus.player_node.get_player_save()

func get_general_settings_from_player() -> Dictionary:
	# Load settings from Player
	var player_save: PlayerSave = get_player_save()
	if is_instance_valid(player_save):
		# If has settings
		return player_save.general_settings
	return {}

func save_general_to_player():
	# Save settings to Player
	if is_instance_valid(player_menus):
		var player_save: PlayerSave = player_menus.player_node.get_player_save()
		if is_instance_valid(player_save):
			# Overwrite settings
			player_save.general_settings = general_node.get_options_dic()

func open():
	# Load settings from Player when menu is opened
	var general_settings: Dictionary = get_general_settings_from_player()
	if general_settings.size() > 0:
		general_node.load_options_dic(general_settings)

func exit():
	# Save Player when exiting Settings
	player_menus.player_node.save()
#	var player_save: PlayerSave = get_player_save()
#	if is_instance_valid(player_save):
#		player_save.save_to_file()
	# Exit
	emit_signal("exit")

# ===== Focus

func focus_entered(focus: FocusCursor):
	focus.set_current_node(tab_hbox_container)

# ===== Signals

func _on_BackButton_pressed():
	exit()

func _on_Controls_looped(focus: FocusCursor, loop: int):
	match loop:
		1: # Down
			focus.set_current_node(tab_hbox_container)

func _on_General_save(_save_dic: Dictionary):
	save_general_to_player()

func _on_General_option_changed(_option_name: String, _value):
	save_general_to_player()

func _on_DTabContainer_tab_looped(focus: FocusCursor, looped: int):
	match looped:
		1:
			focus.set_current_node(back_button)

func _on_Options_looped(focus: FocusCursor, looped: int):
	# Options up loop go to tabs
	match looped:
		1:
			focus.set_current_node(tab_hbox_container)
