extends Node2D

export var gridSize = Vector2()
export (TileSet) var tileset

const BASE_TILE_MAP = 0
const SOLID_TILE_MAP = 1
const PROC_DEBUG_SPRITE = 2

var grid_start_x
var grid_start_y
var grid_end_x
var grid_end_y
var tile_maps

var tile_width
var tile_height

func _ready():
	
	self.grid_start_x = 0
	self.grid_start_y = 0
	self.grid_end_x = int(gridSize.x)
	self.grid_end_y = int(gridSize.y)
	
	self.tile_maps = self.get_children()
	
	var basemap = tile_maps[BASE_TILE_MAP]
	var solidmap = tile_maps[SOLID_TILE_MAP]
	
	var edgeTool = load("res://MarchingSquares.gd").new(grid_end_x, grid_end_y)
	
	# Index tileset groups
	var water_sand = []
	for i in range(16):
		water_sand.append(tileset.find_tile_by_name("WaterSand_%02d" % i))
	
	var water_grass = []
	for i in range(16):
		water_grass.append(tileset.find_tile_by_name("WaterGrass_%02d" % i))
	
	var sand_grass = []
	for i in range(16):
		sand_grass.append(tileset.find_tile_by_name("SandGrass_%02d" % i))

	var tree_edge = []
	for i in range(16):
		tree_edge.append(tileset.find_tile_by_name("Tree_%02d" % i))
	
	var grasses = []
	for i in range(1, 9):
		grasses.append(tileset.find_tile_by_name("Grass_%02d" % i))
	
	# Select primary file tiles
	var water = water_sand[0]
	var sand = sand_grass[0]
	var grass = grasses[0]
	var tree = tree_edge[0]
	var empty = -1
	
	self.tile_width = tileset.tile_get_region(water).size.x
	self.tile_height = tileset.tile_get_region(water).size.y
	
	# print (self.tile_width, ", ", self.tile_height)
	# print (water, ", ", grass, ", ", tree, ", ", empty)
	
	basic_perlin_fill(tile_maps, grass, sand, water, tree)
	
	# edgeTool.simple_marching_squares(basemap, water_grass, grasses)
	
	edgeTool.simple_marching_squares(basemap, water_sand, [sand, grass])
	
	edgeTool.simple_marching_squares(basemap, sand_grass, [grass])
	
	edgeTool.simple_marching_squares(solidmap, tree_edge, [empty], true)
	
	randomise_grass(basemap, grass, grasses)

func basic_perlin_fill(tile_maps, grass, sand, water, tree):
	
	var basemap = tile_maps[BASE_TILE_MAP]
	var solidmap = tile_maps[SOLID_TILE_MAP]
	var debug = tile_maps[PROC_DEBUG_SPRITE]
	
	var perlinRef = load("res://PerlinRef.gd")
	
	var base = perlinRef.new(64, 64, 64, 4)
	var solid = perlinRef.new(64, 64, 64, 7, 20)
	
	var image_width = (grid_end_x - grid_start_x) * tile_width
	var image_height = (grid_end_y - grid_start_y) * tile_height
	
	var texture = ImageTexture.new()
	texture.create(image_width, image_height, Image.FORMAT_RGBA)
	var data = Image(image_width, image_height, false, Image.FORMAT_RGBA)
	
	var b1_mid = 0.5
	var b1_min = b1_mid
	var b1_max = b1_mid
	
	var s1_mid = 0
	var s1_min = s1_mid
	var s1_max = s1_mid
	
	for tile_y in range(grid_start_y, grid_end_y):
		for tile_x in range(grid_start_x, grid_end_x):
			var b1 = base.fractal2d(2, 1, tile_x, tile_y) + b1_mid
			var s1 = solid.fractal2d(1, 1, tile_x, tile_y) + s1_mid
			
			var color = Color(s1, s1, s1)
			
			b1_min = min(b1_min, b1)
			b1_max = max(b1_max, b1)
			
			s1_min = min(s1_min, s1)
			s1_max = max(s1_max, s1)
			
			# Choose tiles
			if b1 <= b1_mid:
				basemap.set_cell(tile_x, tile_y, water)
			elif s1 < s1_mid - 0.11:
				 basemap.set_cell(tile_x, tile_y, sand)
			else:
				basemap.set_cell(tile_x, tile_y, grass)
				if s1 > s1_mid + 0.11:
					solidmap.set_cell(tile_x, tile_y, tree)
			
			# Fill debug overlay image
			var color = Color(b1, b1, b1, 1)
			var pos_y = tile_y * tile_height
			var pos_x = tile_x * tile_width
			
			for y in range(pos_y, pos_y + tile_height):
				for x in range(pos_x, pos_x + tile_width):
					data.put_pixel(x, y, color)
	
	texture.set_data(data)
	debug.set_pos(Vector2(image_width / 2, image_height / 2))
	debug.set_texture(texture)
	
	print ("b1 - min: ", b1_min, ", max: ", b1_max)
	print ("s1 - min: ", s1_min, ", max: ", s1_max)

func randomise_grass(tile_map, grass, grasses):
	for y in range(grid_start_y, grid_end_y):
		for x in range(grid_start_x, grid_end_x):
			if grass == tile_map.get_cell(x, y):
				tile_map.set_cell(x, y, grasses[rand_range(0,8)])
