extends Node2D

export (TileSet) var tileset

var chunk_01
var chunk_02

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	var Chunk = load("res://Chunk.gd")
	
	chunk_01 = Chunk.new(Rect2(0, 0, 16, 16), tileset)
	chunk_02 = Chunk.new(Rect2(16, 16, 16, 16), tileset)

	self.add_child(chunk_01, true)
	self.add_child(chunk_02, true)