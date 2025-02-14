extends Reference
class_name Client

var name: String = "Default Name"
var players: Dictionary = {
#	0 : Player.new()
}
var o3dp_id: int = O3DP.O.generate_o3dp_id()
# Other Online related ids (Steam, Network, Discord, etc...)
var other_ids: Dictionary = {}

func to_dictionary() -> Dictionary:
	var val: Dictionary = {}
	val.players = {}
	for key in players.keys():
		val.players[key] = players[key].to_dictionary()
	val.name = name
	return val

func from_dictionary(dictionary: Dictionary):
	if "players" in dictionary:
		for key in dictionary.players.keys():
			var player = Player.new()
			player.from_dictionary(dictionary.players[key])
			players[key] = player
	if "name" in dictionary:
		name = dictionary.name
