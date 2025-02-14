extends Reference
class_name LinkedColor

var color: Color = Color.black
# Data of the ImagePalette and the connected 
var links: Dictionary = {}

func _init(new_color: Color = Color.black):
	color = new_color

func set_color(new_color: Color):
	color = new_color
	update_image_palette_colors()

func update_image_palette_colors():
	for key in links.keys():
		var image_palette_data = links[key]
		var image_palette: ImagePalette = image_palette_data.image_palette
		# For each color to set within the image_palette
		var color_indexes = image_palette_data.color_indexes
		for color_index in color_indexes:
			image_palette.set_color(color_index, color)

func add_link(key: String, image_palette: ImagePalette, color_index: int):
	# Append color_index if data already exists for key, otherwise create the data
	if key in links:
		# Check to make sure the link doesn't already exist
		if not color_index in links[key].color_indexes:
			links[key].color_indexes.append(color_index)
	else:
		links[key] = {
			"image_palette" : image_palette,
			"color_indexes" : [color_index]
		}
	# Update image_palette color
	image_palette.set_color(color_index, color)

func remove_link(key: String, color_index: int):
	# Make sure data exists for key
	if key in links:
		var link = links[key]
		# Get the color_index's index within color_indexes to erase
		var color_index_index = link.color_indexes.find(color_index)
		# If index found
		if color_index_index >= 0:
			# Remove color_index
			link.color_indexes.remove(color_index_index)
		# If there are no more color_indexes, erase the link
		if link.color_indexes.size() <= 0:
			links.erase(key)

#func remove_link_by_image_palette(key: String, image_palette: ImagePalette):
#	if key in links:
#		var image_palette_data = links[key]
#		if image_palette_data.image_palette == image_palette:
#			image_palette_data.erase(key)
