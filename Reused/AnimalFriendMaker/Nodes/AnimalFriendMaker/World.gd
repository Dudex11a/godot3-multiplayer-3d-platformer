extends Spatial

onready var a_f_node: = $AnimalFriend
onready var camera_rod_node: = $CameraRod

var a_f_materials: MaterialArray = MaterialArray.new()

#func _ready():
#	a_f_materials.mesh_node = a_f_node.head_node
#	a_f_materials.mesh_material_id = 0

#func _process(delta: float):
#	camera_rod_node.rotation.y += delta
#	for material in a_f_materials.get_material_array():
#		material.texture_rotation += delta
#		material.uv_offset.x = material.uv_offset.x + delta
#		material.uv_offset.x = move_toward(material.uv_offset.x, randf() * 2 - 1, delta)
