extends Node2D

export (TileSet) var tileset
export (Vector2) var chunk_size

var Chunk = load("res://Chunk.gd")

var chunk_01
var chunk_02

var chunks = {}

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
	
	var tiles_viewable = get_tiles_viewable()
	var chunks_viewable = get_chunks_viewable()
	update_chunks()
	
	var new_time = self.acc_time + delta
	self.per_sec += 1
	
	if (floor(self.acc_time) < floor(new_time)):
		# Once per second
		print ("[", new_time, "; ", per_sec, "] tiles_viewable: ", tiles_viewable.pos, ", ", tiles_viewable.end)
		print ("[", new_time, "; ", per_sec, "] chunks_viewable: ", chunks_viewable.pos, ", ", chunks_viewable.end)
		update_chunks()
		self.per_sec = 0
		
	self.acc_time = new_time

func get_tiles_viewable():
	var center = self.cam.get_camera_screen_center()
	var screen = get_viewport().get_rect().size
	var zoom = self.cam.get_zoom()
	var tiles_per_screen = screen * zoom / self.tile_size
	var tiles_center = center / self.tile_size
	var tiles_viewable = Rect2(tiles_center - (tiles_per_screen / 2), tiles_per_screen)
	
	return tiles_viewable

func get_chunks_viewable():
	var tiles_viewable = get_tiles_viewable()
	var rect = Rect2()
	
	rect.pos.x = floor(tiles_viewable.pos.x / self.chunk_size.x)
	rect.pos.y = floor(tiles_viewable.pos.y / self.chunk_size.y)
	rect.end.x = floor(tiles_viewable.end.x / self.chunk_size.x)
	rect.end.y = floor(tiles_viewable.end.y / self.chunk_size.y)
	
	return rect

func update_chunks():
	# Currently, how this is run is a bit slow, 
	# need to look into pre-loading on a separate thread
	var chunks_viewable = get_chunks_viewable()
	for y in range(chunks_viewable.pos.y, chunks_viewable.end.y + 1):
		for x in range(chunks_viewable.pos.x, chunks_viewable.end.x + 1):
			var chunk_key = "x" + str(x) + "y" + str(y) 
			if not chunks.has(chunk_key):
				var new_pos = Vector2(self.chunk_size.x * x, self.chunk_size.y * y)
				var new_chunk = Chunk.new(Rect2(new_pos, self.chunk_size), self.tileset)
				self.add_child(new_chunk, true)
				chunks[chunk_key] = new_chunk
	