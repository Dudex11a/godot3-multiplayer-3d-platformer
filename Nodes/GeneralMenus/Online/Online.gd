extends Control

#onready var parent_tab_container_node: TabContainer = get_parent()
onready var tab_container_node: = $_TabContainer
onready var host_node: = tab_container_node.get_node("Content/Host")
onready var host_button_node: = host_node.get_node("HBoxContainer/HostButton")
onready var discord_host_button_node: = host_node.get_node("HBoxContainer/DiscordHostButton")
onready var host_option_editor: = host_node.get_node("HostOptionEditor")
onready var connect_node: = tab_container_node.get_node("Content/Connect")
onready var connect_button_node: = connect_node.get_node("ConnectButton")
onready var connect_option_editor: = connect_node.get_node("ConnectOptionEditor")
onready var tab_hbox_container: = $_TabContainer/TabScrollContainer/TabHBoxContainer
onready var back_button: = $BackButton

onready var main_menu_node: = get_node("../..")

signal cancel

#
#func _input(event):
#	if event.is_action_pressed("debug_1"):
#		var fc: FocusCursor = CustomFocus.add_cursor()
#		yield(get_tree(), "idle_frame")
#		fc.set_current_node(self)
#

func get_current_menu() -> Control:
	return tab_container_node.get_children()[tab_container_node.current_tab]

func cancel():
	emit_signal("cancel")

# ===== Focus

func focus_enter_current_menu(focus: FocusCursor):
	focus.set_current_node(get_current_menu().get_children()[0])

# Enter active online tab
func focus_entered(focus: FocusCursor):
	focus_enter_current_menu(focus)

# ===== Game methods
# Update visuals based on button pressed

func Host(_options: Dictionary):
	tab_container_node.disable_tabs(true)
	host_button_node.text = "Stop hosting on Network"
	tab_container_node.current_tab = 0
	
#	discord_host_button_node.disabled = true
	
func StopHosting():
	tab_container_node.disable_tabs(false)
	host_button_node.text = "Host on Network"
	
#	discord_host_button_node.disabled = false

func Connect(_options: Dictionary):
	tab_container_node.disable_tabs(true)
	tab_container_node.current_tab = 1
	connect_button_node.text = "Disconnect"

func Disconnect():
	tab_container_node.disable_tabs(false)
	connect_button_node.text = "Connect"

# ===== Debug methods

#func host_button():
#	host_button_node.pressed = true
#	_on_HostButton_pressed()
#
#func connect_button():
#	connect_button_node.pressed = true
#	_on_ConnectButton_pressed()

# ===== Signals

func _on_HostButton_pressed():
	if host_button_node.pressed:
		# Host
		get_tree().call_group("Game", "Host", host_option_editor.get_options_dic())
	else:
		# Stop Hosting
		get_tree().call_group("Game", "StopHosting")

func _on_DiscordHostButton_pressed():
	if discord_host_button_node.pressed:
		# Host
		get_tree().call_group("Game", "DiscordHost", host_option_editor.get_options_dic())
	else:
		# Stop Hosting
		get_tree().call_group("Game", "DiscordStopHosting")

func _on_ConnectButton_pressed():
	if connect_button_node.pressed:
		# Connect
		get_tree().call_group("Game", "Connect", connect_option_editor.get_options_dic())
	else:
		# Disconnect
		get_tree().call_group("Game", "Disconnect")

func _on_BackButton_pressed():
	cancel()

func _on_HostOptionEditor_cancel():
	cancel()

func _on_ConnectOptionEditor_cancel():
	cancel()

func _on__TabContainer_focus_out_up(focus: FocusCursor):
	focus.set_current_node(back_button)

func _on__TabContainer_tab_looped(focus: FocusCursor, looped: int):
	# On looped left go to back button
	if looped == 1:
		focus.set_current_node(back_button)

func _on_BackButton_ui_right_action(focus: FocusCursor):
	focus.set_current_node(tab_container_node.get_first_tab())
	
func _on_BackButton_ui_left_action(focus: FocusCursor):
	focus.set_current_node(tab_container_node.get_last_tab())

func _on_HostOptionEditor_looped(focus: FocusCursor, loop: int):
	# Wait for loop default behavior to finish
	yield(get_tree(), "idle_frame")
	match loop:
		0: # Down
			focus.set_current_node(host_button_node)
		1: # Up
			focus.set_current_node(tab_hbox_container)

func _on_ConnectOptionEditor_looped(focus: FocusCursor, loop: int):
	# Wait for loop default behavior to finish
	yield(get_tree(), "idle_frame")
	match loop:
		0: # Down
			focus.set_current_node(connect_button_node)
		1: # Up
			focus.set_current_node(tab_hbox_container)
