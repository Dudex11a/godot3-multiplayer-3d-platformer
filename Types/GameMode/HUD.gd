extends Control
class_name GameModeHUD

export var game_mode_id: String = "GameMode"

func _ready():
	# Set name to game_mode_id
	name = game_mode_id

# Stuff needs to be named things for systems to work properly
# -----
# Name the base node the game mode's id
# Name the tscn file HUD
