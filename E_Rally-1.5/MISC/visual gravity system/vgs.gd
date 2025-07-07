extends Control

export var Scale = 1.0
export var MaxG = 0.75

export var gforce = Vector2(0,0)

var glength = 0.0

	
func _physics_process(delta):
	

	glength = Vector2(abs(gforce.x),abs(gforce.y)).length()/Scale -1.0
	if Vector2(abs(gforce.x),abs(gforce.y)).length()>MaxG:
		$centre/Circle.modulate = Color(1.0,1.0,0.5,1.0)
	else:
		$centre/Circle.modulate = Color(1.0,0.75,0.0,1.0)

	if glength<0.0:
		glength = 0.0
	
	gforce /= glength +1.0
	
	$centre.position = rect_size/2 +gforce*(64.0/Scale)
	$field.position = rect_size/2
	
