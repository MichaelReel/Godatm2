extends Node2D

export (TileSet) var tileset
export (Vector2) var chunk_size

var Chunk = load("res://Chunk.gd")

var chunk_01
var chunk_02

var tile_size
var cam

var acc_time = 0 # Accumulated time (not real time)
var per_sec = 0  # Times that _fixed_process was called in the last accumulated second

func _ready():
	set_fixed_process(true)
	
	self.tile_size = tileset.tile_get_region(1).size
	self.cam = find_node("Camera2D", false)
	
	print (self.cam)
	
	chunk_01 = Chunk.new(Rect2(Vector2(0, 0), chunk_size), tileset)
	chunk_02 = Chunk.new(Rect2(chunk_size, chunk_size), tileset)

	self.add_child(chunk_01, true)
	self.add_child(chunk_02, true)

func _fixed_process(delta):
	
	var center = self.cam.get_camera_screen_center()
	var screen = get_viewport().get_rect().size
	var zoom = self.cam.get_zoom()
	var tiles_per_screen = screen * zoom / self.tile_size
	var tiles_center = center / self.tile_size
	var tiles_viewable = Rect2(tiles_center - (tiles_per_screen / 2), tiles_per_screen)
	
	var new_time = self.acc_time + delta
	self.per_sec += 1
	
	if (floor(self.acc_time) < floor(new_time)):
		# Once per second
		print ("[", new_time, "; ", per_sec, "] tiles_viewable: ", tiles_viewable.pos, ", ", tiles_viewable.end)
		print ("[", new_time, "; ", per_sec, "] zoom: ", self.cam.get_zoom())
		self.per_sec = 0
		
	self.acc_time = new_time

