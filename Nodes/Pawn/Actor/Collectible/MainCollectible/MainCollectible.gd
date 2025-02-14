extends Collectible
class_name MainCollectible
func get_class() -> String: return "MainCollectible"

onready var anim_player: = $AnimationPlayer


export var visibility: float = 0.0 setget set_visibility

# The type of collectible (ex: Star, Hourglass, Shine).
export var collectible_type: String = "MainCollectible"
# The id for this collectible, this is what it's refered to in the files.
export var collectible_id: String = "MainCollectible1"
# The name of the collectible, this is what will display in the game when
# refering to the collectible.
export var collectible_name: String = "Main Collectible 1"
export var collectible_message: String = "You got a %s!"

var local_players_collected: Array = []

var collected_visual_active: bool = false

func _ready():
	# Update local_players_collected and then update the visuals
	var main: Main = O3DP.get_main()
	for player in main.local_client.players.values():
		add_local_player(player)

func update_visual():
	# Remove any local_players that don't exist anymore
	for player in local_players_collected:
		if not is_instance_valid(player):
			local_players_collected.erase(player)
	
	update_collected_visual()

func update_collected_visual(collected: bool = is_all_players_collected()):
	collected_visual_active = collected
	if collected:
		anim_player.queue("VisibilityOff")
	else:
		anim_player.queue("VisibilityOn")

func set_visibility(value: float):
	visibility = value

func player_collect(player: Player):
	if not player in local_players_collected:
		local_players_collected.append(player)

func player_save_collect(player_save: PlayerSave):
	player_save.append_value_to_game_mode_place_array(collectible_type, collectible_id)
#	player_save.save_to_file()

func player_node_collect(player_node: PlayerNode):
	enter_player_node_collect_state(player_node.get_path())
	player_node.save()

remote func enter_player_node_collect_state(player_node_path: String, instant_transition: bool = true):
	var player_node: PlayerNode = get_node(player_node_path)
	var character_node: Character = player_node.character_node
	if player_node.is_local:
		local_player_node_enter(player_node_path, instant_transition)
	# Freeze character node
	character_node.disable_physics_process = true
	# Disable character node collision
	character_node.add_intangibility_value(collectible_id, true)
	# Add state to character
	character_node.add_state(get_class(), {
		"state_start" : {
			"node_path" : get_path(),
			"method" : "enter_player_node_collect_state",
			"args" : [player_node_path]
		}})

func local_player_node_enter(player_node_path: String, instant_transition: bool = true):
	var player_node: PlayerNode = get_node(player_node_path)
	# Online
#	rpc("enter_player_node_collect_state", player_node_path, false)
	O3DP.O.custom_rpc(self, "enter_player_node_collect_state", [player_node_path, false])
	# Connect player input to check for button
	player_node.connect("controller_input_event", self, "player_node_input")
	# HUD Anim and Info
#	var main: Main = O3DP.get_main()
	var game_mode_type: String = O3DP.get_main().current_game_mode.type
	# There's no game mode id
	var args: Array = [collectible_name, collectible_message % collectible_type]
	# Popup
	player_node.hud_node.call_game_mode_method(game_mode_type, "collect_start", args)
	# Update collectible amount
	var place_collectibles: Array = player_node.get_player_save().get_game_mode_place_save_value(collectible_type)
	var collectible_amount: int = place_collectibles.size()
	player_node.hud_node.call_game_mode_method(game_mode_type, "set_collectible_amount", [collectible_amount])

remote func exit_player_node_collect_state(player_node_path: String):
	var player_node: PlayerNode = get_node(player_node_path)
	var character_node: Character = player_node.character_node
	if player_node.is_local:
		# Online
#		rpc("exit_player_node_collect_state", player_node_path)
		O3DP.O.custom_rpc(self, "exit_player_node_collect_state", [player_node_path])
		# Disconnect player input to check for button
		player_node.disconnect("controller_input_event", self, "player_node_input")
	# Unfreeze Character node
	character_node.disable_physics_process = false
	# Enable Character node collision
	character_node.remove_intangibility_value(collectible_id)
	# Remove state from character
	var class_string: String = get_class()
	character_node.remove_state(class_string)

func player_node_input(player_node: PlayerNode, event: InputEvent):
	if event.is_action_pressed("character_action-1"):
		exit_player_node_collect_state(player_node.get_path())
		# HUD Anim and Info
#		var main: Main = O3DP.get_main()
		var game_mode_type: String = O3DP.get_main().current_game_mode.type
		player_node.hud_node.call_game_mode_method(game_mode_type, "collect_end")

func passby_anim():
	anim_player.queue("Passby")

# Check if all players have collected this
func is_all_players_collected() -> bool:
	var main: Main = O3DP.get_main()
	for player in main.local_client.players.values():
		if is_instance_valid(player.player_save):
			if not player_save_has_collected(player.player_save):
				return false
		else:
			return false
	return true

func player_save_has_collected(player_save: PlayerSave) -> bool:
	return player_save.game_mode_place_array_has_value(collectible_type, collectible_id)

func add_local_player(player: Player):
	var player_save = player.player_save
	if is_instance_valid(player_save):
		if player_save_has_collected(player_save):
			local_players_collected.append(player)

# ===== Game Group

func LocalPlayerLoadedSave(player: Player):
	add_local_player(player)
	update_visual()

func LocalPlayerRemoved(player: Player):
	# Remvoe player from local_players_collected
	if player in local_players_collected:
		local_players_collected.erase(player)
	update_visual()

func SetGameModeFinished():
	# Re-update visuals when game mode is set
	update_visual()

# ===== Signals

func player_entered(player_node: PlayerNode):
	# Collect if does not have in save
	var player: Player = player_node.get_player()
	var player_save: PlayerSave = player.player_save
	if is_instance_valid(player_save) and player_node.is_local:
		if player_save.game_mode_place_array_has_value(collectible_type, collectible_id):
			passby_anim()
		else:
			player_collect(player)
			player_save_collect(player_save)
			update_visual()
			player_node_collect(player_node)
