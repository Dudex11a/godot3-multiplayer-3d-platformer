extends Node
class_name Resources

export var debug_text_res: PackedScene
export var resources: Dictionary

func get_resource(id: String) -> Object:
	var res
	res = resources[id]
	if is_instance_valid(res):
		return res
	else:
		return null
