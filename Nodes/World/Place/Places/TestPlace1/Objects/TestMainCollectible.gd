extends "res://Nodes/Pawn/Actor/Collectible/MainCollectible/MainCollectible.gd"

onready var model_mesh: = $Model/Mesh

export var on_color: = Color.yellow
export var off_color: = Color.darkblue

func _ready():
	# Make model mesh material unique
	model_mesh.set_surface_material(0, model_mesh.get_surface_material(0).duplicate())

func set_visibility(value: float):
	.set_visibility(value)
	if is_instance_valid(model_mesh):
		var material = model_mesh.get_surface_material(0)
		material.albedo_color = off_color.linear_interpolate(on_color, value)
