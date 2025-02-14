extends Control
class_name TextItem

onready var text_node: = $Text
onready var image_node: = $Image
var timer_node: Timer
#onready var timer_progress_bar: = $TimerProgressBar

var text: String = "" setget set_text

signal timer_stopped

func populate(text: String, length: float):
	set_text(text)
	if length > 0:
		# Create timer node
		timer_node = Timer.new()
		add_child(timer_node)
		timer_node.connect("timeout", self, "on_Timer_timeout")
		timer_node.one_shot = true
		timer_node.wait_time = length
		timer_node.start()
		# Update timer progress bar once timer activated
		while not timer_node.is_stopped():
#			timer_progress_bar.value = (timer_node.time_left / timer_node.wait_time) * 100
			yield(get_tree(), "idle_frame")
		emit_signal("timer_stopped")

func set_text(val: String):
	text = val
	if is_instance_valid(text_node):
		text_node.text = val
	# Set node width based on text
	var font: Font = text_node.get("custom_fonts/font")
	rect_min_size.x = font.get_string_size(text).x + 80

func set_texture(value: Texture):
	image_node.texture = value

func _on_CloseButton_pressed():
	if is_instance_valid(timer_node):
		timer_node.stop()
	remove()

func on_Timer_timeout():
	remove()

func remove():
	if is_instance_valid(timer_node):
		yield(self, "timer_stopped")
	queue_free()
