extends Node

var R: ResourceContainer
var resources_path: String = ""

func _init():
	var resources_path: String = get_script().get_path()
	resources_path = resources_path.replace(resources_path.get_file(), "")
	resources_path += "ResourceContainer/ResourceContainer.tscn"
	R = load(resources_path).instance()
	add_child(R)

const directory_divider: String = "-"

const texture_and_color_layout: Dictionary = {
	"Texture" : {
		"_type" : "texture"
	},
	"Colors" : {
		"_type" : "colors_editor"
	}
}

const directory_layout: Dictionary = {
	"Colors" : {
		"_type" : "all_colors_editor"
	},
	"Body parts" : {
		"Head" : {
	#		"Facial Features" : "face_editor",
	#		"Head Shape" : {
	#
	#		},
	#		"Texture" : {
	#			"_type" : "texture"
	#		},
			"Colors" : {
				# ???
	#			"path": ["head", "color"],
				# Type of thing to do when opened in browser
				"_type" : "limb_colors_editor",
				# Arguments for type in Editor node
				"args" : ["Head"]
			}
		},
		"Body" : {
			"Texture" : {
				"_type" : "texture_editor",
				"args" : ["Body"]
			},
			"Colors" : {
				"_type" : "limb_colors_editor",
				"args" : ["Body"]
			}
		},
		"Arms" : {
	#		"Texture" : {
	#			"_type" : "texture"
	#		},
			"Colors" : {
				"_type" : "limb_colors_editor",
				"args" : ["Arm_L", "Arm_R"]
			},
			"Left Arm" : {
				"Colors" : {
					"_type" : "limb_colors_editor",
					"args" : ["Arm_L"]
				}
			},
			"Right Arm" : {
				"Colors" : {
					"_type" : "limb_colors_editor",
					"args" : ["Arm_R"]
				}
			}
		},
		"Legs" : {
	#		"Texture" : {
	#			"_type" : "texture"
	#		},
			"Colors" : {
				"_type" : "limb_colors_editor",
				"args" : ["Leg_L", "Leg_R"]
			},
			"Left Leg" : {
				"Colors" : {
					"_type" : "limb_colors_editor",
					"args" : ["Leg_L"]
				}
			},
			"Right Leg" : {
				"Colors" : {
					"_type" : "limb_colors_editor",
					"args" : ["Leg_R"]
				}
			}
		},
		"Tail" : {
			"Colors" : {
				"_type" : "limb_colors_editor",
				"args" : ["Tail"]
			}
		}
	#	"Clothes" : {
	#
	#	},
	#	"Animation" : {
	#
	#	},
	#	"Emote" : {
	#
	#	},
	#	"Load Preset" : "SPECIES"
	}
}

const part_defaults: Dictionary = {
	"Basic 1": {
		"valid_color_indexes" : [
			0, 1, 2
		],
		# key = ImagePalette index, value = What color to link it to in AnimalFriend
		"LinkedColors" : {
			0 : 4,
			1 : 5,
			2 : 3
		}
	}
}
