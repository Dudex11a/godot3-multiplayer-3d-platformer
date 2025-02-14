extends ViewportContainer
class_name PlayerNode

onready var viewport_node: = $Viewport
onready var character_node: = viewport_node.get_node("Character")

var menus_node: Control = null
var hud_node: Control = null
var camera_node: Spatial = null
#var af_maker_node: AnimalFriendMaker = null
# Is character local to the client
var is_local: bool = false setget set_is_local
var controller_data: ControllerData = null

var checkpoint: Spatial = null setget set_checkpoint

var disable_menu_array: Array = []

signal set_is_local
signal controller_input_event(player_node, input_event)

func _ready():
	# Match shadows to settings
	SetShadows()

func _input(event: InputEvent):
	# Store mouse input because of bug
	if event is InputEventMouseMotion and is_local:
		var player_id: = String(get_player_id())
		CustomFocus.add_mouse_input(event, player_id)
	
	# Abort if not controller
	var event_controller_data: = ControllerData.new(event)
	if is_instance_valid(controller_data):
		if controller_data.to_name() != event_controller_data.to_name():
			return
	else:
		return
	
	emit_signal("controller_input_event", self, event)
	
	if event.is_action_pressed("ui_menu") and not menus_node.is_visible_in_tree():
		toggle_menus()
	
	# DEBUG
#	if event is InputEventJoypadButton and event.is_pressed():
#		G.debug_print(G.input_event_to_image(event))
#	if event is InputEventJoypadMotion:
#		printt("Motion", event.axis)
	# ACTION STATUS
#	if event.is_action_pressed("debug_1"):
#		character_node.set_actions_from_status({
#			"Jump":{
#				"action_index":1, 
#				"children":{}, 
#				"up_velocity":33}
#			})
#	if event.is_action_pressed("debug_2"):
#		var status: Dictionary = {
#			"Jump": {
#				"action_index" :1, 
#				"children": {
#					"WallClimb": {
#						"action_index": 1,
#						"children": {}
#					}
#				}, 
#				"up_velocity": 33
#			},
#			"AirDash": {
#				"action_index": 2, 
#				"children": {
#					"Roll": {
#						"action_index": 2,
#						"children": {}
#					}
#				}
#			},
#			"Crouch": {
#				"action_index": 6, 
#				"children": {}
#			},
#			"Pickup": {
#				"action_index": 3, 
#				"children": {}
#			}
#		}
#		character_node.set_actions_from_status(status)
#	if event.is_action_pressed("debug_3"):
#		G.debug_print(character_node.get_action_status())
		

func _process(delta):
#	# Debug character state
#	G.debug_value(name, character_node.state_info)
#	# Debug move input
#	G.debug_value(name, character_node.move_input)
	# Debug h speed
#	G.debug_value(name, character_node.get_horizontal_velocity())
#	Debug velocity
#	G.debug_value(name, character_node.velocity.y)
#	Debug up dir
#	G.debug_value("%s snap" % name, character_node.snap)
#	G.debug_value("%s snap multiplier" % name, character_node.snap_multiplier)
#	G.debug_value("%s snap override" % name, character_node.snap_normal_override)
#	G.debug_value(name, character_node.up_direction)
#	Debug 
	pass

# Actions to take when toggling the menu
func toggle_menus(value: bool = not menus_node.visible, force: bool = false):
	# Return if not allowed
	if not is_menu_allowed() and not force:
		return
	# If using mouse also toggle if mouse is captured
	if "Mouse" in controller_data.to_name():
		if value:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if is_instance_valid(menus_node):
		# Enable input
		menus_node.focus_cursor.enabled = value
		
		# Disable or enable menu focus_cursor with menu toggle
		if value:
			menus_node.visible = true
			menus_node.mouse_filter = menus_node.MOUSE_FILTER_STOP
			# Goto main menu when opening menu
			menus_node.set_active_screen("MainMenu")
			character_node.add_disable_input("CharacterMenus")
			
			menus_node.focus_cursor.enabled = true
		else:
			var active_screen: Control = menus_node.get_active_screen()
			if is_instance_valid(active_screen):
				# Play exit animation if it exists
				if active_screen.has_method("exit_anim") and active_screen.has_signal("exit_anim_end"):
					active_screen.exit_anim()
					yield(active_screen, "exit_anim_end")
			# Close if visible
			if menus_node.visible:
				menus_node.visible = false
				menus_node.mouse_filter = menus_node.MOUSE_FILTER_IGNORE
				character_node.remove_disable_input("CharacterMenus")
#				menus_node.exit_af_maker(false)
				# Enable input
				menus_node.focus_cursor.enabled = false

func set_viewport_size(size: Vector2):
	rect_size = size
	viewport_node.size = size

func set_is_local(value: bool):
	is_local = value
	
	if value and "Mouse" in controller_data.to_name():
		# Capture mouse cursor
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if is_local:
		# Network master
		if is_instance_valid(get_tree().network_peer):
			set_network_master(get_tree().network_peer.get_unique_id())
		# Add menus and hud node if they don't already exist
		# HUD
		if not is_instance_valid(hud_node):
			hud_node = O3DP.R.get_instance("hud_node")
			viewport_node.add_child(hud_node)
		# CAMERA
		if not is_instance_valid(camera_node):
			camera_node = O3DP.R.get_instance("camera_node")
			viewport_node.add_child(camera_node)
		# PLAYER MENUS
		if not is_instance_valid(menus_node):
			menus_node = O3DP.R.get_instance("character_menus_node")
			viewport_node.add_child(menus_node)
			menus_node.visible = false
			menus_node.player_node = self
			menus_node.connect("loaded_save", self, "loaded_save")
			yield(get_tree(), "idle_frame")
			# Disable the ability to close the menu until save selected
			disable_menu_array.append("PlayerSaveSelect")
			# Initialize menu at save select
			toggle_menus(true, true)
			menus_node.set_active_screen("PlayerSaveSelect")
	else:
		character_node.add_disable_input("NotLocal")
		# Remove menus and hud node (I don't think this should ever happen)
		if is_instance_valid(menus_node):
			menus_node.queue_free()
			menus_node = null
		if is_instance_valid(hud_node):
			hud_node.queue_free()
			hud_node = null
		if is_instance_valid(camera_node):
			camera_node.queue_free()
			camera_node = null

func get_player_id() -> int:
	return int(name.split(O3DP.id_separator)[1])

func get_player() -> Player:
	# Get local if player_node is local
	if G.get_node_network_master(self):
		var main_node = O3DP.get_main()
		var id: String = String(get_player_id())
		if id in main_node.local_client.players:
			return main_node.local_client.players[id]
	return null

func get_player_save() -> PlayerSave:
	var player: Player = get_player()
	if is_instance_valid(player):
		return player.player_save
	return null

func get_game_mode_save(id: String = O3DP.get_current_game_mode_id()):
	var player_save: PlayerSave = get_player_save()
	if is_instance_valid(player_save):
		return player_save.get_game_mode_save(id)
	return null

#func get_default_af_info() -> AnimalFriendInfo:
#	var af_info: = AnimalFriendInfo.new()
#	af_info.from_dictionary(G.load_json_file("user://%s.af" % String(get_player_id())))
#	return af_info

func get_af_info_from_maker() -> AnimalFriendInfo:
	if is_instance_valid(menus_node):
		return menus_node.af_maker_node.af_info
	return null

func is_menu_allowed() -> bool:
	return disable_menu_array.size() == 0

func set_checkpoint(value: Spatial):
	checkpoint = value
	# Add checkpoint to save
	get_game_mode_save()

func respawn_character():
	# Reset character state
	character_node.reset_state()
	# Move to checkpoint
	# Client handles translation
	if G.is_node_network_master(character_node, false):
		character_node.global_transform.origin = checkpoint.get_respawn_pos()

func get_general_setting(setting_name: String):
	var player_save: PlayerSave = get_player_save()
	if is_instance_valid(player_save):
		var general_settings: Dictionary = player_save.general_settings
		if general_settings.has(setting_name):
			return general_settings[setting_name]
	return null

func save():
	# Load actions into save
	var game_mode_save: GameModeSave = get_game_mode_save()
	game_mode_save.action_status = character_node.get_action_status()
	# Save to file
	var player_save: PlayerSave = get_player_save()
	player_save.save_to_file()

# ===== Game methods =====

#func LocalPlayerLoadedSave(player: Player):
#	# Setup player node with Game Mode
#	if player != get_player(): return
#	printt(player, get_player())
	

func DisableLocalPlayerInput(value: bool, id: String):
	if is_local:
		if value:
			# Cannot open menu when local input is disabled
			disable_menu_array.append("LocalPlayerInput")
		else:
			disable_menu_array.erase("LocalPlayerInput")

func SetActiveScreen(screen_name: String):
	# Hide or Capture mouse if menu is open and what screen is shown if
	# Controller has mouse
	if is_instance_valid(controller_data) and is_local:
		if "Mouse" in controller_data.to_name():
			if screen_name == "":
				if not menus_node.is_visible_in_tree():
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func SetShadows(value: Dictionary = O3DP.get_shadow_settings()):
	O3DP.set_shadows_in_viewport(viewport_node, value)

# ===== Signals

func loaded_save(player_save: PlayerSave):
	# Create animal_friend and load new af_info
	character_node.set_af_info(player_save.character_info.af_info)
	# Set game mode
	var game_mode = O3DP.get_main().current_game_mode
	game_mode.player_node_setup(self)

#func _on_Player_tree_exiting():
#	get_tree().call_group("Game", "LocalPlayerExiting", get_player())

func _on_Character_action_added(action_node):
	if is_instance_valid(hud_node):
		hud_node.actions_node.add_action_hud(action_node)

func _on_Character_action_removed(action_node):
	if is_instance_valid(hud_node):
		hud_node.actions_node.remove_action_hud(action_node)
