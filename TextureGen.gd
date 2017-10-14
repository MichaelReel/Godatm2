extends Sprite

func _ready():
	var dims = get_viewport_rect().size
	var width = 100
	var height = 100
	
	var openSimplex = load("res://OpenSimplex.gd")
	var perlinRef   = load("res://PerlinRef.gd")
	
	var simplex = openSimplex.new(1)
	var perlin = perlinRef.new(10, 10)
	
	var texture = ImageTexture.new()
	
	texture.create(width, height, Image.FORMAT_GRAYSCALE)
	
	var data = Image(width, height, false, Image.FORMAT_GRAYSCALE)
	
	for y in range(int(height)):
		for x in range(int(width)):
			# var c_comp = simplex.noise2d(x, y)
			var c_comp = (perlin.fractal2d(8, 0.5, x, y) + 0.5) / 3
			var color = Color(c_comp, c_comp, c_comp, 1)
			data.put_pixel(x, y, color)
	
	texture.set_data(data)
	
	self.set_pos(Vector2(width / 2, height / 2))
	self.set_texture(texture)
