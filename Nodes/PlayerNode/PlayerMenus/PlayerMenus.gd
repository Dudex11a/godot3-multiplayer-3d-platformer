extends Control

onready var screens_node: = $Screens
onready var main_menu_node: = screens_node.get_node("MainMenu")
onready var af_maker_node: = screens_node.get_node("AnimalFriendMaker")
onready var buttons_node: = main_menu_node.get_node("ScrollContainer/Buttons")
onready var player_save_select: = $Screens/PlayerSaveSelect

var player_node: PlayerNode = null setget set_player_node
var controller_data: ControllerData = null
var focus_cursor: FocusCursor = null

signal loaded_save(player_save)

func _ready():
	# Create focus_cursor
	focus_cursor = CustomFocus.add_cursor()
	# PlayerNode controls when the focus_cursor is enabled
	yield(focus_cursor, "ready")
	focus_cursor.enabled = false
#	# Initialize af_maker path
#	while not is_instance_valid(player_node):
#		yield(get_tree(), "idle_frame")
#	var af_path: String = "../%s" % [player_node.get_player_id()]
#	af_maker_node.initialize_af_from_path(af_path)

func save_and_reset_af_maker():
	# Set af_info in player
	var character_node: Character = player_node.character_node
	character_node.set_af_info(af_maker_node.af_info)
	player_node.get_player().player_save.character_info.af_info = af_maker_node.af_info
	# Save to af file
	af_maker_node.save_current_af()
	# Save player
	player_node.save()
#	player_node.get_player_save().save_to_file()
	
	af_maker_node.editor_node.goto_directory(af_maker_node.editor_node.default_path)

# ===== setget

func set_player_node(value: PlayerNode):
	player_node = value
	# Connect signals
	player_node.connect("controller_input_event", self, "player_input_event")

func set_controller_data():
	if is_instance_valid(player_node):
		if is_instance_valid(player_node.controller_data):
			controller_data = player_node.controller_data
			focus_cursor.controller_data = controller_data

func set_active_screen(screen_name: String):
	# Reset controller_data
	if not is_instance_valid(controller_data):
		set_controller_data()
	
	var last_active_screen: Control = null
	
	# Hide other screens
	for child in screens_node.get_children():
		if child.visible:
			last_active_screen = child
			child.visible = false
	
	# Show and set focus to screen_name
	var active_node: Control = screens_node.get_node_or_null(screen_name)
	if is_instance_valid(active_node):
		if is_instance_valid(focus_cursor):
			focus_cursor.set_current_node(active_node)
		
		active_node.visible = true
		focus_cursor.set_current_node(active_node)
		if active_node.has_method("open"):
			active_node.open()

func get_active_screen() -> Control:
	var active_screen: Control = null
	
	for child in screens_node.get_children():
		if child.visible:
			active_screen = child
	
	return active_screen

func get_active_screen_name() -> String:
	var active_screen: Node = get_active_screen()
	if is_instance_valid(active_screen):
		return active_screen.name
	return ""

# ===== Game methods =====

func DisableLocalPlayerInput(value: bool, id: String):
	if player_node.is_local:
		if visible:
			focus_cursor.enabled = not value

# ===== Signals

func _on_Buttons_exit_main_menu():
	player_node.toggle_menus()

func _on_ResumeButton_pressed():
	player_node.toggle_menus()

func _on_CharacterButton_pressed():
	af_maker_node.focus_cursor = focus_cursor
	set_active_screen("AnimalFriendMaker")
	
func exit_af_maker():
	save_and_reset_af_maker()
	set_active_screen("MainMenu")

func _on_QuitButton_pressed():
	get_tree().call_group("Game", "RemoveLocalPlayer", player_node.get_player_id())

func _on_CharacterMenus_tree_exiting():
	# Remove focus_cursor
	if is_instance_valid(focus_cursor):
		focus_cursor.queue_free()

func _on_PlayerSaveSelect_exit():
	# Don't continue if there isn't a af_node
	if not is_instance_valid(player_node.character_node.af_node):
		return
	# Normally just go to MainMenu but if the "PlayerSaveSelect" value
	# is in the disable_menu_array it means that it was on the PlayerSaveSelect
	# when the player loaded so exit the menu when the save is selected.
	if "PlayerSaveSelect" in player_node.disable_menu_array:
		player_node.disable_menu_array.erase("PlayerSaveSelect")
		player_node.toggle_menus(false)
		return
	
	set_active_screen("MainMenu")
#	if not "PlayerSaveSelect" in player_node.disable_menu_array:
#		set_active_screen("MainMenu")

func _on_Settings_exit():
	set_active_screen("MainMenu")

func _on_SettingsButton_pressed():
	set_active_screen("Settings")

func player_input_event(player_node: PlayerNode, event: InputEvent):
	# When event pressed
	if event.is_action_pressed("ui_menu"):
		var active_screen_name: String = get_active_screen_name()
		match active_screen_name:
			# Exit menu if menu is pressed on MainMenu
			"MainMenu":
				# Wait for menu to potentially open
				player_node.toggle_menus()
			# Have these menus redirect to main menu
			"Settings":
				set_active_screen("MainMenu")
			"AnimalFriendMaker":
				exit_af_maker()

func _on_PlayerSaveSelect_loaded_save(player_save: PlayerSave):
	# Load af_info in af_maker
	var af_info: AnimalFriendInfo = player_save.character_info.af_info
	af_maker_node.af_info = af_info
	af_maker_node.af_node.set_af_info(af_info)
	emit_signal("loaded_save", player_save)
