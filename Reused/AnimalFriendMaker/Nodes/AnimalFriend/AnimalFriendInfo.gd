extends Reference
class_name AnimalFriendInfo

func _init():
	randomize()
	LinkedColors.append_array(G.create_random_color_scheme())

var Face: Dictionary = {
	
	
}
# I want to store color info in here, what info do I need
# I can store both this information in each part
# Update this info when colors are set
	# Unique colors:
		# In part Dictionary "UniqueColors":
			# are stored in a Dictionary with the key being
			# the index of the color in the ImagePalette
	# Linked colors:
		# In part Dictionary "LinkedColors":
			# key = ImagePalette index, value = What color to link it to in AnimalFriend
		# In LinkedColors:
			# Array of colors

var Head: Dictionary = {
	"PartName" : "Basic 1",
	"Mesh" : ["Head", "Cat 1", "Mesh"],
	"ColorTexture" : ["Head", "Cat 1", "Texture", "ColorTexture1"]
	
}
var Body: Dictionary = {
	"PartName" : "Basic 1",
	"Mesh" : ["Body" ,"Basic 1", "Mesh"],
	"ColorTexture" : ["Body", "Basic 1", "Texture", "ColorTexture1"]
	
}
var Arm_L: Dictionary = {
	"PartName" : "Basic 1",
	"Mesh" : ["Arm", "Basic 1", "L"],
	"ColorTexture" : ["Arm", "Basic 1", "Texture", "ColorTexture1"]
	
}
var Arm_R: Dictionary = {
	"PartName" : "Basic 1",
	"Mesh" : ["Arm", "Basic 1", "R"],
	"ColorTexture" : ["Arm", "Basic 1", "Texture", "ColorTexture1"]
	
}
var Leg_L: Dictionary = {
	"PartName" : "Basic 1",
	"Mesh" : ["Leg", "Basic 1", "L"],
	"ColorTexture" : ["Leg", "Basic 1", "Texture", "ColorTexture1"]
	
}
var Leg_R: Dictionary = {
	"PartName" : "Basic 1",
	"Mesh" : ["Leg", "Basic 1", "R"],
	"ColorTexture" : ["Leg", "Basic 1", "Texture", "ColorTexture1"]
	
}
var Tail: Dictionary = {
	"PartName" : "Basic 1",
	"Mesh" : ["Tail", "Basic 1", "Mesh"],
	"ColorTexture" : ["Tail", "Basic 1", "Texture", "ColorTexture1"]
	
}
var Anims: Dictionary = {
	"FullBody": {
		"Walk" : ["Anims", "Walk", "Swaggy"],
		"Airborne" : ["Anims", "Airborne", "AllIn"],
		"Climb" : ["Anims", "Climb", "Basic"],
		"Crouch" : ["Anims", "Crouch", "Sit"],
		"Roll" : ["Anims", "Roll", "Cartwheel"],
		"AirDash" : ["Anims", "AirDash", "Hero"],
		"Pickup" : ["Anims", "Pickup", "Basic"],
		"Place" : ["Anims", "Place", "Basic"],
		"Throw" : ["Anims", "Throw", "Basic"]
	},
	"UpperBody": {
		"Hold" : ["Anims", "Hold", "TwoHanded"]
	}
}
var Clothes: Array = [
	
]
var LinkedColors: Array = [
	Color.black,
	Color.white
]

#func randomize_linked_colors():
#	randomize()
#	for index in range(LinkedColors.size()):
#		var color = LinkedColors[index]
#		if color is Color:
#			color.v = randf()
#			color.s = randf() / 2 + .4
#			color.h = randf()
#			LinkedColors[index] = color

func to_dictionary() -> Dictionary:
	var dictionary: = {
		"Face" : Face,
		"Head" : Head,
		"Body" : Body,
		"Arm_L" : Arm_L,
		"Arm_R" : Arm_R,
		"Leg_L" : Leg_L,
		"Leg_R" : Leg_R,
		"Tail" : Tail,
		"Clothes" : Clothes,
		"LinkedColors" : LinkedColors
	}
	G.color_in_object_to_string(dictionary)
	return dictionary

func from_dictionary(dictionary: Dictionary) -> AnimalFriendInfo:
	G.string_in_object_to_color(dictionary)
	G.overwrite_object(self, dictionary)
	return self
