extends Control
class_name DPopup

onready var anim_player: = $AnimationPlayer

var focus_cursor: FocusCursor = null
var focus_node_to_return_to: Node = null

signal close

func open(focus: FocusCursor):
	focus_cursor = focus
	focus_node_to_return_to = focus_cursor.current_node
	focus_cursor.set_current_node(self)
	anim_player.play("Open")

func close():
	emit_signal("close")
	if is_instance_valid(focus_node_to_return_to) and is_instance_valid(focus_cursor):
		focus_cursor.set_current_node(focus_node_to_return_to)
	anim_player.play("Close")
	yield(anim_player, "animation_finished")
	queue_free()
