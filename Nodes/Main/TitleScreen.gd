extends Control

onready var letter_hitbox_container: = $LetterHitboxes/LettersContainer
onready var letter_mesh_container: = $"3DTitleContainer/Viewport/Title3D/Title"
onready var letter_objects: Dictionary = get_letter_objects()

const letter_anim_length: float = 0.5
const letter_spin_acceleration: float = 100.0
const letter_spin_max_speed: float = 22.0

export var rotation_curve: Curve

var active_letters: Array = []
var just_became_visible: bool = false

func _input(event: InputEvent):
	if not visible or just_became_visible:
		return
	# TEMP change this for controller later
	if is_event_letter_valid(event):
		var drag_right: bool = true
		# Exit if not dragged hard enough
		if event is InputEventScreenDrag:
			# Exit if not enough drag speed
			if event.speed.length() < 160.0:
				return
		# Check if letter is pressed
		for hitbox in letter_hitbox_container.get_children():
			if hitbox is Control:
				var letter_id: String = hitbox.name.split("_")[0]
				var do_process_letter: bool = true
				# End if not in bot
				if is_event_mouse(event):
					if not G.within_box(event.position, hitbox.rect_global_position, hitbox.rect_size):
						do_process_letter = false
				else:
					# Get note from event
					var note: String = O3DP.get_note_from_event(event)
					# Do event note and letter note match?
					if letter_objects[letter_id].note != note:
						do_process_letter = false
					
					# This whole system will check more points on a drag.
					# It does way too many computations so I'm not using it but it does work (I think)
#						var drag_connects: bool = false
#						if event is InputEventScreenDrag:
#							var initial_position: Vector2 = event.position - event.relative
#							# Check if the drag connects on points depending how fast it is
#							var drag_amount: = int(event.speed.length() / 100)
#							for index in range(drag_amount):
#								# Get position on line
#								var far_in_weight: float = index / drag_amount
#								var point_to_pos: Vector2 = initial_position.linear_interpolate(event.position, far_in_weight)
##								print(point_to_pos)
#								if G.within_box(point_to_pos, hitbox.rect_global_position, hitbox.rect_size):
#									drag_connects = true
#									process_letter(letter_id, event)
				
				if do_process_letter and not "just_pressed" in letter_objects[letter_id]:
					process_letter(letter_id, event)

func process_letter(letter_id: String, event: InputEvent):
	# Pressed is true unless released
	var pressed: bool = true
	if "pressed" in event:
		pressed = event.pressed
	# Check drag direction
	var drag_right: bool = true
	if event is InputEventScreenDrag:
		# Check if dragging right
		drag_right = event.relative.x > 0
	if not letter_id in active_letters and pressed:
		register_letter_just_pressed(letter_id)
		# Activate if not active
		active_letters.append(letter_id)
		# Set letter spin timeout
		var timer: SceneTreeTimer = get_tree().create_timer(letter_anim_length)
		letter_anim_start(letter_id)
		# Spin while timer is active
		yield(letter_hold(timer, letter_id, drag_right), "completed")
		# Timer end, remove active when time's up
		active_letters.erase(letter_id)
		# Head to end
		letter_ending(letter_id)
	# End if double pressed or released
	if G.array_is_true([
	letter_id in active_letters,
	pressed,
	not event is InputEventScreenDrag]):
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		if letter_id in active_letters:
			active_letters.erase(letter_id)
		letter_objects[letter_id].speed = 0
		letter_objects[letter_id].mesh.rotation.y = 0

func register_letter_just_pressed(letter_id: String):
	letter_objects[letter_id].just_pressed = true
	yield(get_tree(), "idle_frame")
	if "just_pressed" in letter_objects[letter_id]:
		letter_objects[letter_id].erase("just_pressed")

# I want it to hold when mouse pressed
# Stop holding if slide off
# Have it check if still held at end of timer

# Return while not being held
# Break while if re-pressed


func letter_hold(timer: SceneTreeTimer, letter_id: String, drag_right: bool = true):
	var timer_position: float = 0.0
	while letter_id in active_letters:
		# Is there no time left?
		if timer.time_left <= 0:
			# Hold until letter is not pressed
			if not is_letter_pressed(letter_id):
				break
		# Calculate timer pos
		timer_position = abs((timer.time_left / letter_anim_length) - 1.0)
		letter_anim_hold(letter_id, drag_right)
		yield(get_tree(), "idle_frame")

func letter_ending(letter_id: String):
	var letter_mesh: Spatial = letter_objects[letter_id].mesh
	while letter_objects[letter_id].speed != 0:
		var delta: float = get_process_delta_time()
		# End if pressed again
		if letter_id in active_letters:
			break
		# Move to 0 rotation
		letter_objects[letter_id].speed = move_toward(letter_objects[letter_id].speed, 0, letter_spin_acceleration * delta)
		# Animate
		letter_mesh.rotation.y += letter_objects[letter_id].speed * delta
		yield(get_tree(), "idle_frame")
	# If no longer pressed after end set speed to 0
	if not is_letter_pressed(letter_id):
		letter_objects[letter_id].speed = 0.0

func letter_anim_start(letter_id: String):
	pass

func letter_anim_hold(letter_id: String, drag_right: bool = true):
	var delta: float = get_process_delta_time()
	var letter_mesh: Spatial = letter_objects[letter_id].mesh
	var destination: float = letter_spin_max_speed
	if not drag_right:
		destination *= -1
	letter_objects[letter_id].speed = move_toward(letter_objects[letter_id].speed, destination, letter_spin_acceleration * delta)
	letter_mesh.rotation.y += letter_objects[letter_id].speed * delta
	return false

func is_letter_pressed(letter_id: String) -> bool:
	# Check mouse input first
	if is_position_in_letter(letter_id) and Input.is_mouse_button_pressed(1):
		return true
	# Check other input methods
	if Input.is_action_pressed(O3DP.get_action_name_from_note(letter_objects[letter_id].note)):
		return true
	return false

func is_event_mouse(event: InputEvent) -> bool:
	return event is InputEventScreenTouch or event is InputEventScreenDrag

func is_event_letter_valid(event: InputEvent) -> bool:
	if is_event_mouse(event):
		return true
	if O3DP.get_note_from_event(event) != "":
		return true
	return false

func is_position_in_letter(letter_id: String, position: Vector2 = get_global_mouse_position()):
	var letter_hitboxes: Array = letter_objects[letter_id].hitboxes
	for hitbox in letter_hitboxes:
		if G.within_box(position, hitbox.rect_global_position, hitbox.rect_size):
			return true
	return false

# ===== setget

func get_letter_objects() -> Dictionary:
	var value: Dictionary = {}
	
	# Func add valid controller events for each button
	var to_add: Dictionary = {
		"P1" : {
			"note" : "C#"
		},
		"A1" : {
			"note" : "D#"
		},
		"L" : {
			"note" : "F#"
		},
		"Apostrophe" : {
			"note" : "G#"
		},
		"N1" : {
			"note" : "A#"
		},
		"A2" : {
			"note" : "C"
		},
		"R" : {
			"note" : "D"
		},
		"O" : {
			"note" : "E"
		},
		"U" : {
			"note" : "F"
		},
		"N2" : {
			"note" : "G"
		},
		"D" : {
			"note" : "A"
		}
	}
	
	# Get Meshes
	for letter_mesh in letter_mesh_container.get_children():
		var letter_id: String = letter_mesh.name
		value[letter_id] = {}
		value[letter_id].mesh = letter_mesh
		# Add speed values
		value[letter_id].speed = 0.0
		value[letter_id].note = to_add[letter_id].note
	
	# Get Hitboxes
	for letter_hitbox in letter_hitbox_container.get_children():
		var letter_dic: Dictionary = value[letter_hitbox.name.split("_")[0]]
		# Define hitboxes if doesn't exist
		if not "hitboxes" in letter_dic:
			letter_dic.hitboxes = []
		# Add hitbox
		letter_dic.hitboxes.append(letter_hitbox)
	
	return value

func set_visible(value: bool):
	.set_visible(value)
	if visible:
		just_became_visible = true
		yield(get_tree().create_timer(0.5), "timeout")
		just_became_visible = false

# ===== Signals

func _on_SettingsButton_pressed():
	get_tree().call_group("Game", "SetActiveScreen", "Settings")
