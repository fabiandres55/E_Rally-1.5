extends RayCast

export var Differed_Wheel = ""

export var Wheel_Margin = 1.0

export var Left_Max_Steer_Angle = 0.0
export var Right_Max_Steer_Angle = 0.0
export var Grip = 1.0
export var Static_Grip = 0.0
export var Grip_Stiffness = 3.0
export var Grip_Deform = 1.0

export var Camber = 0.0
export var Caster = 0.0
export var Toe = 0.0

export var Power_Bias = 1.0

export var S_Stiffness = 55.0
export var S_Damping = 4.0
export var S_ReboundDamping = 4.0
export var S_RestLength = 0.0
export var Lateral_Roll_Influence = 0.0
export var Longitudinal_Roll_Influence = 0.0


export var Brake_Torque = 15.0
export var Brake_Bias = 1.0
export var Brake_Saturation = 1.0 # leave this at 1.0 unless you have a heavy vehicle with large wheels, set it higher depending on how big it is
export var Handbrake_Bias = 0.0


onready var car = get_parent()

var dist = 0.0
var w_size = 1.0
var w_size_read = 1.0
var w_weight_read = 0.0
var w_weight = 0.0
var wv = 0.0
var wv_ds = 0.0
var wv_diff = 0.0
var c_tp = 0.0
var effectiveness = 0.0

var angle = 0.0
var snap = 0.0
var absolute_wv = 0.0
var absolute_wv_brake = 0.0
var absolute_wv_diff = 0.0
var output_wv = 0.0
var offset = 0.0
var c_p = 0.0
var wheelpower = 0.0
var wheelpower_global = 0.0
var stress = 0.0
var rolldist = 0.0
var rd = 0.0
var c_camber = 0.0
var cambered = 0.0

var rollvol = 0.0
var sl = 0.0
var skvol = 0.0
var skvol_d = 0.0
var velocity = Vector3(0,0,0)
var velocity2 = Vector3(0,0,0)
var compress = 0.0
var compensate = 0.0
var axle_position = 0.0

var heat_rate = 1.0
var wear_rate = 1.0

var ground_bump = 0.0
var ground_bump_up = false
var ground_bump_frequency = 0.0
var ground_bump_frequency_random = 1.0
var ground_bump_height = 0.0

var ground_friction = 1.0
var ground_stiffness = 1.0
var fore_friction = 0.0
var fore_stiffness = 0.0
var drag = 0.0
var ground_builduprate = 0.0
var ground_dirt = false
var hitposition = Vector3(0,0,0)

var cache_tyrestiffness = 0.0
var cache_friction_action = 0.0

func power():
	if not c_p == 0:
		dist *= (car.clutchpedal*car.clutchpedal)/(car.currentstable)
		var dist_cache = dist
		
		var tol = car.clutchgrip/10.0

		if dist_cache>tol:
			dist_cache = tol
		elif dist_cache<-tol:
			dist_cache = -tol
		
		var dist2 = dist_cache

		car.dsweight += c_p
		car.stress += stress*c_p
		
		if car.dsweightrun>0.0:
			wheelpower -= (((dist2/car.ds_weight)/(car.dsweightrun/2.5))*c_p)/w_weight
			car.resistance += (((dist_cache*(10.0))/car.dsweightrun)*c_p)

func diffs():
	if car.locked>0.0:
		if not Differed_Wheel == "":
			var d_w = car.get_node(Differed_Wheel)
			snap = abs(d_w.wheelpower_global)/(car.locked*16.0) +1.0
			absolute_wv = output_wv+(offset*snap)
			var distanced2 = abs(absolute_wv - d_w.absolute_wv_diff)/(car.locked*16.0)
			distanced2 += abs(d_w.wheelpower_global)/(car.locked*16.0)
			if distanced2<snap:
				distanced2 = snap
			distanced2 += 1.0/cache_tyrestiffness
			if distanced2>0.0:
				wheelpower += -((absolute_wv_diff - d_w.absolute_wv_diff)/distanced2)

var directional_force = Vector3(0,0,0)
var slip_perc = Vector2(0,0)
var slip_perc2 = 0.0
var slip_percpre = 0.0

var velocity_last = Vector3(0,0,0)
var velocity2_last = Vector3(0,0,0)

func _physics_process(_delta):
	var last_translation = translation
	
	if Power_Bias>0:
		get_parent().c_pws.append(self)

	var sr = Left_Max_Steer_Angle*car.steer
	
	if car.steer>0:
		sr = Right_Max_Steer_Angle*car.steer

	rotation_degrees = Vector3(0,-((Toe*(float(translation.x>0)) -Toe*float(translation.x<0))) -sr,0)

	translation = last_translation

	c_camber = Camber +Caster*rotation.y*float(translation.x>0.0) -Caster*rotation.y*float(translation.x<0.0)

	directional_force = Vector3(0,0,0)
	
	$velocity.translation = Vector3(0,0,0)

	
	w_size = Wheel_Margin
	w_weight = pow(w_size,2.0)
	
	w_size_read = w_size
	if w_size_read<1.0:
		w_size_read = 1.0
	if w_weight_read<1.0:
		w_weight_read = 1.0
	
	$velocity2.global_transform.origin = $geometry.global_transform.origin

	$velocity/step.global_transform.origin = velocity_last
	$velocity2/step.global_transform.origin = velocity2_last
	velocity_last = $velocity.global_transform.origin
	velocity2_last = $velocity2.global_transform.origin
	
	velocity = -$velocity/step.translation*60.0
	velocity2 = -$velocity2/step.translation*60.0

	$velocity.rotation = Vector3(0,0,0)
	$velocity2.rotation = Vector3(0,0,0)

	# VARS
	var elasticity = S_Stiffness
	var damping = S_Damping
	var damping_rebound = S_ReboundDamping
	
	if elasticity<0.0:
		elasticity = 0.0
		
	if damping<0.0:
		damping = 0.0
		
	if damping_rebound<0.0:
		damping_rebound = 0.0

	var tyre_maxgrip = Grip


	var tyre_stiffness = Grip_Stiffness

	var deviding = (Vector2(velocity.x,velocity.z).length()/50.0 +0.5)*Grip_Deform

	deviding /= ground_stiffness +fore_stiffness
	if deviding<1.0:
		deviding = 1.0
	tyre_stiffness /= deviding
	
	if tyre_stiffness<1.0:
		 tyre_stiffness = 1.0

	cache_tyrestiffness = tyre_stiffness
		
	absolute_wv = output_wv+(offset*snap) -compensate*1.15296
	absolute_wv_brake = output_wv+((offset/w_size_read)*snap) -compensate*1.15296
	absolute_wv_diff = output_wv
	
	wheelpower = 0.0

	var braked = car.brakeline*Brake_Bias + car.handbrakepull*Handbrake_Bias
	if braked>1.0:
		braked = 1.0
	var bp = (Brake_Torque*braked)/w_weight_read

	if not car.actualgear == 0:
		if car.dsweightrun>0.0:
			bp += ((car.stalled*(c_p/car.ds_weight))*car.clutchpedal)*(((500.0/(1.0*100.0))/(car.dsweightrun/2.5))/w_weight_read)
	if bp>0.0:
		if abs(absolute_wv)>0.0:
			var distanced = abs(absolute_wv)/bp
			distanced -= car.brakeline
			if distanced<snap*(w_size_read/Brake_Saturation):
				distanced = snap*(w_size_read/Brake_Saturation)
			wheelpower += -absolute_wv/distanced
		else:
			wheelpower += -absolute_wv

	wheelpower_global = wheelpower
	
	power()
	diffs()

	snap = 1.0
	offset = 0.0

	# WHEEL
	if is_colliding():
#		if "drag" in get_collider():
#			drag = get_collider().get("drag")*CompoundSettings["GroundDragAffection"]*CompoundSettings["GroundDragAffection"]
#		if "ground_friction" in get_collider():
#			ground_friction = get_collider().get("ground_friction")
#		if "fore_friction" in get_collider():
#			fore_friction = get_collider().get("fore_friction")
#		if "ground_stiffness" in get_collider():
#			ground_stiffness = get_collider().get("ground_stiffness")
#		if "fore_stiffness" in get_collider():
#			fore_stiffness = get_collider().get("fore_stiffness")
#		if "ground_builduprate" in get_collider():
#			ground_builduprate = get_collider().get("ground_builduprate")*CompoundSettings["BuildupAffection"]
#		if "ground_dirt" in get_collider():
#			ground_dirt = get_collider().get("ground_dirt")
#		if "ground_bump_frequency" in get_collider():
#			ground_bump_frequency = get_collider().get("ground_bump_frequency")
#		if "ground_bump_frequency_random" in get_collider():
#			ground_bump_frequency_random = get_collider().get("ground_bump_frequency_random") +1.0
#		if "ground_bump_height" in get_collider():
#			ground_bump_height = get_collider().get("ground_bump_height")
#		if "wear_rate" in get_collider():
#			wear_rate = get_collider().get("wear_rate")
#		if "heat_rate" in get_collider():
#			heat_rate = get_collider().get("heat_rate")
		if ground_bump_up:
			ground_bump -= rand_range(ground_bump_frequency/ground_bump_frequency_random,ground_bump_frequency*ground_bump_frequency_random)*(velocity.length()/1000.0)
			if ground_bump<0.0:
				ground_bump = 0.0
				ground_bump_up = false
		else:         
			ground_bump += rand_range(ground_bump_frequency/ground_bump_frequency_random,ground_bump_frequency*ground_bump_frequency_random)*(velocity.length()/1000.0)
			if ground_bump>1.0:
				ground_bump = 1.0
				ground_bump_up = true

		var suspforce = VitaVehicleSimulation.suspension(self,S_RestLength, elasticity,damping,damping_rebound, velocity.y,abs(cast_to.y),global_transform.origin,get_collision_point(),car.mass,ground_bump,ground_bump_height)
		compress = suspforce

		# FRICTION
		var grip = (suspforce*tyre_maxgrip) +Static_Grip
		stress = grip
		var rigidity = 0.67

		var distw = velocity2.z - wv*w_size
		wv += (wheelpower*(1.0-(1.0/tyre_stiffness)))
		var disty = velocity2.z - wv*w_size

		offset = disty/w_size
		if offset>grip:
			offset = grip
		elif offset<-grip:
			offset = -grip

		var distx = velocity2.x

		var compensate2 = suspforce
		var grav_incline = $geometry.global_transform.basis.orthonormalized().xform_inv(Vector3(0,1,0)).x
		var grav_incline2 = $geometry.global_transform.basis.orthonormalized().xform_inv(Vector3(0,1,0)).z
		
		compensate = grav_incline2*(compensate2/tyre_stiffness)
		
		distx -= (grav_incline*(compensate2/tyre_stiffness))*1.1

		disty *= tyre_stiffness
		distw *= tyre_stiffness
		distx *= tyre_stiffness

		distx -= atan2(abs(wv),1.0)*((angle*10.0)*w_size)

		if grip>0:

			var slip = sqrt(pow(abs(disty),2.0) + pow(abs(distx),2.0))/grip
			
			slip_percpre = slip/tyre_stiffness
			
			slip /= slip*ground_builduprate +1
			slip -= 1.0
			if slip<0:
				slip = 0

			var slip_sk = sqrt(pow(abs(disty),2.0) + pow(abs((distx)*2.0),2.0))/grip
			slip_sk /= slip*ground_builduprate +1
			slip_sk -= 1.0
			if slip_sk<0:
				slip_sk = 0


			var slipw = sqrt(pow(abs(0.0),2.0) + pow(abs(distx),2.0))/grip
			slipw /= slipw*ground_builduprate +1.0
			var forcey = -disty/(slip +1.0)
			var forcex = -distx/(slip +1.0)

			var yesx = abs(forcex)
			if yesx>1.0:
				yesx = 1.0
			var smoothx = yesx*yesx
			if smoothx>1.0:
				smoothx = 1.0
			var yesy = abs(forcey)
			if yesy>1.0:
				yesy = 1.0
			var smoothy = yesy*1.0
			if smoothy>1.0:
				smoothy = 1.0
			forcex /= (smoothx*(rigidity) +(1.0-rigidity))
			forcey /= (smoothy*(rigidity) +(1.0-rigidity))
				
			var distyw = sqrt(pow(abs(disty),2.0) + pow(abs(distx),2.0))
			var tr = (grip/tyre_stiffness)
			var afg = tyre_stiffness*tr
			distyw /= 1.0
			if distyw<afg:
				distyw = afg
				
			var ok = ((distyw/tyre_stiffness)/grip)/w_size
			
			if ok>1.0:
				ok = 1.0
				
			snap = ok*w_weight_read
			if snap>1.0:
				snap = 1.0
			
			wv -= forcey*ok
			
			cache_friction_action = forcey*ok
			
			wv += (wheelpower*(1.0/tyre_stiffness))

			rollvol = velocity.length()*grip

			sl = slip_sk-tyre_stiffness
			if sl<0.0:
				sl = 0.0
			skvol = sl/4.0
			
#			skvol *= skvol

			skvol_d = slip*25.0
	else:
		wv += wheelpower
		stress = 0.0
		rollvol = 0.0
		sl = 0.0
		skvol = 0.0
		skvol_d = 0.0
		compress = 0.0
		compensate = 0.0
	
	slip_perc = Vector2(0,0)
	slip_perc2 = 0.0
	
	wv_diff = wv
	# FORCE
	if is_colliding():
		hitposition = get_collision_point()
		directional_force.y = VitaVehicleSimulation.suspension(self,S_RestLength, elasticity,damping,damping_rebound, velocity.y,abs(cast_to.y),global_transform.origin,get_collision_point(),car.mass,ground_bump,ground_bump_height)

		# FRICTION
		var grip = (directional_force.y*tyre_maxgrip) +Static_Grip
		var rigidity = 0.67
		var r = 1.0-rigidity
		
		var patch_hardness = 1.0


		var disty = velocity2.z - (wv*w_size)/(drag +1.0)
		if not Differed_Wheel == "":
			var d_w = car.get_node(Differed_Wheel)
			disty = velocity2.z - ((wv*(1.0-get_parent().locked) +d_w.wv_diff*get_parent().locked)*w_size)/(drag +1)

#		if name == 'fl':
#			print(disty)

		var distx = velocity2.x

		var compensate2 = directional_force.y
		var grav_incline = $geometry.global_transform.basis.orthonormalized().xform_inv(Vector3(0,1,0)).x

		distx -= (grav_incline*(compensate2/tyre_stiffness))*1.1

		slip_perc = Vector2(distx,disty)

		disty *= tyre_stiffness
		distx *= tyre_stiffness
	
		distx -= atan2(abs(wv),1.0)*((angle*10.0)*w_size)

		if grip>0:

			var slipraw = sqrt(pow(abs(disty),2.0) + pow(abs(distx),2.0))
			if slipraw>grip:
				 slipraw = grip

			var slip = sqrt(pow(abs(disty),2.0) + pow(abs(distx),2.0))/grip
			slip /= slip*ground_builduprate +1.0
			slip -= 1.0
			if slip<0:
				slip = 0
			slip_perc2 = slip
				
			var forcey = -disty/(slip +1.0)
			var forcex = -distx/(slip +1.0)
			
			var yesx = abs(forcex)
			if yesx>1.0:
				yesx = 1.0
			var smoothx = yesx*yesx
			if smoothx>1.0:
				smoothx = 1.0
			var yesy = abs(forcey)
			if yesy>1.0:
				yesy = 1.0
			var smoothy = yesy*1.0
			if smoothy>1.0:
				smoothy = 1.0
			forcex /= (smoothx*(rigidity) +(1.0-rigidity))
			forcey /= (smoothy*(rigidity) +(1.0-rigidity))
				
			directional_force.x = forcex
			directional_force.z = forcey
	else:
		$geometry.translation = cast_to

	output_wv = wv
	$animation/camber/wheel.rotate_x(deg2rad(wv))

	$geometry.translation.y += w_size






	$animation/camber.rotation.z = -(deg2rad(-c_camber*float(translation.x<0.0) + c_camber*float(translation.x>0.0)) )






	var g
	
	axle_position = $geometry.translation.y

	$animation.translation = $geometry.translation
		
	car.apply_impulse(hitposition-car.global_transform.origin -global_transform.basis.y.normalized()*Lateral_Roll_Influence,$velocity2.global_transform.basis.x.normalized()*directional_force.x)
	car.apply_impulse(hitposition-car.global_transform.origin,$velocity2.global_transform.basis.y.normalized()*directional_force.y)
	car.apply_impulse(hitposition-car.global_transform.origin -global_transform.basis.y.normalized()*Longitudinal_Roll_Influence,$velocity2.global_transform.basis.z.normalized()*directional_force.z)

	# torque
	
	var torqed = (wheelpower*w_weight)/4.0
	
	wv_ds = wv
	
#	car.apply_impulse($geometry.global_transform.origin-car.global_transform.origin +$velocity2.global_transform.basis.orthonormalized().xform(Vector3(0,0,1)),$velocity2.global_transform.basis.orthonormalized().xform(Vector3(0,1,0))*torqed)
#	car.apply_impulse($geometry.global_transform.origin-car.global_transform.origin -$velocity2.global_transform.basis.orthonormalized().xform(Vector3(0,0,1)),$velocity2.global_transform.basis.orthonormalized().xform(Vector3(0,1,0))*-torqed)
	
	





