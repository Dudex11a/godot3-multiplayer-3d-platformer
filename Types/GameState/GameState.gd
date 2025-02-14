extends Reference
class_name GameState

var local_client: Client
var connected_clients: Dictionary

var world_state: Dictionary
var player_state: Dictionary
var game_mode_state: Dictionary

func get_all_clients(local_client_id: int) -> Dictionary:
	var val: Dictionary = connected_clients.duplicate()
	val[String(local_client_id)] = local_client
	return val

func to_dictionary() -> Dictionary:
	var val: Dictionary = {}
	val.local_client = local_client.to_dictionary()
	val.connected_clients = {}
	val.world_state = world_state
	val.player_state = player_state
	val.game_mode_state = game_mode_state
	for key in connected_clients.keys():
		val.connected_clients[key] = connected_clients[key].to_dictionary()
	return val

func from_dictionary(dictionary: Dictionary):
	if "game_mode_state" in dictionary:
		game_mode_state = dictionary.game_mode_state
	if "world_state" in dictionary:
		world_state = dictionary.world_state
	if "player_state" in dictionary:
		player_state = dictionary.player_state
	if "local_client" in dictionary:
		local_client = Client.new()
		local_client.from_dictionary(dictionary.local_client)
	if "connected_clients" in dictionary:
		for key in dictionary.connected_clients.keys():
			var client = Client.new()
			client.from_dictionary(dictionary.connected_clients[key])
			connected_clients[key] = client
