extends Spatial
export var Transmission_Whine_Factor = 1.0
export var Transmission_Whine_Volume = 0.0
export var Transmission_Whine_Pitch = 1.0

export var Backfire_Fuel_Richness = 0.2
export var Backfire_Fuel_Decay = 0.1
export var Backfire_Air = 0.02
export var Backfire_Threshold = 1.0
export var Backfire_Rate = 1.0
export var Backfire_Volume = 0.5
export var Backfire_Throttle_Release_Trigger = 0.0
export var Backfire_Throttle_Release_Trigger_RPM = 4000.0

export var WhinePitch = 4
export var WhineVolume = 0.4
 
export var BlowOffBounceSpeed = 0.0
export var BlowOffWhineReduction = 1.0
export var BlowDamping = 0.25
export var BlowOffVolume = 0.5
export var BlowOffVolume2 = 0.5
export var SpoolVolume = 0.5
export var SpoolPitch = 0.5
export var TurboNoiseRPMInfluence = 0.25

export var engine_sound = NodePath("../engine_sound")
export(Array,NodePath) var exhaust_particles = []

export var volume = 0.25
var blow_psi = 0.0
var blow_inertia = 0.0

var fueltrace = 0.0
var air = 0.0
var rand = 0.0
var released = false
var released2 = false
var released3 = false

func play():
	$spool.stop()
	$scwhine.stop()
	$whigh.play()
	$wlow.play()

	if get_parent().Turbo_Enabled:
		$spool.play()
	if get_parent().Supercharger_Enabled:
		$scwhine.play()
			
func stop():
	for i in get_children():
		i.stop()

func _ready():
	play()

func _physics_process(_delta):
	fueltrace += (get_parent().throttle)*Backfire_Fuel_Richness
	air = (get_parent().throttle*get_parent().rpm)*Backfire_Air +get_parent().turbopsi

	fueltrace -= fueltrace*Backfire_Fuel_Decay
	
	if fueltrace<0.0:
		fueltrace = 0.0
		
	
	if has_node(engine_sound):
		get_node(engine_sound).pitch_influence -= (get_node(engine_sound).pitch_influence - 1.0)*0.5

	released = get_parent().throttle<Backfire_Throttle_Release_Trigger
	
	if not released2 == released:
		released2 = released
		if get_parent().rpm>Backfire_Throttle_Release_Trigger_RPM:
			released3 = released

	if fueltrace>rand_range(air*0.1 +Backfire_Threshold,60.0/Backfire_Rate) or released3:
		released3 = false
		rand = 0.1
		var ft = fueltrace
		if ft<10:
			ft = 10
		$backfire.play()
		var yed = 1.5-ft*0.1
		if yed<1.0:
			yed = 1.0
		$backfire.pitch_scale = rand_range(yed*1.25,yed*1.5)
		$backfire.unit_db = linear2db((ft*Backfire_Volume)*0.1)
		$backfire.max_db = $backfire.unit_db
		get_node(engine_sound).pitch_influence = 0.5
		for i in exhaust_particles:
			get_node(i).emitting = true
	else:
		for i in exhaust_particles:
			get_node(i).emitting = false

	
	
	var wh = abs(get_parent().rpm/10000.0)*WhinePitch
	if wh<0.0:
		wh = 0.0
	if wh>0.01:
		$scwhine.unit_db = linear2db(WhineVolume*volume)
		$scwhine.max_db = $scwhine.unit_db
		$scwhine.pitch_scale = wh
	else:
		$scwhine.unit_db = linear2db(0.0)


	var dist = blow_psi - get_parent().turbopsi
	blow_psi -= (blow_psi - get_parent().turbopsi)*BlowOffWhineReduction
	blow_inertia += blow_psi - get_parent().turbopsi
	blow_inertia -= (blow_inertia - (blow_psi - get_parent().turbopsi))*BlowDamping
	blow_psi -= blow_inertia*BlowOffBounceSpeed

	if blow_psi>get_parent().Forced_Induction_Torque_Add:
		blow_psi = get_parent().Forced_Induction_Torque_Add
		
		
	var blowvol = dist
	if blowvol<0.0:
		blowvol = 0.0
	elif blowvol>1.0:
		blowvol = 1.0
		
	var spoolvol = get_parent().turbopsi/10.0
	if spoolvol<0.0:
		spoolvol = 0.0
	elif spoolvol>1.0:
		spoolvol = 1.0

	spoolvol += (abs(get_parent().rpm)*(TurboNoiseRPMInfluence/1000.0))*spoolvol
	
	var blow = linear2db(volume*(blowvol*BlowOffVolume2))
	if blow<-60.0:
		blow = -60.0
	var spool = linear2db(volume*(spoolvol*SpoolVolume))
	if spool<-60.0:
		spool = -60.0

	$spool.unit_db = spool
	$spool.max_db = $spool.unit_db
	var yes = blowvol*BlowOffVolume
	if yes>1.0:
		yes = 1.0
	elif yes<0.0:
		yes = 0.0
	$spool.pitch_scale = SpoolPitch +spoolvol*0.5

	var whinepitch = clamp( (get_parent().rpm_root/1.0)*get_parent().maxspeed,1.0,1000.0 )*Transmission_Whine_Pitch

	var whinevol = clamp(abs(get_parent().resistance*Transmission_Whine_Factor)*1000.0,0.0,1000000.0)*Transmission_Whine_Volume

	if get_parent().gear == 0:
		whinevol = 0.0

	var h = whinepitch/200.0
	if h>1.0:
		h = 1.0
	elif h<0.5:
		h = 0.5
		
	var wlow = linear2db(((get_parent().clutchpedal*whinevol)/160000.0)*((1.0-h)*0.5))
	if wlow<-60.0:
		wlow = -60.0
	$wlow.unit_db = wlow
	$wlow.max_db = $wlow.unit_db
	if whinepitch/50.0>0.0001:
		$wlow.pitch_scale = whinepitch/50.0
	var whigh = linear2db(((get_parent().clutchpedal*whinevol)/80000.0)*0.5)
	if whigh<-60.0:
		whigh = -60.0
	$whigh.unit_db = whigh
	$whigh.max_db = $whigh.unit_db
	if whinepitch/100.0>0.0001:
		$whigh.pitch_scale = whinepitch/100.0




