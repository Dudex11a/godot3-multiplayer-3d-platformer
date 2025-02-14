extends Node
#
#onready var player_node: PlayerNode = get_parent().get_parent().get_parent()
#onready var character_node: Character = get_parent()
#
## For watching character translation and rotation to update when needed
#var old_translation: = Vector3.ZERO
#var old_move_input: = Vector2.ZERO
#var old_forward_direction: float = 0.0
#
#func NetworkUpdate():
#	# Make sure the character is local so it's not called from other clients or server
#	if player_node.is_local:
#		# Movement
#		# set_movement if the character's translation is different than last
#		if old_translation != character_node.translation:
#			rpc("set_movement", character_node.get_movement_state())
#			old_translation = character_node.translation
#		if old_move_input != character_node.move_input:
#			rpc("set_move_input", character_node.move_input)
#			old_move_input = character_node.move_input
#		if old_forward_direction != character_node.forward_direction:
#			rpc("set_forward_direction", character_node.forward_direction)
#			old_forward_direction = character_node.forward_direction
#
#remote func set_movement(state: Dictionary):
#	character_node.translation = state.translation
#	character_node.velocity = state.velocity
#
#remote func set_move_input(value: Vector2):
#	character_node.move_input = value
#
#remote func set_forward_direction(value: float):
#	character_node.forward_direction = value
