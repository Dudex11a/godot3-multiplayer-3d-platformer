extends Node
class_name LazyAudio

export var sound_amount: int = 10
export var audio_array: Array = []
var sound_dictionary: Dictionary = {}
var audio_directory: String = "res://Resources/LazyAudio/"

var audio_players: Array = []

func _ready():
	# Create the sound nodes
	for index in range(sound_amount):
		var player: = AudioStreamPlayer.new()
		add_child(player)
		player.name = "AudioPlayer" + String(index)
		audio_players.append(player)
	
	# Create sound_dictionary from audio_array
	for sound in audio_array:
		# Create sound dictionary name/key
		var file_path: String = sound.resource_path
		var file_name: String = file_path.get_file().replace(".import", "")
		file_name = file_name.replace("." + file_name.get_extension(), "")
		# Save sound under file_name
		sound_dictionary[file_name] = sound
	
	# Old code for dynamically loading from folder, I don't believe this is possible to do
	# Create audio in sound dictionary
	# Get audio file paths
#	var audio_paths: Array = []
#	var dir: Directory = Directory.new()
#	if dir.open(audio_directory) == OK:
#		dir.list_dir_begin()
#		var file_name: String = dir.get_next()
#		while file_name != "":
#			if not dir.current_is_dir():
#				print(file_name)
#				if not ".import" in file_name:
#					audio_paths.append(audio_directory + file_name)
#			file_name = dir.get_next()
#	else:
#		G.debug_print("LazyAudio directory doesn't exist")
#	printt("Paths", audio_paths)
#	# Add Audio files to sound_dictionary
#	for path in audio_paths:
#		var file_name: String = path.get_file().replace(".import", "")
#		file_name = file_name.replace("." + file_name.get_extension(), "")
#		sound_dictionary[file_name] = load(path)
#	printt("Sounds", sound_dictionary)

func get_sound(id: String) -> AudioStream:
	var sound: AudioStream
	if id in sound_dictionary:
		sound = sound_dictionary[id]
	else:
		G.debug_print("Sound id '" + id + "' doesn't exist.")
	return sound

func play_sound(id: String, aditional_params: Dictionary = {}):
	var sound = get_sound(id)
	if is_instance_valid(sound):
		for player in audio_players:
			if not player.playing:
				player.stream = sound
				G.overwrite_object(player, aditional_params)
				player.play()
				break
