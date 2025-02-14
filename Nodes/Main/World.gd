extends Spatial
class_name DWorld

onready var places_node: = $Places
onready var lobbies_node: = $Lobbies

const places_directory: String = "res://Nodes/World/Place/Places/"

var test_state: Dictionary = {}

var active_location: int = LOCATION_LOBBIES setget set_active_location
enum {
	LOCATION_LOBBIES,
	LOCATION_PLACES
}

func _ready():
	# Init active_location
	for child in get_children():
		recursive_set_node_existance(child, false)
	set_active_location(LOCATION_LOBBIES)
#	load_place("TestPlace1")

export var box_res: PackedScene

#func _input(event: InputEvent):
#	if event.is_action_pressed("debug_1"):
#		for index in range(100):
#			var box = box_res.instance()
#			self.add_child(box)
#			box.global_transform.origin.y = index * 2
	
func get_state() -> Dictionary:
	var state: Dictionary = {}
	# Misc state
	state["active_location"] = active_location
	return state

func set_state(state: Dictionary):
	# Misc state
	G.overwrite_object(self, state)

func get_places_spawn_location() -> Vector3:
	var location: = Vector3.ZERO
	if places_node.get_child_count() > 0:
		location = places_node.get_children()[0].global_transform.origin
	return location

func get_lobby_spawn_location() -> Vector3:
	var location: = Vector3.ZERO
	if lobbies_node.get_child_count() > 0:
		location = lobbies_node.get_children()[0].get_spawn_location()
	return location
# -3252587252790582838-629262673456

remote func set_active_location(value: int):
	# Network (This is probably called when GameMode is set)
#	if G.is_node_network_master(self):
#		rpc("set_active_location", value)
	#
	var last_location: int = active_location
	active_location = value
	match last_location:
		LOCATION_LOBBIES:
			recursive_set_node_existance(lobbies_node, false)
		LOCATION_PLACES:
			recursive_set_node_existance(places_node, false)
	match active_location:
		LOCATION_LOBBIES:
			recursive_set_node_existance(lobbies_node, true)
		LOCATION_PLACES:
			recursive_set_node_existance(places_node, true)
	
#	update_discord_activity()

func get_active_place() -> Place:
	match active_location:
		LOCATION_LOBBIES:
			if lobbies_node.get_child_count() > 0:
				return lobbies_node.get_children()[0]
		LOCATION_PLACES:
			if places_node.get_child_count() > 0:
				return places_node.get_children()[0]
	return null

func get_active_place_id() -> String:
	var place: Place = get_active_place()
	if is_instance_valid(place):
		return place.get_id()
	return ""

func get_spawn_checkpoint() -> Checkpoint:
	var place: Place = get_active_place()
	if is_instance_valid(place):
		var spawn_checkpoint = place.spawn_node
		if is_instance_valid(spawn_checkpoint):
			if spawn_checkpoint is Checkpoint:
				return spawn_checkpoint
	return null

func get_spawn_location() -> Vector3:
	var checkpoint: Checkpoint = get_spawn_checkpoint()
	if is_instance_valid(checkpoint):
		return checkpoint.get_respawn_pos()
	return Vector3.ZERO

func recursive_set_node_existance(node: Node, value: bool, first: bool = true):
	# set self
	set_node_existance(node, value, first)
	# set children
	for child in node.get_children():
		recursive_set_node_existance(child, value, false)

func set_node_existance(node: Node, value: bool, first: bool = true):
	if first:
		if "visible" in node:
			node.visible = value
	if node is Light:
		node.visible = value
	if node is CollisionShape:
		node.disabled = not value
	if node is LevelEnvironment:
		node.enabled = value
	if node is CSGShape:
		node.use_collision = value
	# General
	node.set_process(value)
	node.set_process_internal(value)
	node.set_physics_process(value)
	node.set_physics_process_internal(value)
	node.set_process_input(value)

func load_place(place_name: String):
	var place_scene_path: String = "%s%s/%s.tscn" % [
		places_directory,
		place_name,
		place_name
	]
	# Load this on another thread later?
	var place = load(place_scene_path).instance()
	add_place(place)

func add_place(place: Place):
	places_node.add_child(place)
	# Disable place if it's not supposed to be exisiting yet
	recursive_set_node_existance(place, active_location == LOCATION_PLACES, false)
#	update_discord_activity()

func unload_places():
	for child in places_node.get_children():
		child.queue_free()

#func update_discord_activity():
#	# Discord Activity
#	if is_instance_valid(O3DP.discord_activity):
#		var place: Place = get_active_place()
#		if is_instance_valid(place):
##			var assets = O3DP.discord_activity.get_assets()
##			assets.set_large_text(place.name)
#			O3DP.discord_activity.set_state("Map: %s" % place.name)  
#			O3DP.update_discord_activity()
			
