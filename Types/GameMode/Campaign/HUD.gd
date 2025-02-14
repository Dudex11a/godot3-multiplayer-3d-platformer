extends GameModeHUD

onready var big_collect_node: = $BigCollect
onready var collectible_amount_node: = $CollectibleAmount
onready var collectible_amount_label: = collectible_amount_node.get_node("Amount")

func setup_w_player_node(player_node: PlayerNode):
	var main_node: Node = O3DP.get_main()
	var game_mode: CampaignGameMode = main_node.current_game_mode
	# Get collectible amount from player
	var player_save: PlayerSave = player_node.get_player_save()
	# If has any collectibles
	if is_instance_valid(player_save):
		if game_mode.main_collectible_type in player_save.get_game_mode_place_save():
			var player_collectibles: Array = player_save.get_game_mode_place_save_value(game_mode.main_collectible_type)
			set_collectible_amount(player_collectibles.size())

func collect_start(sub_text, main_text):
	big_collect_node.start_popup(sub_text, main_text)

func collect_end():
	big_collect_node.end_popup()

func set_collectible_amount(value: int):
	# Set value
	collectible_amount_label.text = String(value)
	# Play animation
	
