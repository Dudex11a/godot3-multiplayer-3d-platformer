extends Node
class_name Main
func get_class() -> String: return "Main"

onready var world_node: = $World
onready var players_node: = $Players
onready var anim_player: = $AnimationPlayer
onready var add_remove_player_trans_node: = $AddRemovePlayerTrans
onready var title_screen: = $PreviewViewportContainer/Viewport/TitleScreen

onready var menu_viewport_container_node: = $MenuViewportContainer
onready var general_menu_node: = menu_viewport_container_node.get_node("Viewport/GeneralMenus")

onready var preview_viewport: = $PreviewViewportContainer/Viewport

export var splash_image: StreamTexture

const max_player_amount: int = 4

var current_game_mode: GameMode = null
var loaded_save_files: Array = []
# On ready so O3DP.O can initialize
onready var local_client: Client = Client.new()
var local_player_node: PlayerNode = null

var elapsed_time: float = 0.0

var accept_input_array: Array = []

signal local_player_created
signal local_player_removed

func _ready():
	# Set GameMode
	SetGameMode(CampaignGameMode.new())
	# Wait a moment for generic loading
	yield(get_tree().create_timer(0.15), "timeout")
	# Open game with circle transition from splash image
	play_transition(splash_image)
	SetShadows()

# Debug a list of things
func _process(delta: float):
	elapsed_time += delta * Engine.time_scale

func _input(event: InputEvent):
	# Player join
	# Keep track of what buttons have accept pressed for checking how long
	# it's held.
	var event_controller_data: = ControllerData.new(event)
	var controller_data_string: String = event_controller_data.to_string()
	if OS.is_window_focused() and not general_menu_node.is_visible_in_tree():
		# Yield so it doesn't check when the quit button is pressed
		yield(get_tree(), "idle_frame")
		# Add controller data if pressed and isn't already in array
		if event.is_action_pressed("start_game"):
			if not controller_data_string in accept_input_array:
				accept_input_array.append(controller_data_string)
				add_character_check(event_controller_data)
		if event.is_action_released("start_game"):
			if controller_data_string in accept_input_array:
				accept_input_array.erase(controller_data_string)
	
	# Open options
	if title_screen.is_visible_in_tree() and event.is_action_pressed("options_menu"):
		if general_menu_node.is_visible_in_tree():
			get_tree().call_group("Game", "SetActiveScreen", "")
		else:
			get_tree().call_group("Game", "SetActiveScreen", "Settings")
	
#	if event.is_action_pressed("debug_1"):
#		G.debug_print(O3DP.O.generate_o3dp_id())

func add_character_check(controller_data: ControllerData):
#	# Wait a period of time
#	yield(get_tree().create_timer(0.05), "timeout")
	# Check if button is still held
	if not controller_data.to_string() in accept_input_array:
		return
	# If character doesn't already exist
	if is_instance_valid(get_player_node_w_controller_data(controller_data)):
		return
	# Create character
	yield(CreateLocalPlayer(get_next_player_id(), controller_data), "completed")

func get_player_node_w_controller_data(controller_data: ControllerData) -> PlayerNode:
	var player_node: PlayerNode = null
	for child in players_node.get_children():
		if child is PlayerNode:
			if is_instance_valid(child.controller_data):
				if child.controller_data.to_string() == controller_data.to_string():
					player_node = child
	return player_node

func get_state() -> GameState:
	var state: GameState = GameState.new()
	state.local_client = local_client
	state.connected_clients = O3DP.O.connected_clients
	state.world_state = O3DP.get_states(world_node)
	state.player_state = O3DP.get_states(players_node)
	state.game_mode_state = current_game_mode.to_dictionary()
	return state

func set_state(state: GameState):
	O3DP.set_states(world_node, state.world_state)
	set_game_mode_from_dictionary(state.game_mode_state)
	O3DP.set_states(players_node, state.player_state)

func capture_mouse(val: bool):
		if val:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func get_player_node(client_id: int, player_id: int):
	var player_node = players_node.get_node(O3DP.make_character_name(client_id, player_id))
	if player_node is PlayerNode:
		return player_node
	return null

func get_local_player_node(player_id: int) -> PlayerNode:
	var player_node = players_node.get_node(O3DP.make_local_player_name(player_id))
	if player_node is PlayerNode:
		return player_node
	return null

func get_player_nodes() -> Array:
	var characters: Array = []
	for child in players_node.get_children():
		if child is PlayerNode:
			characters.append(child)
	return characters

func take_and_set_screenshot():
	# Screenshot
	var image: Image = get_viewport().get_texture().get_data()
	image.flip_y()
	# Texture
	var texture: = ImageTexture.new()
	texture.create_from_image(image)
	# Set
	set_screenshot(texture)

func set_screenshot(texture: Texture):
	add_remove_player_trans_node.material.set("shader_param/image", texture)

func move_characters_to_checkpoint(checkpoint: Spatial = null):
	for player in get_player_nodes():
		if player is PlayerNode:
			var character: Character = player.character_node
			if is_instance_valid(character):
				if is_instance_valid(checkpoint):
					player.checkpoint = checkpoint
					player.respawn_character()

# "Game" group functions

# Local create character and remove character
# (also add player to client)
func CreateLocalPlayer(player_id : int = get_next_player_id(), controller_data: = ControllerData.new()):
	var player_id_string: = String(player_id)
	# Check if local_id is valid in local_player_nodes
	if not player_id_string in local_client.players and local_client.players.size() < max_player_amount:
		# Play anim
		play_transition()
		# Yield to take picture for anim
		yield(get_tree(), "idle_frame")
		# Create Player
		var player: = Player.new()
		local_client.players[player_id_string] = player
		# Create Viewport Character
		var player_node: PlayerNode = O3DP.R.get_instance("player_node")
		players_node.add_child(player_node)
		player_node.controller_data = controller_data
		player_node.name = O3DP.make_local_player_name(player_id)
		# Wait for local to be set
		yield(player_node.set_is_local(true), "completed")
		# Setup player node for game mode
		current_game_mode.player_node_setup(player_node)
		# Character related
		var character_node: Character = player_node.character_node
		local_client.players[player_id_string].player_save.character_info = character_node.info
		character_node.global_transform.origin = world_node.get_spawn_location()
		
		
		
		emit_signal("local_player_created", player_id, player)
		
		players_node.sort()

func RemoveLocalPlayer(player_id: int = 0):
	var player_id_string: = String(player_id)
	if player_id_string in local_client.players:
		# Play anim
		play_transition()
		# Yield to take picture for anim
		yield(get_tree(), "idle_frame")
		var player_node: PlayerNode = get_local_player_node(player_id)
		# Remove loaded_save
		if is_instance_valid(player_node):
			var path: String = player_node.get_player_save().make_path_from_name()
			loaded_save_files.erase(path)
		# Remove Player
		var player: Player = local_client.players[player_id_string]
		local_client.players.erase(player_id_string)
		get_tree().call_group("Game", "LocalPlayerRemoved", player)
		# Remove Viewport Character
		if is_instance_valid(player_node):
			# Delete node
			player_node.queue_free()
			# Signal
			emit_signal("local_player_removed", player_id)
			# Sort viewports in player_node
			players_node.sort()

func SetGameMode(game_mode = current_game_mode):
	# Network
	if G.is_node_network_master(self):
#		rpc("set_game_mode_from_dictionary", game_mode.to_dictionary())
		O3DP.O.custom_rpc(self, "set_game_mode_from_dictionary", [game_mode.to_dictionary()])
	# Put away last game_mode
	if is_instance_valid(current_game_mode):
		current_game_mode.put_away()
	# Reset character state
	for player in get_player_nodes():
		var character: Character = player.character_node
		if is_instance_valid(character):
			character.reset_state()
	# Setup new game_mode
	current_game_mode = game_mode
#	game_mode.main_node = self
	game_mode.setup()
	get_tree().call_group("Game", "SetGameModeFinished")

remote func set_game_mode_from_dictionary(game_mode_dic: Dictionary):
#	G.debug_print(game_mode_dic)
	# Create correct game_mode
	var game_mode = O3DP.make_game_mode_from_dictionary(game_mode_dic)
	# Set
	if is_instance_valid(game_mode):
		SetGameMode(game_mode)

func get_local_players() -> Array:
	var local_players: Array = []
	for child in players_node.get_children():
		if child.is_local:
			local_players.append(child)
	return local_players

func change_network_id_in_characters(from: int, to: int):
	var player_nodes: Array = get_player_nodes()
	for player_node in player_nodes:
		var player_id: int = int(player_node.name.split(O3DP.id_separator)[1])
		if player_id == from:
			player_node.name = O3DP.make_character_name(to, player_id)

func update_network_id_in_local_players():
	var local_players: Array = get_local_players()
	for character in local_players:
		# Change name
		var player_id: int = int(character.name.split(O3DP.id_separator)[1])
		character.name = O3DP.make_local_player_name(player_id)
		# Change network master
		if is_instance_valid(get_tree().network_peer):
			character.set_network_master(get_tree().network_peer.get_unique_id())

func CreateSpectator():
	if not is_instance_valid(get_node_or_null("Spectator")):
		# Create spectator node
		var spectator_node: Spectator = O3DP.R.get_instance("spectator_node")
		add_child(spectator_node)
	# Hide MainMenu
#	toggle_main_menu(false)

func RemoveSpectator():
	var spectator_node: Spectator = get_node("Spectator")
	if is_instance_valid(spectator_node):
		# Remove spectator node
		spectator_node.queue_free()

func Quit():
	get_tree().quit()

func get_next_player_id() -> int:
	var id: int = 0
	var has_id: bool = true
	while has_id:
		if String(id) in local_client.players:
			id += 1
		else:
			has_id = false
	return id

func play_transition(texture: Texture = null):
	if is_instance_valid(texture):
		set_screenshot(texture)
	else:
		take_and_set_screenshot()
	anim_player.play("CircleTransition")

# ===== Game methods =====

func SetActiveScreen(screen_name: String = ""):
	# Default screen_name value will hide and re-enable Players
	var show: bool = screen_name != ""
	menu_viewport_container_node.visible = show
	general_menu_node.visible = show


# ===== Settings methods =====

func SetShadows(value: Dictionary = O3DP.get_shadow_settings()):
	O3DP.set_shadows_in_viewport(preview_viewport, value)

# ===== Debug methods =====
#func HostSpectate():
#	get_tree().call_group("Debug", "enable_debug_menu", false)
#	# Start Spectate
#	main_menu_node.spectate_button()
#	yield(get_tree(), "idle_frame")
#	# Host
#	main_menu_node.online_node.host_button()
#	# Set spectator to specific position and rotation
#	var spectator: Spectator = get_node_or_null("Spectator")
#	spectator.translation = Vector3(8.04, 6.76, 67.0)
#	spectator.camera_node.rotation = Vector3(-0.53, -1.58, 0)
#	spectator.set_move_active(false)

#func ConnectPlay():
#	get_tree().call_group("Debug", "enable_debug_menu", false)
#	# Start Play
#	main_menu_node.play_button()
#	# Adjust Character position
#	# Wait until character exists
#	while not is_instance_valid(local_player_node):
#		yield(get_tree(), "idle_frame")
#	var character_node: Character = local_player_node.character_node
#	character_node.global_transform.origin = Vector3(16, 2, 67.7)
#	yield(get_tree(), "idle_frame")
#	# Connect
#	main_menu_node.online_node.connect_button()

