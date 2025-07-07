extends Control

var changed_graph_size = Vector2(0,0)
export(NodePath) var car

func _ready():
	pass

func _process(delta):
	if delta>0:
		get_node("container/fps").text = "fps: "+str(1.0/delta)
		if has_node(car):
			$sw.rect_rotation = get_node(car).steer*380.0
			$sw_desired.rect_rotation = get_node(car).steer2*380.0
			if get_node(car).Debug_Mode:
				get_node("container/weight_dist").text = "weight distribution: F%f/R%f" % [get_node(car).weight_dist[0]*100,get_node(car).weight_dist[1]*100]
			else:
				get_node("container/weight_dist").text = "[ enable Debug_Mode or press F to\nfetch weight distribution ]"

	if not car == "":
		
		$throttle.scale = get_node(car).gaspedal
		$brake.scale = get_node(car).brakepedal
		$handbrake.scale = get_node(car).handbrakepull
		$clutch.scale = get_node(car).clutchpedalreal
		
		$tacho/speedk.text = "KM/PH: " +str(int(get_node(car).linear_velocity.length()*1.10130592))
		$tacho/speedm.text = "MPH: " +str(int((get_node(car).linear_velocity.length()*1.10130592)/1.609 ) )
		
		
		
		$g.text = "Gs:\nx%s,\ny%s,\nz%s" % [str(int(get_node(car).gforce.x*100.0)/100.0),str(int(get_node(car).gforce.y*100.0)/100.0),str(int(get_node(car).gforce.z*100.0)/100.0)]

		$tacho.currentpsi = get_node(car).turbopsi*(get_node(car).Turbo_Amount)
		$tacho.currentrpm = get_node(car).rpm
		$tacho/rpm.text = str(int(get_node(car).rpm))
		
		if get_node(car).rpm<0:
			$tacho/rpm.self_modulate = Color(1,0,0)
		else:
			$tacho/rpm.self_modulate = Color(1,1,1)
		
		if get_node(car).gear == 0:
			$tacho/gear.text = "N"
		elif get_node(car).gear == -1:
			$tacho/gear.text = "R"
		else:
			$tacho/gear.text = str(get_node(car).gear)
			
func _physics_process(delta):
	if not car == "":
		$vgs.gforce -= ($vgs.gforce - Vector2(get_node(car).gforce.x,get_node(car).gforce.z))*0.5
		
func toggle_forces():
	Input.action_press("toggle_debug_mode")
