extends Node2D

export (TileSet) var tileset
export (Vector2) var chunk_size

var Chunk = load("res://Chunk.gd")

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

func _fixed_process(delta):
	update_chunks()

func get_chunks_viewable():
	var center = self.cam.get_camera_screen_center()
	var screen = get_viewport().get_rect().size
	var zoom = self.cam.get_zoom()
	var tiles_per_screen = screen * zoom / self.tile_size
	var tiles_center = center / self.tile_size
	var tiles_viewable = Rect2(tiles_center - (tiles_per_screen / 2), tiles_per_screen)
	
	var rect = Rect2()
	
	rect.pos.x = floor(tiles_viewable.pos.x / self.chunk_size.x)
	rect.pos.y = floor(tiles_viewable.pos.y / self.chunk_size.y)
	rect.end.x = floor(tiles_viewable.end.x / self.chunk_size.x) + 1
	rect.end.y = floor(tiles_viewable.end.y / self.chunk_size.y) + 1
	
	return rect

func update_chunks():
	# Currently this runs a bit slow, especially zoomed out
	# need to look into pre-loading on a separate thread
	# clearly "call_deferred" isn't used correctly here or isn't sufficient
	var chunks_viewable = get_chunks_viewable()
	for y in range(chunks_viewable.pos.y - 1, chunks_viewable.end.y + 1):
		for x in range(chunks_viewable.pos.x - 1, chunks_viewable.end.x + 1):
			call_deferred("update_keyed_chunk", x, y)

func update_keyed_chunk(x, y):
	var chunk_key = Vector2(x, y) 
	if not chunks.has(chunk_key):
		var new_pos = Vector2(self.chunk_size.x * x, self.chunk_size.y * y)
		var new_chunk = Chunk.new(Rect2(new_pos, self.chunk_size), self.tileset)
		self.add_child(new_chunk, true)
		chunks[chunk_key] = new_chunk
	