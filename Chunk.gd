extends Node2D

var resource

var grid_dims

var water_sand_map
var grass_map
var tree_map

var sand_vertices = []
var grass_vertices = []
var tree_vertices = []

var tile_size

func init_map(resourse):
	var map = TileMap.new()
	
	map.set_tileset(resourse.tileset)
	map.set_cell_size(self.tile_size)
	map.set_pos(self.grid_dims.pos * self.tile_size)
	
	self.add_child(map, true)
	
	return map

func _init(var grid_dimensions, var resource):
	self.resource = resource
	
	self.grid_dims = grid_dimensions
	
	self.tile_size = resource.tileset.tile_get_region(1).size

	self.water_sand_map = init_map(resource)
	self.grass_map      = init_map(resource)
	self.tree_map       = init_map(resource)

func generate_content():
	basic_perlin_fill(self.resource)
	randomise_grass(self.grass_map, self.resource.grass[15], self.resource.grasses)

func set_content(chunk_data):
	self.sand_vertices = chunk_data[sand_vertices]
	self.grass_vertices = chunk_data[grass_vertices]
	self.tree_vertices = chunk_data[tree_vertices]
	
	fill_tiles_from_vertices()

func get_save_data():
	var save_data = {
		sand_vertices = self.sand_vertices,
		grass_vertices = self.grass_vertices,
		tree_vertices = self.tree_vertices
	}
	return save_data

func basic_perlin_fill(resource):
	
	var b1_mid = 0
	var b1_min = b1_mid
	var b1_max = b1_mid
	
	# Populate simple boolean grids
	for corner_x in range(self.grid_dims.pos.x, self.grid_dims.end.x + 1):
		self.sand_vertices.append([])
		self.grass_vertices.append([])
		self.tree_vertices.append([])
		for corner_y in range(self.grid_dims.pos.y, self.grid_dims.end.y + 1):
			var b1 = resource.base_fbm.fractal2d(3, 1.2, corner_x, corner_y, 0, 8)
			var s1 = resource.grass_fbm.fractal2d(2, 0.75, corner_x, corner_y, 0, 16)
			var t1 = resource.tree_fbm.fractal2d(1, 1, corner_x, corner_y)
			
			b1_min = min(b1_min, b1)
			b1_max = max(b1_max, b1)
			
			self.sand_vertices[corner_x - self.grid_dims.pos.x].append(b1)
			self.grass_vertices[corner_x - self.grid_dims.pos.x].append(min(s1, b1))
			self.tree_vertices[corner_x - self.grid_dims.pos.x].append(min(t1, min(s1, b1)))
	
	fill_tiles_from_vertices()

func fill_tiles_from_vertices():
	var water_sand = resource.water_sand
	var grass = resource.grass
	var tree = resource.tree
	
	var b_sparsity = 0
	var g_sparsity = 0
	var t_sparsity = 0.15
	
	for tile_y in range(self.grid_dims.size.y):
		for tile_x in range(self.grid_dims.size.x):
			var sand_score = get_corner_score(self.sand_vertices, b_sparsity, tile_x, tile_y)
			var grass_score = get_corner_score(self.grass_vertices, g_sparsity, tile_x, tile_y)
			var tree_score = get_corner_score(self.tree_vertices, t_sparsity, tile_x, tile_y)
			
			self.water_sand_map.set_cell(tile_x, tile_y, water_sand[sand_score])
			if (grass_score > 0):
				self.grass_map.set_cell(tile_x, tile_y, grass[grass_score])
			if (tree_score > 0):
				self.tree_map.set_cell(tile_x, tile_y, tree[tree_score])

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
	for y in range(0, self.grid_dims.size.y):
		for x in range(0, self.grid_dims.size.x):
			if grass == tile_map.get_cell(x, y):
				tile_map.set_cell(x, y, grasses[rand_range(0,8)])
