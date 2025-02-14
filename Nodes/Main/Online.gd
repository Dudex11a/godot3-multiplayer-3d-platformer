extends Node
class_name Online

onready var main_node = O3DP.get_main()
# This timer will be used to tell characters and other objects to update to the
# server 60 times per a second
onready var network_update_node: = $NetworkUpdate

var peer: NetworkedMultiplayerENet
# Player info, associate ID to data
var connected_clients: Dictionary = {}
var connected_id: int = -1

var is_client: bool = false
var is_server: bool = false

var when_connected: float = 0.0
var when_received_state: float = 0.0

func _ready():
	# Main connections
	main_node.connect("local_player_created", self, "_local_player_created")
	main_node.connect("local_player_removed", self, "_local_player_removed")
	# Network connections
	get_tree().connect("network_peer_connected", self, "player_connected")
	get_tree().connect("network_peer_disconnected", self, "player_disconnected")
	get_tree().connect("connected_to_server", self, "connected_ok")
	get_tree().connect("connection_failed", self, "connected_fail")
	get_tree().connect("server_disconnected", self, "server_disconnected")

func create_rpc_dictionary(node: Node, method_name: String, args: Array = []) -> Dictionary:
	return {
		"node_path": node.get_path(),
		"method_name": method_name,
		"args": args
	}

func custom_rpc(node: Node, method_name: String, args: Array = [], reliable: bool = true):
	var rpc_dictionary: Dictionary = create_rpc_dictionary(node, method_name, args)
#	if not is_instance_valid(node):
#		print("Online - custom_rpc: Node %s is invalid!" % node)
#		return
	# Send over Network
	if is_instance_valid(get_tree().network_peer):
		if reliable:
			rpc("recieve_custom_rpc", rpc_dictionary)
		else:
			rpc_unreliable("recieve_custom_rpc", rpc_dictionary)

func custom_rpc_id(peer_id: int, node: Node, method_name: String, args: Array = [], reliable: bool = true):
	var rpc_dictionary: Dictionary = create_rpc_dictionary(node, method_name, args)
	# Send over Network
	if is_instance_valid(get_tree().network_peer):
		if reliable:
			rpc_id(peer_id, "recieve_custom_rpc", rpc_dictionary)
		else:
			rpc_unreliable_id(peer_id, "recieve_custom_rpc", rpc_dictionary)

remote func recieve_custom_rpc(rpc_dictionary: Dictionary):
	var node: Node = get_node_or_null(rpc_dictionary.node_path)
	if not is_instance_valid(node):
		print("Online - recieve_custom_rpc: Node %s is invalid!\nMethod: %s\nArgs: %s" % [
			rpc_dictionary.node_path,
			rpc_dictionary.method_name,
			rpc_dictionary.args])
		return
	# Check to make sure the method_name is on a remote method
	# IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT IMPORTANT 
	node.callv(rpc_dictionary.method_name, rpc_dictionary.args)

func get_is_online() -> bool:
	return get_is_network_online()

func get_is_network_online() -> bool:
	return is_instance_valid(get_tree().network_peer)

const o3dp_id_digit_amount: int = 6

func generate_o3dp_id(id_blacklist: Array = connected_clients.keys()) -> int:
	# Randomize base seed
	G.randomize_base_seed()
	var mod_num: int = pow(10, max(o3dp_id_digit_amount, 0))
	var id: int = randi() % mod_num
	# If not enough digits, generate new id
	if id < (mod_num / 10):
		return generate_o3dp_id(id_blacklist)
	# If id is in blacklist, generate a different id
	if String(id) in String(id_blacklist):
		return generate_o3dp_id(id_blacklist)
	# Return final id
	return id

func remove_clients():
	for client_id in connected_clients.keys():
		remove_client(int(client_id))

# Send the player state to the server
remote func send_client_state(server_id: int):
	when_connected = main_node.elapsed_time
#	rpc_id(server_id, "recieve_client_state", main_node.get_state().to_dictionary())
	custom_rpc_id(server_id, self, "recieve_client_state", [main_node.get_state().to_dictionary()])

func is_node_network_master(node: Node, also_online: bool = true) -> bool:
	if get_tree().has_network_peer():
		return node.is_network_master()
	return not also_online

func get_node_network_master(node: Node) -> int:
	if get_tree().has_network_peer():
		return node.get_network_master()
	return 1

func set_node_network_master(node: Node, master_id: int):
	if get_tree().has_network_peer():
		node.set_network_master(master_id, true)

# The sender is now connected to the server and this function now has the 
# client's state.
# Process the client's state.
remote func recieve_client_state(state_dictionary: Dictionary):
	var state = GameState.new()
	state.from_dictionary(state_dictionary)
	var sender_id = get_tree().get_rpc_sender_id()
	var server_id = peer.get_unique_id()
	# Sync new client with current server state
#	rpc_id(sender_id, "sync_with_server_state", server_id, main_node.get_state().to_dictionary())
	custom_rpc_id(sender_id, self, "sync_with_server_state", [server_id, main_node.get_state().to_dictionary()])
	# Add new client self to everyone else's games
	add_client(int(sender_id), state.local_client.to_dictionary())
	custom_rpc(self, "add_client", [int(sender_id), state.local_client.to_dictionary()])

# This is called on clients to update them to the server's state
remote func sync_with_server_state(server_id: int, state_dictionary: Dictionary):
	var state = GameState.new()
	state.from_dictionary(state_dictionary)
	# Sync clients
	connected_clients = state.get_all_clients(server_id)
	for client_id in connected_clients.keys():
		var client: Client = connected_clients[String(client_id)]
		for player_id in client.players.keys():
			var player: Player = client.players[String(player_id)]
			add_player(int(client_id), int(player_id), player.to_dictionary())
	# Sync Main state
	main_node.set_state(state)
#	rpc("update_all_characters_to_client", peer.get_unique_id())
	custom_rpc(self, "update_all_characters_to_client", [peer.get_unique_id()])
	
	when_received_state = main_node.elapsed_time

func host_success():
	# Rename characters with network id
	main_node.update_network_id_in_local_players()
	#
	var tree: SceneTree = get_tree()
	tree.network_peer = peer
	tree.call_group("Online", "NewPeer", peer.get_unique_id())
	is_server = true
	network_update_node.start()

func stop_hosting_success():
	is_server = false
#	rpc("client_disconnected", "Server stopped hosting.")
	custom_rpc(self, "client_disconnected", ["Server stopped hosting."])
	yield(get_tree().create_timer(O3DP.online_wait_time), "timeout")
	peer.close_connection(O3DP.online_wait_time * 1000000)
	# Wait for connections to close
	yield(get_tree().create_timer(O3DP.online_wait_time), "timeout")
	peer = null
	get_tree().network_peer = null
	network_update_node.stop()
	# Rename characters with network id
	main_node.update_network_id_in_local_players()
	#

# What to do when disconnected from a server (not one this client is hosting)
func disconnected_from_server():
	# Remove connected clients, it's important to do this first
	for client_id in connected_clients.keys():
		remove_client(int(client_id))
	# Rename characters with network id
	main_node.update_network_id_in_local_players()

# Regular Online functions

remote func client_disconnected(reason: String):
	Disconnect()
	G.debug_print("You have been disconnected for: " + reason)

remote func client_disconnecting(client_id: int):
	# Remove client
	remove_client(int(client_id))

remotesync func player_connecting(id: int):
	pass

remotesync func add_client(client_id: int, client_dictionary: Dictionary):
	# Don't add client if it's self
	if client_id != peer.get_unique_id():
		var client = Client.new()
		client.from_dictionary(client_dictionary)
		connected_clients[String(client_id)] = client
		# Spawn characters in client
		for player_id in client.players.keys():
			var player_dictionary: Dictionary = client.players[String(player_id)].to_dictionary()
			add_player(int(client_id), int(player_id), player_dictionary)
		G.debug_print("Client connected.")

remotesync func remove_client(client_id: int):
	# Remove characters in client
	if String(client_id) in connected_clients:
		var client: Client = connected_clients[String(client_id)]
		for player_id in client.players:
			remove_player(int(client_id), int(player_id))
		connected_clients.erase(String(client_id))

remotesync func add_player(client_id: int, player_id: int, player_dictionary: Dictionary):
	# If the recieving client already has sender's client in their connected_clients
	if String(client_id) in connected_clients:
		# Create and add player object
		var player: = Player.new()
		player.from_dictionary(player_dictionary)
		# Add player if not already added
		var client: Client = connected_clients[String(client_id)]
		if not String(player_id) in client.players:
			client.players[String(player_id)] = player
		# Create character
		# Viewport Character node associated with player
		var player_node: PlayerNode = main_node.get_player_node(int(client_id), int(player_id))
		if not is_instance_valid(player_node):
			# Set Viewport Character
			player_node = O3DP.R.get_instance("player_node")
			main_node.players_node.add_child(player_node)
			player_node.is_local = false
			player_node.name = O3DP.make_character_name(int(client_id), int(player_id))
			# Network master
			player_node.set_network_master(client_id)
			# Set Character
			var character_node: Character = player_node.character_node
#			var character_info: CharacterInfo = CharacterInfo.new()
#			character_info.from_dictionary(player.character_info.to_dictionary())
			character_node.set_character_info(player.player_save.character_info)

remotesync func remove_player(client_id: int, player_id: int):
	# Don't remove player if it's self
	if client_id == peer.get_unique_id():
		return
	# If the recieving client already has sender's client in their connected_clients
	# Data from connected clients
	var client: Client = connected_clients[String(client_id)]
	if String(player_id) in client.players:
		client.players.erase(String(player_id))
	# Node
	var player_node: PlayerNode = main_node.get_player_node(int(client_id), int(player_id))
	if is_instance_valid(player_node):
		player_node.queue_free()
	else:
		print("remove_player: There is no character to remove in...\nclient_id: "
		+ String(client_id) + "\nplayer_id: " + String(player_id))

# A time might come when I need these
#remote func add_character(client_id: int, player_id: int, character_info: Dictionary):
#	pass
#
#remote func remove_character(client_id: int, player_id: int):
#	pass

# Call a function on all clients to update all characters variables on other clients
remote func update_all_characters_to_client(client_id: int):
	pass
#	G.debug_print("update_all_characters_to_client")
#	CharacterReplication.send_update_character(client_id)

# ===== "Game" group

func Host(params: Dictionary = {}):
	peer = NetworkedMultiplayerENet.new()
	var base_params: Dictionary = {
		"Port" : 42069,
		"Max Players" : 10
	}
	base_params = G.overwrite_dic(base_params, params)
	# Try to host the server
	var error: int = peer.create_server(base_params["Port"], base_params["Max Players"])
	if error == OK:
		get_tree().network_peer = peer
		host_success()
	else:
		G.debug_print("Host: error creating server, there's probably one already hosted on the ip: ", error)

func StopHosting():
	# If there is a session active
	if is_server and is_instance_valid(get_tree().network_peer):
		stop_hosting_success()
	else:
		G.debug_print("StopHosting: There is no server to stop.")

func Connect(params: Dictionary = {}):
	peer = NetworkedMultiplayerENet.new()
	var base_params: Dictionary = {
		"IP Address" : "127.0.0.1",
		"Port" : 42069
	}
	base_params = G.overwrite_dic(base_params, params)
	var error: int = peer.create_client(base_params["IP Address"], base_params["Port"])
	if error == OK:
		# Succesful connect
		var tree: SceneTree = get_tree()
		tree.network_peer = peer
		is_client = true
		tree.call_group("Online", "NewPeer", peer.get_unique_id())
		connected_id = peer.get_unique_id()
		network_update_node.start()
	else:
		G.debug_print("Connect: error connect to server: ", error)

func Disconnect():
	# If there is a session active
	if is_client and is_instance_valid(get_tree().network_peer):
		remove_clients()
		network_update_node.stop()
#		rpc("client_disconnecting", connected_id)
		custom_rpc(self, "client_disconnecting", [connected_id])
		yield(get_tree().create_timer(O3DP.online_wait_time), "timeout")
		is_client = false
		peer = null
		get_tree().network_peer = null
		disconnected_from_server()
	else:
		G.debug_print("Disconnect: There is no connection to stop.")

# ===== Signals

# Network signal functions

func player_connected(client_id: int):
	# Make it so only the server sends out the send_client_state so I don't
	# get every client sending send_client_state to everyone else too.
	if is_server:
		# Ask for the player state from whoever just connected and work from there
#		rpc_id(client_id, "send_client_state", peer.get_unique_id())
		custom_rpc_id(client_id, self, "send_client_state", [peer.get_unique_id()])
		# Relay player connecting to self and connected clients
		player_connecting(int(client_id))
		custom_rpc(self, "player_connecting", [int(client_id)])

func player_disconnected(client_id: int):
	if is_server:
		# Remove client for self and connect clients
		remove_client(int(client_id))
		custom_rpc(self, "remove_client", [int(client_id)])

# Client connect to server ok
func connected_ok():
	# Rename characters with network id
	main_node.update_network_id_in_local_players()
	#

func connected_fail():
	G.debug_print("Connected Fail")

func server_disconnected():
	Disconnect()

# Main signal functions

func _local_player_created(local_player_id: int, player: Player):
	if is_instance_valid(peer):
		# Add player to self and connected clients
		add_player(peer.get_unique_id(), local_player_id, player.to_dictionary())
		custom_rpc(self, "add_player", [peer.get_unique_id(), local_player_id, player.to_dictionary()])

func _local_player_removed(local_player_id: int):
	if is_instance_valid(peer):
		# Remove player from self and connected clients
		remove_player(peer.get_unique_id(), local_player_id)
		custom_rpc(self, "remove_player", [peer.get_unique_id(), local_player_id])

func _on_NetworkUpdate_timeout():
	get_tree().call_group("Online", "NetworkUpdate")
