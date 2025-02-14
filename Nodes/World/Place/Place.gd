extends Spatial
class_name Place

onready var spawn_node: Actor = $Spawn.get_children()[0]

func _ready():
	for child in get_children():
		connect_out_of_bounds(child)

func get_id() -> String:
	var file: = String(get_path()).get_file()
	return file.trim_suffix(file.get_extension())

func connect_out_of_bounds(node: Node):
	if node is OutOfBounds:
		node.connect("body_entered", self, "body_oob")

func respawn_character(character: Character):
	var player_node: PlayerNode = character.player_node
	if is_instance_valid(player_node):
		player_node.respawn_character()

func body_oob(body: Node):
	if body is Character:
		respawn_character(body)
	elif body is Actor:
		body.spawner_respawn()
