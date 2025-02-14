extends Control
class_name DTabContainer
tool

#onready var get_tab_hbox_container(): = $TabScrollContainer/TabHBoxContainer
#onready var content_node: = $Content

export var dtab_res: PackedScene

export var current_tab: int = 0 setget set_current_tab

signal tab_changed(tab)
signal focus_out_up(focus)
signal focus_out_down(focus)
signal tab_looped(focus, looped)

# So I can tell if this node or node's that inherit dtab_container are dtab_container
# without having to use the Type (potential for cyclic errors)
const is_dtab_container: bool = true

func _ready():
	# Remove any old tabs
#	for child in get_tab_hbox_container().get_children():
#		remove_tab(child.name)
	# Make tabs for content's children
	for child in get_content_node().get_children():
		# If Control and doesn't already exist
		if child is Control and not get_tab_hbox_container().has_node(child.name):
			add_tab(child)
	
	# Hide tab content
	for node in get_content_children():
		node.visible = false
	
	self.current_tab = current_tab

func add_tab(node: Node):
	var tab_name = node.name
	var tab: DTab = dtab_res.instance()
	get_tab_hbox_container().add_child(tab)
	tab.name = tab_name
	tab.label_node.text = tab_name
	tab.associated_node = node
	node.connect("renamed", tab, "set_name_by_node", [node])
	tab.connect("pressed", self, "tab_pressed", [tab])
	tab.connect("ui_up_action", self, "tab_ui_up_action")
	tab.connect("ui_down_action", self, "tab_ui_down_action")

func get_tab_by_name(node_name: String) -> Node:
	return get_tab_hbox_container().get_node_or_null(node_name)

func get_tab_by_node(node: Node) -> Node:
	return get_tab_by_name(node.name)

func remove_tab_by_name(node_name: String):
	var tab: DTab = get_tab_by_name(node_name)
	if is_instance_valid(tab):
		tab.delete()

func node_renamed(node: Node):
	# Rename corresponding tab
	var tab: DTab = get_tab_by_node(node)
	if is_instance_valid(tab):
		# Rename tab to new name
		tab.name = node.name

func get_content_node() -> Node:
	if is_instance_valid(get_node_or_null("Content")):
		return $Content
	return null
	
func get_tab_hbox_container() -> Node:
	return $TabScrollContainer/TabHBoxContainer

func get_tabs() -> Array:
	return get_tab_hbox_container().get_children()

func get_current_tab_node() -> DTab:
	return get_tabs()[current_tab]

func get_content_children() -> Array:
	return get_content_node().get_children()

func get_current_content() -> Control:
	return get_content_children()[current_tab]

func get_first_tab() -> DTab:
	var tabs: Array = get_tabs()
	if tabs.size() > 0:
		return tabs[0]
	return null

func get_last_tab() -> DTab:
	var tabs: Array = get_tabs()
	if tabs.size() > 0:
		return tabs[tabs.size() - 1]
	return null

func get_active_tab() -> Node:
	for tab in get_tabs():
		if tab.button_node.pressed:
			return tab
	return null

func set_current_tab_w_name(tab_name: String):
	var tab_content: Control = get_content_node().get_node_or_null(tab_name)
	if is_instance_valid(tab_content):
		self.current_tab = tab_content.get_index()

func disable_tabs(disable: bool):
	for tab in get_tabs():
		tab.disable(disable)
	# Re-enable tab when enabled
	if not disable:
		get_current_tab_node().set_button_pressed(true)

# ===== Tab Actions

func tab_ui_up_action(focus: FocusCursor):
	emit_signal("focus_out_up", focus)

func tab_ui_right_action(focus: FocusCursor):
#	emit_signal("tab_focus_right", focus)
	
	focus.set_current_node(G.get_next_child(focus.current_node, 1))

func tab_ui_down_action(focus: FocusCursor):
	focus.set_current_node(get_current_content())

func tab_ui_left_action(focus: FocusCursor):
	emit_signal("tab_focus_left", focus)

func tab_pressed(tab: DTab):
	set_current_tab_w_name(tab.name)

# ===== setget

func set_current_tab(value: int):
	# Don't allow current tab to be set if not initalized
	if not is_instance_valid(get_content_node()):
		return
	# End if content node has to children
	var content_node_children: Array = get_content_children()
	if content_node_children.size() <= 0:
		return
	# Don't set if value is bellow 0
	if value < 0:
		return
	var old_tab_content_id: int = current_tab
	var old_tab_content: Control = null
	if old_tab_content_id >= 0:
		old_tab_content = content_node_children[old_tab_content_id]
	current_tab = value
	var current_tab_content: Control = content_node_children[current_tab]
	if is_instance_valid(old_tab_content):
		# Hide previous tab
		old_tab_content.visible = false
		# Un-toggle_last_tab
		var old_tab_node = get_tab_by_node(old_tab_content)
		if is_instance_valid(old_tab_node):
			old_tab_node.set_button_pressed(false)
	# Set visiblity to new tab
	current_tab_content.visible = true
	# Toggle new tab
	get_current_tab_node().set_button_pressed(true)
	emit_signal("tab_changed", current_tab)

# ===== Signals

func _on_TabHBoxContainer_focus_cursor_entered(focus: FocusCursor):
	focus.set_current_node(get_active_tab())

func _on_TabHBoxContainer_tab_looped(focus: FocusCursor, looped: int):
	emit_signal("tab_looped", focus, looped)
