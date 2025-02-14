extends ResourceContainer

var af_resources: Dictionary = {}

export var resource_folder_marker: PackedScene
var resource_path: String = ""
var components_path: String = ""

func _ready():
	# Set the parts path in relation to the resource_folderr_marker
	resource_path = resource_folder_marker.resource_path
	resource_path = resource_path.replace(resource_path.get_file(), "")
	components_path = resource_path + "Components/"
	# Load af_resources into object
	var path: String = components_path
	af_resources = G.directory_to_dictionary(path)

func get_af_resource(path: Array) -> Object:
	var res = af_resources
	# Loop through strings in path
	for index in range(path.size()):
		var key = path[index]
		if key in res:
			res = res[key]
			if index >= path.size():
				return null
		else:
			return null
	return res
