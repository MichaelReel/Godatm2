extends Node2D

var Chunk = load("res://Chunk.gd")

var chunks = {}

var resource
var tile_size
var cam

var queue = []
var pending = {}

var thread
var mutex

func _ready():
	print("readying chunk manager")
	set_fixed_process(true)
	
	self.resource = find_node("Resource", false)
	self.cam = find_node("Camera2D", false)
	self.tile_size = self.resource.tileset.tile_get_region(1).size
	
	mutex = Mutex.new()
	thread = Thread.new()
	thread.start(self, "chunk_generation", 0)

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
	
	rect.pos.x = floor(tiles_viewable.pos.x / self.resource.chunk_size.x)
	rect.pos.y = floor(tiles_viewable.pos.y / self.resource.chunk_size.y)
	rect.end.x = floor(tiles_viewable.end.x / self.resource.chunk_size.x) + 1
	rect.end.y = floor(tiles_viewable.end.y / self.resource.chunk_size.y) + 1
	
	return rect

func update_chunks():
	# Chunk create is less interruptive. but there are 
	# resource issues while not storing out of view chunks
	var chunks_viewable = get_chunks_viewable()
	for y in range(chunks_viewable.pos.y - 1, chunks_viewable.end.y + 1):
		for x in range(chunks_viewable.pos.x - 1, chunks_viewable.end.x + 1):
			update_keyed_chunk(x, y)

func update_keyed_chunk(x, y):
	var chunk_key = Vector2(x, y)
	if not chunks.has(chunk_key):
		if queue_chunk(chunk_key):
			var new_chunk = is_ready(chunk_key)
			if (new_chunk):
				self.add_child(new_chunk, true)
				chunks[chunk_key] = new_chunk

func chunk_generation(u):
	print("start chunk checker")
	while true:
		if mutex.try_lock() == OK:
			chunk_loader()
			mutex.unlock()

func chunk_loader():
	if queue.size() > 0:
		var chunk_key = queue[0]
		var new_pos = Vector2(self.resource.chunk_size.x * chunk_key.x, self.resource.chunk_size.y * chunk_key.y)
		var new_chunk = Chunk.new(Rect2(new_pos, self.resource.chunk_size), self.resource)
		pending[chunk_key] = new_chunk
		queue.erase(chunk_key)

func queue_chunk(var chunk_key):
	var already_queued = true
	if mutex.try_lock() == OK:
		if not (chunk_key in pending or chunk_key in queue):
			already_queued = false
			queue.push_back(chunk_key)
		mutex.unlock()
	return already_queued

func is_ready(chunk_key):
	var chunk = false
	if mutex.try_lock() == OK:
		if chunk_key in pending:
			chunk = pending[chunk_key]
			pending.erase(chunk_key)
		mutex.unlock()
	return chunk