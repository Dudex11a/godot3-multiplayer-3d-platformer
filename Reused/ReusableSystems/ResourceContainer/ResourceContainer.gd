extends Node
class_name ResourceContainer

var resource_instancer: = ResourceInstancer.new()

export var resources: Dictionary
export var instances_to_pool: Dictionary = {}
var pooled_instances: Dictionary = {}

func _ready():
	# Pool instances fomr instances_to_pool
	for key in instances_to_pool.keys():
		var amount_of_instances: int = instances_to_pool[key]
		if key in resources:
			var ids: Array = []
			# Make an array of ids for instances
			for index in range(amount_of_instances):
				ids.append(key)
			#
			pooled_instances[key] = get_instances(ids, false)
	# Pool all PackedScene instances from resources
	for key in resources.keys():
		var resource = resources[key]
		if resource is PackedScene:
			var instance = get_instance(key, false)
			if key in pooled_instances:
				pooled_instances[key].append(instance)
			else:
				pooled_instances[key] = [instance]

func get_resource(id: String) -> Object:
	var res
	res = resources[id]
	if is_instance_valid(res):
		return res
	else:
		return null

func has_resource(id: String) -> bool:
	return id in resources

func get_instance(id: String, from_pool: bool = true) -> Object:
	return get_instances([id], from_pool)[0]

func get_instances(ids: Array, from_pool: bool = true) -> Array:
	var new_ids: Array = ids.duplicate()
	var instances: Array = []
	# Get instance from pooled instances if pooled
	for id in new_ids:
		var instance_was_pooled: bool = false
		# Check if instance is pooled
		if id in pooled_instances and from_pool:
			if pooled_instances[id].size() > 0:
				# Add to instances
				instances.append(pooled_instances[id][0])
				# Remove instance from pooled_instances
				pooled_instances[id].remove(0)
				instance_was_pooled = true
		# Load instance with ResourceInstancer
		if not instance_was_pooled:
			instances.append(resource_instancer.load_start([get_resource(id)])[0])
	return instances

#func get_instances(ids: Array) -> Dictionary:
#	var new_ids: Array = ids.duplicate()
#	# Get resources from ids to new array
#	var resources: Dictionary = {}
#	for id in new_ids:
#		resources[id] = get_resource(id)
#	#
#	var resources_to_load: Array = resources.values()
#	var instances: Dictionary = {}
#	# Get instance from pooled instances if pooled
#	for id in new_ids:
#		if id in pooled_instances:
#			if pooled_instances[id].size() > 0:
#				# Add to instances
#				instances[id] = pooled_instances[id][0]
#				# Remove instance from pooled_instances
#				pooled_instances[id].remove(0)
#				# Remove from resources_to_load since it already has it
#				G.debug_print(instances)
#				G.debug_print(resources_to_load)
##				resources_to_load.erase(instances[id])
#	# Load not pooled instances with resource_instancer
#	var instances_loaded: Array = yield(resource_instancer.load_start(resources_to_load), "completed")
#	# Attach instances to their ids in instances
#
#	return instances
