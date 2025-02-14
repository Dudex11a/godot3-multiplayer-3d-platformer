extends Control
class_name DTabContainerContent
tool

onready var dtab_container: = get_node("..")
#onready var tab_hbox_container: = dtab_container.get_node("TabScrollContainer/TabHBoxContainer")

func add_child(node: Node, legible_unique_name: bool = false):
	print("add_child %s" % node)
	# Make tab when node is dropped in
	.add_child(node, legible_unique_name)
	get_node("..").add_tab(node)

func remove_child(node: Node):
	# Remove tab when node is removed
	var tab: Node = get_node("..").get_tab_by_node(node)
	if is_instance_valid(tab):
		tab.delete()
	.remove_child(node)
	
# ===== Focus

func focus_entered(focus: FocusCursor):
	# Go into first visible child
	for child in get_children():
		if "visible" in child:
			if child.visible:
				focus.set_current_node(child)
