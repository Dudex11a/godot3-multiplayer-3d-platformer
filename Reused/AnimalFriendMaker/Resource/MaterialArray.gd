extends Reference
class_name MaterialArray

var mesh_node: MeshInstance
var mesh_material_id: int = -1

var last_materials: Array = []

# Get all the materials attached to a mesh_node's surface material
func get_material_array() -> Array:
	var mat_array: Array = []
	var mesh_node_material: Material = mesh_node.get_surface_material(mesh_material_id)
	if is_instance_valid(mesh_node_material):
		mat_array.append(mesh_node_material)
		mat_array = get_material_from_array(mat_array)
	return mat_array

# Recursive function to get all the next_pass materials into an array
func get_material_from_array(array: Array) -> Array:
	if array.size() > 0:
		var last_material: Material = array[array.size() - 1]
		if is_instance_valid(last_material.next_pass):
			array.append(last_material.next_pass)
			array = get_material_from_array(array)
	return array

# Add a material to the mesh_node and return the materials position
func add_material(material: Material) -> int:
	var materials: Array = get_material_array()
	if materials.size() > 0:
		var last_material: Material = materials[materials.size() - 1]
		last_material.next_pass = material
	else:
		mesh_node.set_surface_material(mesh_material_id, material)
	return materials.size() - 1

func get_material(index) -> Material:
	var material: Material = null
	if index is int:
		material = get_material_array()[index]
	elif index is String:
		for value in get_material_array():
			if "name" in value:
				if value.name == index:
					material = value
					break
	return material

func get_material_value(index, property: String):
	return get_material(index)[property]

func set_material_value(index, property: String, value):
	var material: Material = get_material(index)
	material[property] = value

# Order materials in mesh_node by the array that is given
func order_by_array(array: Array = create_material_array()):
#	var materials: Array = get_material_array()
	# Remove the next pass on all materials
#	for material in materials:
#		material.next_pass = null
	#
	for index in range(array.size()):
		var material: Material = array[index]
		if index + 1 in array:
			var next_material: Material = array[index] + 1
			material.next_pass = next_material
	mesh_node.set_surface_material(mesh_material_id, array[0])

# This is different from get material array as it organizes the last_materials
# to be at the end of the array. This is used with order_by_array to order the
# last_materials so they're actually last in the next_pass'.
func create_material_array() -> Array:
	var material_array: Array = []
	# Add materials that aren't the last materials
	for material in get_material_array():
		if not material in last_materials:
			material_array.append(material)
	# Add the last_materials
	for material in last_materials:
		material_array.append(material)
	return material_array
