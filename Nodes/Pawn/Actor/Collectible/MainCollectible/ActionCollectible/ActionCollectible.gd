extends MainCollectible

onready var ability_icon_mesh: = $Model/AbilityIcon
onready var ability_icon_mesh_mat: SpatialMaterial = ability_icon_mesh.get_surface_material(0)

# The action id is the collectible id
onready var action_id: String = collectible_id

export var default_action_index: int = 1

func _ready():
	init_ability()

func init_ability():
	# Change action icon to action_id
	var action_icon: StreamTexture = O3DP.R.actions_resources[action_id]["Icon"]
	ability_icon_mesh_mat.albedo_texture = action_icon
	ability_icon_mesh_mat.transmission_texture = action_icon

func player_node_collect(player_node: PlayerNode):
	# Give action
	player_node.character_node.add_action(action_id, {
		"action_index" : default_action_index })
	# Save player
	.player_node_collect(player_node)
