extends Node

const id_separator: String = "_"
const online_wait_time: float = 0.1
const animation_dead_zone: float = 0.1
const backup_file_extention: String = ".bak"
const game_version: String = "0.0.1"
const game_modes_path: String = "res://Types/GameMode/"
const actor_actions_path: String = "res://Nodes/Pawn/Actor/Actions/"
const actions_path: String = "res://Nodes/Pawn/Actor/Actions/"

var R: ResourceContainer
var O: Online
var A: Audio
#var discord_activity: Discord.Activity = null

var used_cull_masks: Array = []

func _ready():
	var script_path: String = get_script().get_path()
	script_path = script_path.replace(script_path.get_file(), "")
	# Load resource container
	G.load_resource_container(self, "ResourceContainer/ResourceContainer.tscn")
	# Load Audio object
	G.load_resource_container(self, "Audio/Audio.tscn", "A")
	# Load Online object
	G.load_resource_container(self, "Online/Online.tscn", "O")

#func _ready():
#	# Create Discord Activity if not consoles
#	discord_activity = Discord.Activity.new()

#func update_discord_activity():
#	if is_instance_valid(O3DP.discord_activity):
#		var result = yield(Discord.activity_manager.update_activity(O3DP.discord_activity), "result").result
#		if result != Discord.Result.Ok:
#			push_error(str(result))

func get_main() -> Node:
	return get_node_or_null("/root/Main")

func make_local_player_name(player_id: int = 0):
	var network_id: String = "1"
	if O.get_is_online():
		network_id = String(get_tree().get_network_unique_id())
	# Associate network id of 0 (offline) with 1 (hosting online)
	if network_id == "0":
		network_id = "1"
	return network_id + id_separator + String(player_id)

func make_character_name(client_id: int, player_id: int):
	return String(client_id) + id_separator + String(player_id)

func get_unused_cull_mask() -> int:
	var start: int = 1
	var end: int = 19
	var cull_mask: int = start
	while cull_mask <= end:
		if not used_cull_masks.has(cull_mask):
			return cull_mask
		cull_mask += 1
	return -1

func make_game_mode_from_name(game_mode_name: String) -> GameMode:
	var game_mode: GameMode = null
	match game_mode_name:
		"Lobby":
			game_mode = LobbyGameMode.new()
		"Campaign":
			game_mode = CampaignGameMode.new()
	return game_mode

func make_game_mode_save_from_id(id: String, save_dic: Dictionary = {}) -> GameModeSave:
	var game_mode_save: GameModeSave = null
	
	# Path
	var path: String = game_modes_path
	var gm_type_and_id: Array = id.split(id_separator, false)
	# Add type
	path += gm_type_and_id[0] + "/"
	if gm_type_and_id.size() > 1:
		# Has id so add id to path
		path += gm_type_and_id[1] + "/"
	# Add save to path
	path += "Save.gd"
	# If Save.gd exists create it
	var dir: = Directory.new()
	if dir.file_exists(path):
		game_mode_save = load(path).new()
	else:
		# Load default Save.gd for GameMode
		game_mode_save = load(game_modes_path + "Save.gd").new()
		
	# Load save dictionary into new save if one is provided
	if save_dic.size() > 0:
		game_mode_save.from_dictionary(save_dic)
		
	return game_mode_save

func make_game_mode_from_dictionary(dic: Dictionary) -> GameMode:
	var game_mode: GameMode = null
	# Make path for GameMode
	var type: String = dic.type
	var id: String = dic.id
	var path: String = game_modes_path
	path += type + "/"
	# If id is defined open specific version of type (i.e. SpecialAdventure
	# instead of the default Campaign type).
	if id == "":
		path += type + ".gd"
	else:
		path += "%s/%s.gd" % [id, id]
	# Load type and load from dictionary
	game_mode = load(path).new()
	game_mode.from_dictionary(dic)
	return game_mode

func get_states(node: Node, state: Dictionary = {}) -> Dictionary:
	# What to do with node
	if node.has_method("get_state"):
		var node_state = node.get_state()
		if node_state is Dictionary:
			G.overwrite_dic(state, node_state, false)
	# What to do with children
	for child in node.get_children():
		state[child.name] = {}
		get_states(child, state[child.name])
	return state

func set_states(node: Node, state: Dictionary = {}):
	# What to do with node
	if node.has_method("set_state"):
		node.set_state(state)
	# What to do with children
	for child in node.get_children():
		if child.name in state:
			set_states(child, state[child.name])

func get_current_game_mode_id() -> String:
	return get_main().current_game_mode.get_game_mode_id()

func get_current_place_id() -> String:
	return get_main().world_node.get_active_place_id()

func create_base_place_save() -> Dictionary:
	return {
		"type" : "place_save"
	}

func get_action_res(action_id: String) -> Resource:
	var path: String = "%s%s/%s.tscn" % [O3DP.actor_actions_path, action_id, action_id]
	return load(path)

# Create single action from status
func create_action_from_status(action_id: String, status: Dictionary, parent: Node) -> Action:
	# Load action in files
	var action_res = O3DP.get_action_res(action_id)
	if is_instance_valid(action_res):
		var action = action_res.instance()
		# Add action
		parent.add_child(action)
		# Set action status
		action.set_status(status)
		return action
	else:
		G.debug_print("%s is not a valid action!")
		return null

func get_note_from_event(event: InputEvent) -> String:
	if Input.is_action_pressed("instrument_modifier_1"):
		if event.is_action("instrument_note_1"):
			return "E"
		if event.is_action("instrument_note_2"):
			return "F"
		if event.is_action("instrument_note_3"):
			return "F#"
		if event.is_action("instrument_note_4"):
			return "G"
	if Input.is_action_pressed("instrument_modifier_2"):
		if event.is_action("instrument_note_1"):
			return "G#"
		if event.is_action("instrument_note_2"):
			return "A"
		if event.is_action("instrument_note_3"):
			return "A#"
		if event.is_action("instrument_note_4"):
			return "B"
	if event.is_action("instrument_note_1"):
		return "C"
	if event.is_action("instrument_note_2"):
		return "C#"
	if event.is_action("instrument_note_3"):
		return "D"
	if event.is_action("instrument_note_4"):
		return "D#"
	# Do something with pitch to get the note
#	if event is InputEventMIDI:
#		event.pitch
	return ""

func get_action_name_from_note(note: String) -> String:
	match note:
		"C":
			return "instrument_note_1"
		"C#":
			return "instrument_note_2"
		"D":
			return "instrument_note_3"
		"D#":
			return "instrument_note_4"
		"E":
			return "instrument_note_1"
		"F":
			return "instrument_note_2"
		"F#":
			return "instrument_note_3"
		"G":
			return "instrument_note_4"
		"G#":
			return "instrument_note_1"
		"A":
			return "instrument_note_2"
		"A#":
			return "instrument_note_3"
		"B":
			return "instrument_note_4"
		
	return ""

# ===== Settings

# Shadows

const shadows: Dictionary = {
	"None" : {
		"shadow_atlas_size" : 0,
		"shadow_atlas_quad_0" : Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_DISABLED,
		"shadow_atlas_quad_1" : Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_DISABLED,
		"shadow_atlas_quad_2" : Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_DISABLED,
		"shadow_atlas_quad_3" : Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_DISABLED
	},
	"Low" : {
		"shadow_atlas_size" : 2,
		"shadow_atlas_quad_0" : Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_1,
		"shadow_atlas_quad_1" : Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_1,
		"shadow_atlas_quad_2" : Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_4,
		"shadow_atlas_quad_3" : Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_16
	},
	"High" : {
		"shadow_atlas_size" : 4,
		"shadow_atlas_quad_0" : Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_4,
		"shadow_atlas_quad_1" : Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_4,
		"shadow_atlas_quad_2" : Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_16,
		"shadow_atlas_quad_3" : Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_64
	},
}

var current_shadows: String = "High" setget set_current_shadows

func get_shadow_settings(value: String = current_shadows) -> Dictionary:
	return shadows[value]

func set_current_shadows(value: String):
	current_shadows = value
	# Send call to all objects to set shadows
	get_tree().call_group("Settings", "SetShadows", get_shadow_settings())

func set_shadows_in_viewport(viewport: Viewport, shadows_data: Dictionary):
	G.overwrite_object(viewport, shadows_data)

#
