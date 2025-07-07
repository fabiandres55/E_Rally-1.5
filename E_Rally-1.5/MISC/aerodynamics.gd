extends Position3D

export var LiftAngle = 0.1
export var DragCoefficient = 0.25
export var Downforce = 0.0


func _physics_process(_delta):
	var drag = DragCoefficient
	var df = Downforce
	
	var veloc = global_transform.basis.orthonormalized().xform_inv(get_parent().linear_velocity)
	
	var torq = global_transform.basis.orthonormalized().xform_inv(Vector3(1,0,0))
	
	get_parent().apply_torque_impulse(global_transform.basis.orthonormalized().xform( Vector3(((-veloc.length()*0.3)*LiftAngle),0,0)  ) )
	
	var vx = veloc.x*0.15
	var vy = veloc.z*0.15
	var vz = veloc.y*0.15
	var vl = veloc.length()*0.15
			
	var forc = global_transform.basis.orthonormalized().xform(Vector3(1,0,0))*(-vx*drag)
	forc += global_transform.basis.orthonormalized().xform(Vector3(0,0,1))*(-vy*drag)
	forc += global_transform.basis.orthonormalized().xform(Vector3(0,1,0))*(-vl*df -vz*drag)
	
	get_parent().apply_impulse(global_transform.basis.orthonormalized().xform(translation),forc)
			
