extends Node2D

# Attempting to use this as a means to group some 
# resources to get FSB results and tiles

export (TileSet) var tileset
export (Vector2) var chunk_size

const wave_width = 32
const wave_height = 32
const wave_depth = 1

var perlinRef = load("res://PerlinRef.gd")

var water_sand
var grass
var tree
var grasses
var base_fbm
var grass_fbm
var tree_fbm

func _ready():
	self.water_sand = []
	for i in range(16):
		self.water_sand.append(self.tileset.find_tile_by_name("WaterSand_%02d" % i))
	
	self.grass = []
	for i in range(16):
		self.grass.append(self.tileset.find_tile_by_name("SandGrass_%02d" % i))

	self.tree = []
	for i in range(16):
		self.tree.append(self.tileset.find_tile_by_name("Tree_%02d" % i))
	
	self.grasses = []
	for i in range(1, 9):
		self.grasses.append(self.tileset.find_tile_by_name("Grass_%02d" % i))

	self.base_fbm = self.perlinRef.new(wave_width, wave_height, wave_depth, 4)
	self.grass_fbm = self.perlinRef.new(wave_width, wave_height, wave_depth, 7, 20)
	self.tree_fbm = self.perlinRef.new(wave_width, wave_height, wave_depth, 13, 1023)