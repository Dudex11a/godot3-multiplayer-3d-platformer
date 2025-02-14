extends Reference
class_name ResourceInstancer

signal done

var thread: = Thread.new()
#var can_async: bool = false
#var can_async: bool = ["Windows", "OSX", "UWP", "X11"].has(OS.get_name())

var load_queue: Array = []

func load_start(resource_list: Array) -> Array:
	var resources_in = resource_list.duplicate()
	var out: Array = []
	for resource in resources_in:
		out.append(resource.instance())
	return out

#func load_start(resource_list: Array) -> Array:
#	var resources_in = resource_list.duplicate()
#	var out: Array = []
#	if can_async:
#		thread.start(self, "threaded_load", resources_in, 1)
#		out = yield(self, "done")
#		thread.wait_to_finish()
#	else:
#		regular_load(resources_in)
#		out = yield(self, "done")
#	return out
#
#func regular_load(resources_in: Array):
#	var resources_out: Array = []
#	for res_in in resources_in:
#		resources_out.append(res_in.instance())
#	call_deferred("emit_signal", "done", resources_out)

#func queue_threaded_load(resource_list: Array) -> Array:
#	var resources_in: Array = resource_list
#	var instances: Array = []
#	load_queue.append(resource_list)
#	if not thread.is_active():
#		thread.start(self, "threaded_load", resources_in)
#		instances = yield(self, "done")
#		thread.wait_to_finish()
#	return instances

#func threaded_load(resources_in: Array):
#	var resources_out: Array = []
#	for res_in in resources_in:
#		resources_out.append(res_in.instance())
#	call_deferred("emit_signal", "done", resources_out)
