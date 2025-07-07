extends Control

var car

func setcar():
	car = get_parent().get_node(get_parent().car)

func _ready():
	setcar()
	for i in $scroll/container.get_children():
		if i.var_name == "GEAR_ASSIST":
			i.value = car.Shift_Assistance
			i.get_node("amount").text = str(int(i.value))
		else:
			if i.get_class() == "HSlider":
				i.value = car.get(i.var_name)
				i.get_node("amount").text = str(i.value)
			else:
				i.pressed = car.get(i.var_name)
				i.get_node("amount").text = str(i.pressed)

func _process(delta):
	if not get_parent().car == "":
		for i in $scroll/container.get_children():
			if i.var_name == "GEAR_ASSIST":
				car.Shift_Assistance = int(i.value)
				i.get_node("amount").text = str(int(i.value))
			else:
				if i.get_class() == "HSlider":
					car.set(i.var_name, i.value)
					i.get_node("amount").text = str(i.value)
				else:
					car.set(i.var_name,i.pressed)
					i.get_node("amount").text = str(i.pressed)

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		visible = false


func _on_Button_pressed():
	get_parent().get_node("open controls").release_focus()
	if visible:
		visible = false
	else:
		Input.action_press("ui_cancel")
		yield(get_tree().create_timer(0.1), "timeout")
		Input.action_release("ui_cancel")
		visible = true
