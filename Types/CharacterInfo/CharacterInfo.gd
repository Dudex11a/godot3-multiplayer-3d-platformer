extends Node
class_name CharacterInfo

var af_info: AnimalFriendInfo

func to_dictionary() -> Dictionary:
	var dictionary: Dictionary = {}
	if is_instance_valid(af_info):
		dictionary.af_info = af_info.to_dictionary()
	return dictionary

func from_dictionary(dictionary: Dictionary):
#	G.overwrite_object(self, dictionary)
	if "af_info" in dictionary:
		var new_af_info: = AnimalFriendInfo.new()
		new_af_info.from_dictionary(dictionary.af_info)
		af_info = new_af_info
