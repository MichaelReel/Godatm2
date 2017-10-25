extends Camera2D

# Member variables
const MOTION_SPEED = 160 # Pixels/seconds
const ZOOM_SPEED = 1.1 # 

var mouse_pos = Vector2()
var drag = false

func _ready():
	set_fixed_process(true)

func _fixed_process(delta):
	var motion = Vector2()
	
	# Address key movement
	if (Input.is_action_pressed("move_up")):
		motion += Vector2(0, -1)
	if (Input.is_action_pressed("move_down")):
		motion += Vector2(0, 1)
	if (Input.is_action_pressed("move_left")):
		motion += Vector2(-1, 0)
	if (Input.is_action_pressed("move_right")):
		motion += Vector2(1, 0)
	motion = motion.normalized() * MOTION_SPEED * delta
	
	# Address mouse movement
	var new_mouse_pos = self.mouse_pos
	if (Input.is_mouse_button_pressed(BUTTON_LEFT)):
		if drag:
			new_mouse_pos = get_viewport().get_mouse_pos()
			motion -= (new_mouse_pos - self.mouse_pos) * get_zoom()
			self.mouse_pos = new_mouse_pos
		else:
			self.mouse_pos = get_viewport().get_mouse_pos()
			drag = true
	else:
		drag = false
	
	# Perform movement
	translate(motion)
	
	# Do zooming
	if Input.is_action_pressed("zoom_in") or Input.is_mouse_button_pressed(BUTTON_WHEEL_UP):
		set_zoom(get_zoom() * 1 / ZOOM_SPEED)
	if Input.is_action_pressed("zoom_out"):
		set_zoom(get_zoom() * ZOOM_SPEED)

# Need this in an input handler?
#func _input(event):
#	if (event.button_index == BUTTON_WHEEL_UP):
#		print("wheel up (event)")
#		set_zoom(get_zoom() * 1 / ZOOM_SPEED)
#	if (event.button_index == BUTTON_WHEEL_DOWN):
#		print("wheel down (event)")
#		set_zoom(get_zoom() * ZOOM_SPEED)