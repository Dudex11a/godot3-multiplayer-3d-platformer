extends Actor
class_name Collectible

signal actor_entered
signal character_entered
signal player_entered

func _on_CollectRange_body_entered(body: KinematicBody):
	if body is Actor:
		emit_signal("actor_entered", body)

func actor_entered(actor: Actor):
	if actor is Character:
		emit_signal("character_entered", actor)

func character_entered(character: Character):
	var player_node: PlayerNode = character.player_node
	if is_instance_valid(player_node):
		emit_signal("player_entered", player_node)

func player_entered(player_node: PlayerNode):
	pass
