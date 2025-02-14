extends CanvasLayer
class_name DebugText

export var text_item_res: PackedScene

onready var text_list_node: = $TextList

func debug_print(val, length: float):
	var text: String = "No text"
	if val is Object:
		if val.has_method("to_string"):
			text = val.to_string()
	elif val == null:
		text = "null"
	else:
		text = String(val)
	
	var text_item_node: TextItem = add_text_item(text, length)
	if val is Texture:
		text_item_node.set_texture(val)
	print(text)

func debug_value(id: String, value):
	var text_item_node: TextItem = text_list_node.get_node_or_null(id)
	if text_item_node == null:
		# Create text item
		text_item_node = add_text_item(create_text_item_text(id, value), 0)
		text_item_node.name = id
	else:
		# Modify text item
		text_item_node.set_text(create_text_item_text(id, value))

func create_text_item_text(id: String, value) -> String:
	var text: String = id + " : " + String(value)
	return text

func add_text_item(text: String, length: float) -> TextItem:
	var text_item: TextItem = text_item_res.instance()
	text_list_node.add_child(text_item)
	text_item.populate(text, length)
	return text_item
