extends GameMode
class_name LobbyGameMode

const lobbies_path: String = "res://Nodes/World/Lobby/Lobbies/"

func _init():
	type = "Lobby"
	name = "Lobby"
	# Default start place
	start_place = "Lobby1"

func setup():
	var world_node: DWorld = O3DP.get_main().world_node
	world_node.set_active_location(DWorld.LOCATION_LOBBIES)
	.setup()
	

remote func put_away():
	pass

func get_world_res() -> Resource:
	return load(get_world_path())

func get_world_path() -> String:
	return "%s%s.tscn" % [lobbies_path, start_place]
