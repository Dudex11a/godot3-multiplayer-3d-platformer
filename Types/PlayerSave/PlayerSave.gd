extends Reference
class_name PlayerSave

const player_saves_path: String = "user://Players/"
const file_extention: String = ".json"

var file_name: String = "Default Filename"

#var af_save_path: String = ""
var game_mode_saves: Dictionary = {}

var time_played: String = ""
var original_game_version: String = ""
var updates_applied: Array = []
var character_info: = CharacterInfo.new()

var general_settings: Dictionary = {}

func to_dictionary() -> Dictionary:
	if original_game_version == "":
		original_game_version = O3DP.game_version
	var dic: Dictionary = {
#		"af_save_path" : af_save_path,
#		"game_mode_saves" : game_mode_saves,
		"game_mode_saves" : {},
		"file_name" : file_name,
		"time_played" : time_played,
		"updates_applied" : updates_applied,
		"original_game_version" : original_game_version,
		"general_settings" : general_settings,
		"character_info" : character_info.to_dictionary()
	}
	# Convert game_mode_saves to dic
	for key in game_mode_saves.keys():
		var gm_save: GameModeSave = game_mode_saves[key]
		dic.game_mode_saves[key] = gm_save.to_dictionary()
	return dic

func from_dictionary(dic: Dictionary):
	# Manually deal with game_saves
	if "game_mode_saves" in dic:
		# Extract game_mode_saves from dic
		var gm_saves_dic: Dictionary = dic.game_mode_saves
		# Erase the game_mode_saves from the dic so it doesn't attempt to
		# overwrite game_mode_saves with the overwrite_object later down
		dic.erase("game_mode_saves")
		# Process saves
		for key in gm_saves_dic.keys():
			var gm_save_dic: Dictionary = gm_saves_dic[key]
			# Set save in this save (I make Save from id/key)
			game_mode_saves[key] = O3DP.make_game_mode_save_from_id(key, gm_save_dic)
	# Manually deal with character_info
	if "character_info" in dic:
		# Extract character_info from dic
		character_info.from_dictionary(dic.character_info)
		dic.erase("character_info")
	# Everything else
	G.overwrite_object(self, dic)

func save_to_file(path: String = make_path_from_name()):
	# If overwriting create backup file
	var dir: = Directory.new()
	if dir.file_exists(path):
		dir.rename(path, path + O3DP.backup_file_extention)
	#
	G.save_json_file(path, to_dictionary())

func load_from_file(path: String = make_path_from_name()):
	var dic: Dictionary = G.load_json_file(path)
	from_dictionary(dic)
	# Update filename
	file_name = path.get_file().trim_suffix(path.get_extension())

func make_path_from_name() -> String:
	return player_saves_path + G.create_filename(file_name) + file_extention

func get_new_filename() -> String:
	var new_file_name: String = ""
	
	# Find the next number that's not taken for the file_name
	var index: int = 1
	var new_file_name_path: String = ""
	var dir: = Directory.new()
	while new_file_name == "":
		new_file_name_path = "%s%s%s" % [player_saves_path, String(index), file_extention]
		if not dir.file_exists(new_file_name_path):
			new_file_name = String(index)
		index += 1
		# Fail safe for infinite loop
		if index > 1000:
			new_file_name = "1000"
	
	return new_file_name

func get_game_mode_save(id: String = O3DP.get_current_game_mode_id(), create_if_none: bool = true) -> GameModeSave:
	if id in game_mode_saves:
		return game_mode_saves[id]
	elif create_if_none:
		# Create save if there is no save
		var game_mode_save: GameModeSave = O3DP.make_game_mode_save_from_id(id)
		if is_instance_valid(game_mode_save):
			game_mode_saves[id] = game_mode_save
			return game_mode_save
	return null

func get_game_mode_place_save(
	game_mode_id: String = O3DP.get_current_game_mode_id(),
	place_id: String = O3DP.get_current_place_id(),
	create_if_none: bool = true) -> Dictionary:
	var game_mode_save: GameModeSave = get_game_mode_save(game_mode_id, create_if_none)
	if is_instance_valid(game_mode_save):
		if place_id in game_mode_save.place_saves:
			# Return place save
			return game_mode_save.place_saves[place_id]
		elif create_if_none:
			# Create and return place save
			game_mode_save.place_saves[place_id] = O3DP.create_base_place_save()
			return game_mode_save.place_saves[place_id]
	return {}

func get_game_mode_place_save_value(
	key: String,
	game_mode_id: String = O3DP.get_current_game_mode_id(),
	place_id: String = O3DP.get_current_place_id()):
		var game_mode_place_save: Dictionary = get_game_mode_place_save(game_mode_id, place_id)
		if key in game_mode_place_save:
			return game_mode_place_save[key]
		return null

func set_game_mode_place_save_value(
	key: String,
	value,
	game_mode_id: String = O3DP.get_current_game_mode_id(),
	place_id: String = O3DP.get_current_place_id()):
		var game_mode_place_save: Dictionary = get_game_mode_place_save(game_mode_id, place_id)
		game_mode_place_save[key] = value
		return null

# Append to an array in the game_mode_place save (this is mostly for checkpoints)
func append_value_to_game_mode_place_array(
	key: String,
	value,
	allow_duplicates: bool = false,
	game_mode_id: String = O3DP.get_current_game_mode_id(),
	place_id: String = O3DP.get_current_place_id()):
		var array = get_game_mode_place_save_value(key, game_mode_id, place_id)
		# Make array if doesn't exist
		if not array is Array:
			array = []
			set_game_mode_place_save_value(key, array, game_mode_id, place_id)
		# Append value if duplicates are allowed or the value is not in the array
		if allow_duplicates or not value in array:
			array.append(value)

func game_mode_place_array_has_value(
	key: String,
	value,
	allow_duplicates: bool = false,
	game_mode_id: String = O3DP.get_current_game_mode_id(),
	place_id: String = O3DP.get_current_place_id()) -> bool:
		var array = get_game_mode_place_save_value(key, game_mode_id, place_id)
		if array is Array:
			return value in array
		return false
