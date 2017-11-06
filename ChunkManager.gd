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

func get_centered_chunk():
	var center = self.cam.get_camera_screen_center()
	var tiles_center = center / self.tile_size
	
	var vector = Vector2()
	
	vector.x = floor(tiles_center.x / self.resource.chunk_size.x)
	vector.y = floor(tiles_center.y / self.resource.chunk_size.y)
	
	return vector

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

func _fixed_process(delta):
	# Chunk create is less interruptive. but there are 
	# resource issues while not storing out of view chunks
	var chunks_saveable_keys = chunks.keys()
	var center_chunk = get_centered_chunk()
	var chunks_viewable = get_chunks_viewable()
	var rings = max(chunks_viewable.end.x - center_chunk.x, chunks_viewable.end.y - center_chunk.y)
	# Loop around in a "spiral" to list the nearest chunks first
	for ring in range(rings):
		for y in range(center_chunk.y - ring - 1, center_chunk.y + ring + 1):
			for x in range(center_chunk.x - ring - 1, center_chunk.x + ring + 1):
				var chunk_key = Vector2(x, y)
				if (chunks_viewable.has_point(chunk_key)):
					load_keyed_chunk(chunk_key)
					chunks_saveable_keys.erase(chunk_key)
	
	for chunk_key in chunks_saveable_keys:
		save_keyed_chunk(chunk_key)

func load_keyed_chunk(chunk_key):
	if not chunks.has(chunk_key):
		if queue_chunk(chunk_key):
			var new_chunk = is_ready(chunk_key)
			if (new_chunk):
				new_chunk.set_name(str(chunk_key))
				self.add_child(new_chunk, true)
				chunks[chunk_key] = new_chunk

func save_keyed_chunk(chunk_key):
	# TODO: We don't actually save yet, just remove from the tree
	if chunks.has(chunk_key):
		var old_chunk = chunks[chunk_key]
		chunks.erase(chunk_key)
		old_chunk.queue_free()

const once_per = 0.1250

func chunk_generation(u):
	print("start chunk checker")
	
	var next_time = OS.get_unix_time() + once_per
	while true:
		if next_time < OS.get_unix_time() and mutex.try_lock() == OK:
			next_time += once_per
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