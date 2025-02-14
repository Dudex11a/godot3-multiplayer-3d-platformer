extends Control

onready var back_button: = $BackButton
onready var tab_hbox_container: = $OptionEditor/Options/TabScrollContainer/TabHBoxContainer

#func _ready():
#	$OptionEditor/Options/OptionContainer.queue_sort()

# ===== Focus

func focus_entered(focus: FocusCursor):
	focus.set_current_node(tab_hbox_container)

func _on_OptionTabs_tab_focus_left(focus: FocusCursor):
	focus.set_current_node(back_button)

# ===== Signals

func _on_BackButton_pressed():
	# Exit on back
	get_tree().call_group("Game", "SetActiveScreen", "")

func _on_Options_tab_looped(focus: FocusCursor, looped: int):
	match looped:
		1:
			focus.set_current_node(back_button)

func _on_Shadows_value_changed(value: String):
	O3DP.set_current_shadows(value)
