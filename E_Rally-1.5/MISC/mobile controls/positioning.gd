extends TouchScreenButton

onready var default_pos = position/get_parent().base_resolution
onready var default_size = scale/get_parent().base_resolution


func _process(delta):
	position = default_pos*OS.get_real_window_size()
	scale = default_size*OS.get_real_window_size()


func press(state):
	if state:
		Input.action_press(name)
	else:
		Input.action_release(name)
