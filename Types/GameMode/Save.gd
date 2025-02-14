extends Reference
class_name GameModeSave

var current_place: String = "default place"

var place_saves: Dictionary = {}

var action_status: Dictionary = {}

func init_player_node(player_node):
	# Set actions
	player_node.character_node.set_actions_from_status(action_status)

func to_dictionary() -> Dictionary:
	var dic: Dictionary = {
		"place_saves" : place_saves,
		"action_status" : action_status
	}
	return dic

func from_dictionary(dic: Dictionary):
	G.overwrite_object(self, dic)
