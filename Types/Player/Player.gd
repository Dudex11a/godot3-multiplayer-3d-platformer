extends Reference
class_name Player

var player_save: = PlayerSave.new()

func to_dictionary() -> Dictionary:
	var val: Dictionary = {}
#	# character_info can be null
#	if is_instance_valid(character_info):
#		val.character_info = character_info.to_dictionary()
#	else:
#		val.character_info = null
	#
	if is_instance_valid(player_save):
		val.player_save = player_save.to_dictionary()
	else:
		val.player_save = null
	return val

func from_dictionary(dictionary: Dictionary):
#	if "character_info" in dictionary:
#		if dictionary.character_info != null:
#			character_info = CharacterInfo.new()
#			character_info.from_dictionary(dictionary.character_info)
	if "player_save" in dictionary:
		if dictionary.player_save != null:
			player_save = PlayerSave.new()
			player_save.from_dictionary(dictionary.player_save)
