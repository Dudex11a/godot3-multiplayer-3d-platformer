extends Reference
class_name ImagePalette

var image: Image = null
var image_texture: ImageTexture = ImageTexture.new()

func _init():
	image = AF_Maker.R.get_resource("base_palette").get_data()
	update_image_texture()

func set_color(index: int, color: Color):
	image.lock()
	image.set_pixelv(get_pixel_coords(index), color)
	image.unlock()
	update_image_texture()

func get_color(index: int) -> Color:
	var color: Color = Color.black
	image.lock()
	color = image.get_pixelv(get_pixel_coords(index))
	image.unlock()
	return color

func get_pixel_coords(index: int) -> Vector2:
	var coords: Vector2 = Vector2.ZERO
	var image_size = image.get_size()
	coords.x = index % int(image_size.x)
	coords.y = index / int(image_size.y)
	return coords

func update_image_texture():
	image_texture.create_from_image(image, 0)
