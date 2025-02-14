extends Material
class_name FacePartMaterial
func get_class() -> String: return "FacePartMaterial"

var name: String = ""

var uv_offset: Vector3 = Vector3.ZERO setget set_uv_offset, get_uv_offset
var uv_scale: Vector3 = Vector3.ONE setget set_uv_scale, get_uv_scale
var texture_rotation: float = 1.571 setget set_texture_rotation, get_texture_rotation

func set_uv_offset(offset: Vector3):
	set("shader_param/uv_offset", offset)

func get_uv_offset() -> Vector3:
	return get("shader_param/uv_offset")

func set_uv_scale(scale: Vector3):
	set("shader_param/uv_scale", scale)

func get_uv_scale() -> Vector3:
	return get("shader_param/uv_scale")

func set_texture_rotation(rotation: float):
	set("shader_param/texture_rotation", rotation)
	
func get_texture_rotation() -> float:
	return get("shader_param/texture_rotation")
