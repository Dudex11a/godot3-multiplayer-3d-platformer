extends Reference
class_name GameMode

# Base type, this will most likley be the file name
var type: String = "default type"

var id: String = ""
var name: String = "default name"
var start_place: String = "default place"

remote func setup():
	var main_node: Node = O3DP.get_main()
	# Move characters to spawn
	main_node.move_characters_to_checkpoint(main_node.world_node.get_active_place().spawn_node)
	# Add GameMode HUD to character
	var game_mode_hud = make_hud()
	# Setup player nodes for game mode
	for local_player in main_node.get_local_players():
		player_node_setup(local_player)

func player_node_setup(player_node: PlayerNode):
	var hud_node: Node = player_node.hud_node.game_mode_container
	# Remove previous game mode HUD
	for child in hud_node.get_children():
		child.queue_free()
	# Add hud
	# Add GameMode HUD to character
	var game_mode_hud = make_hud()
	if is_instance_valid(game_mode_hud):
		hud_node.add_child(game_mode_hud)
		if game_mode_hud.has_method("setup_w_player_node"):
			game_mode_hud.call("setup_w_player_node", player_node)
	# Reset status is character
	player_node.character_node.reset_status()
	# Initalize Game Mode save in player
	var game_mode_save = player_node.get_game_mode_save()
	if is_instance_valid(game_mode_save):
		game_mode_save.init_player_node(player_node)

remote func put_away():
	pass

func get_game_mode_id() -> String:
	var game_mode_id: String = type
	if id != "":
		game_mode_id += O3DP.id_separator + id
	return game_mode_id

func new_game_mode_save(save_dic: Dictionary = {}) -> GameModeSave:
	var game_mode_save: GameModeSave = O3DP.make_game_mode_save_from_id(get_game_mode_id(), save_dic)
	return game_mode_save

func get_game_mode_directory_path() -> String:
	var script_path: String = get_script().get_path()
	return script_path.trim_suffix(script_path.get_file())

func make_hud() -> Node:
	var game_mode_hud_path: String = get_game_mode_directory_path() + "HUD.tscn"
	var dir: = Directory.new()
	# If file exists make hud
	if dir.file_exists(game_mode_hud_path):
		return load(game_mode_hud_path).instance()
	return null

func to_dictionary() -> Dictionary:
	return {
		"type" : type,
		"name" : name,
		"id" : id
	}

func from_dictionary(dic: Dictionary):
	G.overwrite_object(self, dic)
