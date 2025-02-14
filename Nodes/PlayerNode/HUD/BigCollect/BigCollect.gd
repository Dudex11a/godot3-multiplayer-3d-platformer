extends Control

onready var main_text_node: = $MainText
onready var sub_text_node: = $SubText
onready var anim_player: = $AnimationPlayer

var main_text: String = "You got a Thing!"

func _ready():
	visible = false

func start_popup(sub_text: String = "Sub text", new_main_text: String = main_text):
	main_text = new_main_text
	main_text_node.text = main_text
	sub_text_node.text = sub_text
	anim_player.queue("BigCollectStart")

func end_popup():
	anim_player.queue("BigCollectEnd")
