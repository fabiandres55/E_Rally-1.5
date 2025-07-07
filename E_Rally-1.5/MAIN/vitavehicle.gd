tool
extends Node

static func fastest_wheel(array):
	var val = -10000000000000000000000000000000000.0
	var obj
	
	for i in array:
		val = max(val, abs(i.absolute_wv))
		
		if val == abs(i.absolute_wv):
			obj = i

	return obj

static func slowest_wheel(array):
	var val = 10000000000000000000000000000000000.0
	var obj
	
	for i in array:
		val = min(val, abs(i.absolute_wv))
		
		if val == abs(i.absolute_wv):
			obj = i

	return obj

static func alignAxisToVector(xform, norm): # i named this literally out of blender
	xform.basis.y = norm
	xform.basis.x = -xform.basis.z.cross(norm)
	xform.basis = xform.basis.orthonormalized()
	return xform

func suspension(own,rest,      elasticity,damping,damping_rebound     ,linearz,g_range,located,hit_located,weight,ground_bump,ground_bump_height):
	own.get_node("geometry").global_translation = own.get_collision_point()
	own.get_node("geometry").translation.y -= (ground_bump*ground_bump_height)
	if own.get_node("geometry").translation.y<-g_range:
		own.get_node("geometry").translation.y = -g_range
	own.get_node("velocity").global_transform = alignAxisToVector(own.get_node("velocity").global_transform,own.get_collision_normal())
	own.get_node("velocity2").global_transform = alignAxisToVector(own.get_node("velocity2").global_transform,own.get_collision_normal())

	own.angle = (own.get_node("geometry").rotation_degrees.z -(-own.c_camber*float(own.translation.x>0.0) + own.c_camber*float(own.translation.x<0.0)) )/90.0

	var damp_variant = damping_rebound
	if linearz<0:
		 damp_variant = damping

	var compressed = g_range -(located - hit_located).length() - (ground_bump*ground_bump_height)

	var j = compressed-rest
	
	if j<0.0:
		 j = 0.0

	var elasticity2 = elasticity
	var damping2 = damp_variant
	var elasticity3 = weight
	var damping3 = weight/10.0
	var suspforce = j*elasticity2

	suspforce -= linearz*damping2

	own.rd = compressed

	if suspforce<0.0:
		suspforce = 0.0

	return suspforce

