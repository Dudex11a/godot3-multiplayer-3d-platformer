extends Actor
class_name Checkpoint

onready var anim_player: = $AnimationPlayer
var light_material: SpatialMaterial

# Set player_node checkpoint
# Add to internal array of local player_nodes

#export var light_anim: float = 0.0 setget set_light_anim

var local_players: Array = []
var light: bool = false setget set_light

func _ready():
	# Make material unique to others
	var mesh: = $Model/LampCheckpoint/Cube
	var material_copy: Material = mesh.get_surface_material(1)
	material_copy = material_copy.duplicate()
	mesh.set_surface_material(1, material_copy)
	light_material = material_copy

func get_respawn_pos() -> Vector3:
	return global_transform.origin

func set_light(value: bool = false):
	var previous_value: bool = light
	light = value
	anim_player.stop()
	if light:
		# Play anim if not already on
		if not previous_value:
			anim_player.play("TurnLightOn")
			while light:
				on_anim()
				yield(get_tree(), "idle_frame")
	else:
		anim_player.play("TurnLightOff")

func on_anim():
	var delta: float = get_process_delta_time()
	var current_hue: float = light_material.emission.h
	light_material.emission.h = fmod(current_hue + (delta / 8), 1)

func update_light():
	self.light = local_players.size() > 0

func update_player_save(player_node: PlayerNode):
	var player_save: PlayerSave = player_node.get_player_save()
	var place: Place = G.get_parent_of_type(self, Place)
	if is_instance_valid(player_save):
		# Edit and save if adding new data
		var should_save: bool = not player_save.game_mode_place_array_has_value("checkpoints", name)
		if should_save:
			# Add checkpoint
			player_save.append_value_to_game_mode_place_array("checkpoints", name)
#			# Save
#			player_save.save_to_file()
	player_node.save()

# ===== Signals

func _on_CharacterDetection_body_entered(body):
	# If body is local player's character
	if body is Character:
		var player_node: PlayerNode = body.player_node
		if player_node.is_local:
			# Remove player from local_players if they have been to a previous checkpoint
			var previous_checkpoint = player_node.checkpoint
			if is_instance_valid(previous_checkpoint) and previous_checkpoint != self:
				previous_checkpoint.local_players.erase(player_node)
				previous_checkpoint.update_light()
			# Manage Checkpoint functionality
			if not player_node in local_players:
				local_players.append(player_node)
			# Set player_node checkpoint
			player_node.checkpoint = self
			update_light()
			# Update player_node save data
			update_player_save(player_node)
			
# ===== Game Group

# When removing local player, remove player from local_players
func RemoveLocalPlayer(player_id: int = 0):
	for player_node in local_players:
		if player_node.get_player_id() == player_id:
			local_players.erase(player_node)
			update_light()
