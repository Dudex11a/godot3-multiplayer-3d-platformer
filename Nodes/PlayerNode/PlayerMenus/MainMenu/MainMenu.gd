extends Control

onready var buttons_node: = $ScrollContainer/Buttons
onready var anim_player: = $AnimationPlayer

export var main_menu_anim_progress: float = 0.0 setget set_main_menu_anim_progress
#export var anim_button_start_x: float = 13.0
#export var anim_button_end_x: float = 60.0
export var open_anim_x_curve: Curve
export var exit_anim_x_curve: Curve
export var time_offset: float = 0.1

var anim_playing: String = "None"

signal open_anim_end
signal exit_anim_end

func _ready():
	for child in buttons_node.get_children():
		connect("open_anim_end", child, "open_anim_end")

func set_main_menu_anim_progress(value: float):
	main_menu_anim_progress = value
	# Animation
	if is_instance_valid(buttons_node):
		var children: Array = buttons_node.get_children()
		for index in range(buttons_node.get_child_count()):
			var time: float = max(value, 0)
#			var time: float = max(value - (time_offset * index), 0)
			var child = children[index]
			if child.get_class() == "MainMenuButton":
				var x_interpolation: float = 0.0
				match anim_playing:
					"OpenMainMenu":
						x_interpolation = open_anim_x_curve.interpolate(time)
					"ExitMainMenu":
						x_interpolation = exit_anim_x_curve.interpolate(time)
				child.visual_node.rect_position.x = x_interpolation

func focus_entered(focus_cursor: FocusCursor):
	focus_cursor.set_current_node(buttons_node.get_children()[0])

func open():
	var anim_name: String = "OpenMainMenu"
	anim_playing = anim_name
	anim_player.stop(true)
	anim_player.play(anim_name)

func exit_anim():
	var anim_name: String = "ExitMainMenu"
	anim_playing = anim_name
	anim_player.stop(true)
	anim_player.play(anim_name)

func _on_AnimationPlayer_animation_finished(anim_name: String):
	match anim_name:
		"OpenMainMenu":
			emit_signal("open_anim_end")
		"ExitMainMenu":
			emit_signal("exit_anim_end")

func _on_OnlineButton_pressed():
	get_tree().call_group("Game", "SetActiveScreen", "Online")

func _on_GameButton_pressed():
	get_tree().call_group("Game", "SetActiveScreen", "Lobby")
