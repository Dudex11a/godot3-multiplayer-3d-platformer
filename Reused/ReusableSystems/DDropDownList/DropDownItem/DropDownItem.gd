extends Control
class_name DropDownItem

export var text: String = "" setget set_text

signal pressed(focus)
signal cancel(focus)

func _ready():
	set_text()

func pressed(focus: FocusCursor = null):
	emit_signal("pressed", focus)

func cancel(focus: FocusCursor = null):
	emit_signal("cancel", focus)

# ===== Focus

func ui_accept_action(focus: FocusCursor):
	pressed(focus)

func ui_cancel_action(focus: FocusCursor):
	cancel(focus)

# ===== setget

func set_text(value: String = text):
	text = value

func _on_Button_pressed():
	pressed()
