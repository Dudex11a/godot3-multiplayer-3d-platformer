extends Control

onready var screens_node: = $Screens

var focus_cursor: FocusCursor = null

func _ready():
	# Create focus_cursor that anyone can control
	focus_cursor = CustomFocus.add_cursor(ControllerData.new())
	# Wait for focus_cursor to ge all set
	yield(focus_cursor, "ready")
	# Hide screens
	SetActiveScreen()

func _input(event: InputEvent):
	if not is_instance_valid(focus_cursor):
		return
	if not focus_cursor.controller_data.event_matches(event):
		return
	
	# Exit if menu is pressed and keyboard is noy open
	var text_window_is_visible: bool = false
	if is_instance_valid(focus_cursor):
		if is_instance_valid(focus_cursor.text_window):
			text_window_is_visible = focus_cursor.text_window.is_visible_in_tree()
	if G.array_is_true([
		event.is_action_pressed("ui_menu"),
		not text_window_is_visible,
		focus_cursor.enabled
	]):
		exit_menus()

func exit_menus():
	get_tree().call_group("Game", "SetActiveScreen", "")

# ===== Game methods =====

func SetActiveScreen(screen_name: String = ""):
	# Default screen_name value will hide and re-enable Players
	var show: bool = screen_name != ""
	get_tree().call_group("Game", "DisableLocalPlayerInput", show, "GeneralMenus")
	focus_cursor.enabled = show
	
	# Reset controller_data
#	if not is_instance_valid(controller_data):
#		set_controller_data()
	
	var last_active_screen: Control = null
	
	# Hide other screens
	for child in screens_node.get_children():
		if child.visible:
			last_active_screen = child
			child.visible = false
	
	# Show and set focus to screen_name
	var active_node: Control = screens_node.get_node_or_null(screen_name)
	if is_instance_valid(active_node):
		active_node.visible = true
		focus_cursor.set_current_node(active_node)
#		focus_cursor.set_current_node(active_node)
		if active_node.has_method("open"):
			active_node.open()

# ===== Signals

func _on_Lobby_back():
	exit_menus()

func _on_Online_cancel():
	exit_menus()
