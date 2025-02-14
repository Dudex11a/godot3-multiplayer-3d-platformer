extends DTabContainer
class_name OptionTabs
tool
func get_class() -> String: return "OptionTabs"

# Overwrite get_children for the get and load save in OptionEditor
# (which is what this node is for)
func get_children() -> Array:
	var content_node: Control = get_content_node()
	if is_instance_valid(content_node):
		return content_node.get_children()
	return []
