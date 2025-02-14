extends Control
func get_class() -> String: return "TextPopup"

onready var text_node: = $Text
onready var anim_player: = $AnimationPlayer

var rect: Rect2
var direction: int = -1
var text: String = "Default Text" setget set_text
var padding: float = 2.0

export var open_value: float = 0.0 setget set_open_value
export var close_value: float = 0.0 setget set_close_value

func _on_Text_resized():
	rect_size = text_node.rect_size

func set_params(params: Dictionary = {}):
	var params_to_carry_over: Array = [
		"rect",
		"direction",
		"text",
		"padding"
	]
	for param in params_to_carry_over:
		if param in params:
			self[param] = params[param]

func open():
	anim_player.play("Open")
	# Position
	rect_global_position = rect.position
	match direction:
		G.DIR_UP:
			# Move up
			rect_global_position.y -= text_node.rect_size.y
			# Center horizontally
			rect_global_position.x += rect.size.x / 2
			rect_global_position.x -= text_node.rect_size.x / 2
			# Padding
			rect_global_position.y -= padding
			# Change pivot for scale animation
			# Middle Bottom
			rect_pivot_offset = Vector2(0.5, 1.0) * text_node.rect_size
		G.DIR_RIGHT:
			# Move to right
			rect_global_position.x += rect.size.x
			# Move to center vertically
			rect_global_position.y += rect.size.y / 2
			rect_global_position.y -= text_node.rect_size.y / 2
			# Padding
			rect_global_position.x += padding
			# Change pivot for scale animation
			# Left Middle
			rect_pivot_offset = Vector2(0.0, 0.5) * text_node.rect_size
		G.DIR_DOWN:
			# Move to bottom
			rect_global_position.y += rect.size.y
			# Center horizontally
			rect_global_position.x += rect.size.x / 2
			rect_global_position.x -= text_node.rect_size.x / 2
			# Padding
			rect_global_position.y += padding
			# Change pivot for scale animation
			# Middle Top
			rect_pivot_offset = Vector2(0.5, 0.0) * text_node.rect_size
		G.DIR_LEFT:
			# Move to left
			rect_global_position.x -= text_node.rect_size.x
			# Move to center vertically
			rect_global_position.y += rect.size.y / 2
			rect_global_position.y -= text_node.rect_size.y / 2
			# Padding
			rect_global_position.x -= padding
			# Change pivot for scale animation
			# Right Middle
			rect_pivot_offset = Vector2(1.0, 0.5) * text_node.rect_size

func set_open_value(value: float):
	open_value = value
	# Scale
	rect_scale = Vector2(value, value)

func close():
	anim_player.stop()
	anim_player.play("Close")
	# Wait for anim to finish
	yield(anim_player, "animation_finished")
	queue_free()

func set_close_value(value: float):
	close_value = value
	# Scale out
	var reverse_value: float = abs(value - 1)
	rect_scale = Vector2(reverse_value, reverse_value)

func set_text(value: String):
	text = value
	text_node.text = text
	# Shrink text_node size to size of text
	text_node.rect_size = Vector2.ZERO
