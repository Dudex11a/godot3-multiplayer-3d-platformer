extends GameMode
class_name CampaignGameMode

var main_collectible_type: String = "TestMainCollectible"

var place_node_path: String = ""

const places_path: String = "res://Nodes/World/Place/Places/"

func _init():
	type = "Campaign"
	name = "Campaign"
	# Default start place
	start_place = "TestPlace1"

func setup():
	var world_node: DWorld = O3DP.get_main().world_node
	world_node.set_active_location(DWorld.LOCATION_PLACES)
	# Add place
	var place_node = get_world_res().instance()
	world_node.add_place(place_node)
	# Path
	place_node_path = place_node.get_path()
	.setup()

func put_away():
	# Remove place that was loaded
	get_place_node().queue_free()

func to_dictionary() -> Dictionary:
	# Base
	var dic = .to_dictionary()
	dic["start_place"] = start_place
	dic["place_node_path"] = place_node_path
	return dic

func get_place_node():
	return O3DP.get_main().get_node(place_node_path)

func get_world_res() -> Resource:
	return load(get_world_path())

func get_world_path() -> String:
	return "%s%s/%s.tscn" % [places_path, start_place, start_place]
