extends Keyboard
class_name EnglishKeyboard

onready var keys_node: = $Keys
onready var a_key_node: = keys_node.get_node("a")
onready var caps_icon_node: = keys_node.get_node("Caps/Icon")

export(Array, StreamTexture) var caps_icons = []

enum {
	CAPS_OFF,
	CAPS_SHIFT,
	CAPS_ON
}
var caps: int = CAPS_OFF setget set_caps

func _ready():
	connect_keys(keys_node.get_children())
	caps_icon_node.texture = caps_icons[0]

func key_pressed(key: String):
	# Intercept key input if something needs to be done specifically here
	match key:
		"Enter":
			emit_signal("commit_pressed")
		">":
			emit_signal("right_pressed")
		"<":
			emit_signal("left_pressed")
		_:
			match key:
				"Space":
					emit_signal("key_pressed", " ")
				_:
					emit_signal("key_pressed", key)
			# Change caps to lower if was shift
			if caps == CAPS_SHIFT:
				self.caps = CAPS_OFF

func set_caps(value: int):
	caps = value
	if is_instance_valid(keys_node):
		# Adjust single character keys if caps on
		for key_node in keys_node.get_children():
			if key_node is Key:
				if key_node.character.length() == 1:
					match value:
						CAPS_OFF:
							key_node.character = key_node.character.to_lower()
						CAPS_ON, CAPS_SHIFT:
							key_node.character = key_node.character.to_upper()
		caps_icon_node.texture = caps_icons[caps]

# ===== Focus

func focus_entered(focus: FocusCursor):
	focus.set_current_node(a_key_node)

func ui_cancel_action_pp(_focus: FocusCursor, _parent: Node):
	emit_signal("backspace_pressed")

# ===== Signals

func _on_Caps_pressed():
	# Increment caps
	self.caps = (caps + 1) % 3

func _on_Backspace_pressed():
	emit_signal("backspace_pressed")
