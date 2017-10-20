extends Node2D

export var gridSize = Vector2()
export (TileSet) var tileset

const WATER_SAND_MAP = 0
const GRASS_MAP = 1
const TREE_MAP = 2
const PROC_DEBUG_SPRITE = 3

const wave_width = 32
const wave_height = 32
const wave_depth = 1

var grid_start_x
var grid_start_y
var grid_end_x
var grid_end_y

var water_sand_map
var grass_map
var tree_map
var debug_sprite

var tile_width
var tile_height

func _ready():
	
	self.grid_start_x = 0
	self.grid_start_y = 0
	self.grid_end_x = int(gridSize.x)
	self.grid_end_y = int(gridSize.y)
	
	self.water_sand_map = self.find_node("WaterSand", false)
	self.grass_map = self.find_node("Grass", false)
	self.tree_map = self.find_node("Tree", false)
	self.debug_sprite = self.find_node("ProcDebug", false)
	
	# Index tileset groups
	var water_sand = []
	for i in range(16):
		water_sand.append(tileset.find_tile_by_name("WaterSand_%02d" % i))
	
	var grass = []
	for i in range(16):
		grass.append(tileset.find_tile_by_name("SandGrass_%02d" % i))

	var tree = []
	for i in range(16):
		tree.append(tileset.find_tile_by_name("Tree_%02d" % i))
	
	var grasses = []
	for i in range(1, 9):
		grasses.append(tileset.find_tile_by_name("Grass_%02d" % i))
	
	self.tile_width = tileset.tile_get_region(1).size.x
	self.tile_height = tileset.tile_get_region(1).size.y
	
	basic_perlin_fill(water_sand, grass, tree)
	
	randomise_grass(self.grass_map, grass[15], grasses)

func basic_perlin_fill(water_sand, grass, tree):
	
	var perlinRef = load("res://PerlinRef.gd")
	
	var base = perlinRef.new(wave_width, wave_height, wave_depth, 4)
	var solid = perlinRef.new(wave_width, wave_height, wave_depth, 7, 20)
	var rename_this = perlinRef.new(wave_width, wave_height, wave_depth, 13, 1023)
	
	var image_width = (grid_end_x - grid_start_x + 1) * tile_width
	var image_height = (grid_end_y - grid_start_y + 1) * tile_height
	
	var texture = ImageTexture.new()
	texture.create(image_width, image_height, Image.FORMAT_RGBA)
	var data = Image(image_width, image_height, false, Image.FORMAT_RGBA)
	
	var b1_mid = 0
	var b1_min = b1_mid
	var b1_max = b1_mid
	
	var s1_mid = 0
	var s1_min = s1_mid
	var s1_max = s1_mid
	
	var t1_mid = 0
	var t1_min = t1_mid
	var t1_max = t1_mid
	
	var sand_vertices = []
	var grass_vertices = []
	var tree_vertices = []
	
	# Populate simple boolean grids
	for corner_x in range(grid_start_x, grid_end_x + 1):
		sand_vertices.append([])
		grass_vertices.append([])
		tree_vertices.append([])
		for corner_y in range(grid_start_y, grid_end_y + 1):
			var b1 = base.fractal2d(1, 1, corner_x, corner_y)
			var s1 = solid.fractal2d(1, 1, corner_x, corner_y)
			var t1 = rename_this.fractal2d(1, 1, corner_x, corner_y)
			
			b1_min = min(b1_min, b1)
			b1_max = max(b1_max, b1)
			sand_vertices[corner_x].append(b1)
			
			s1_min = min(s1_min, s1)
			s1_max = max(s1_max, s1)
			grass_vertices[corner_x].append(min(s1, b1))
			
			t1_min = min(t1_min, t1)
			t1_max = max(t1_max, t1)
			tree_vertices[corner_x].append(min(t1, min(s1, b1)))
			
	var b_sparsity = b1_mid
	var s_sparsity = s1_mid
	var t_sparsity = t1_mid + 0.15
	
	for tile_y in range(grid_start_y, grid_end_y):
		for tile_x in range(grid_start_x, grid_end_x):
			var sand_score = get_corner_score(sand_vertices, b_sparsity, tile_x, tile_y)
			var grass_score = get_corner_score(grass_vertices, s_sparsity, tile_x, tile_y)
			var tree_score = get_corner_score(tree_vertices, t_sparsity, tile_x, tile_y)
			
			self.water_sand_map.set_cell(tile_x, tile_y, water_sand[sand_score])
			if (grass_score > 0):
				self.grass_map.set_cell(tile_x, tile_y, grass[grass_score])
			if (tree_score > 0):
				self.tree_map.set_cell(tile_x, tile_y, tree[tree_score])
			
			# Fill debug overlay image
			var shade = sand_vertices[tile_x + 1][tile_y + 1]
			shade = (shade - b1_min) / (b1_max -  b1_min)
			var color =  Color(shade, shade, shade)
			
			var pos_y = tile_y * tile_height
			var pos_x = tile_x * tile_width
			
			for y in range(pos_y, pos_y + tile_height):
				for x in range(pos_x, pos_x + tile_width):
					data.put_pixel(x, y, color)
	
	texture.set_data(data)
	self.debug_sprite.set_pos(Vector2(image_width / 2, image_height / 2))
	self.debug_sprite.set_texture(texture)
	
	print ("b1 - min: ", b1_min, ", max: ", b1_max)
	print ("s1 - min: ", s1_min, ", max: ", s1_max)
	
func get_corner_score(grid, limit, x, y):
	var score = 0
	
	# Bottom right
	if grid[x + 1][y + 1] > limit:
		score += 1 
	
	# Bottom left
	if grid[x][y + 1] > limit:
		score += 2
	
	# Top right
	if grid[x + 1][y] > limit:
		score += 4
	
	# Top left
	if grid[x][y] > limit:
		score += 8
	
	return score

func randomise_grass(tile_map, grass, grasses):
	for y in range(grid_start_y, grid_end_y):
		for x in range(grid_start_x, grid_end_x):
			if grass == tile_map.get_cell(x, y):
				tile_map.set_cell(x, y, grasses[rand_range(0,8)])
