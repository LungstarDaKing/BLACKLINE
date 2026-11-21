class_name StanceModifier
extends SkeletonModifier3D
## Procedural crouch and prone for a Mixamo-style skeleton (isolated test only).
##
## Runs after the animation. Nothing is rotated at node level: every change is a
## bone pose, so the skeleton is really folded into the stance.
##  - Crouch: hips drop and lean, both legs are re-solved with two-bone IK so
##    the animated feet stay planted (works with any clip: idle, walk, aim...).
##  - Prone: the whole body is posed on the ground (stomach down, legs behind,
##    torso propped on the elbows) with the rifle placed by IK in both hands.
## CharacterVisual feeds the inputs below every frame.

const CHILD: Dictionary = {
	"Hips": "Spine", "Spine": "Spine1", "Spine1": "Spine2", "Spine2": "Neck",
	"Neck": "Head", "Head": "HeadTop_End",
	"LeftUpLeg": "LeftLeg", "LeftLeg": "LeftFoot", "LeftFoot": "LeftToeBase",
	"RightUpLeg": "RightLeg", "RightLeg": "RightFoot", "RightFoot": "RightToeBase",
	"LeftArm": "LeftForeArm", "LeftForeArm": "LeftHand",
	"RightArm": "RightForeArm", "RightForeArm": "RightHand",
}
## Bones blended while the prone pose fades in or out (parents first).
const BLEND_ORDER: PackedStringArray = [
	"Hips", "Spine", "Spine1", "Spine2", "Neck", "Head",
	"LeftShoulder", "LeftArm", "LeftForeArm", "LeftHand",
	"RightShoulder", "RightArm", "RightForeArm", "RightHand",
	"LeftUpLeg", "LeftLeg", "LeftFoot", "LeftToeBase",
	"RightUpLeg", "RightLeg", "RightFoot", "RightToeBase",
]
const REQUIRED: PackedStringArray = [
	"Hips", "Spine", "Spine1", "Spine2", "Neck", "Head", "HeadTop_End",
	"LeftShoulder", "LeftArm", "LeftForeArm", "LeftHand",
	"RightShoulder", "RightArm", "RightForeArm", "RightHand", "WeaponR",
	"LeftUpLeg", "LeftLeg", "LeftFoot", "LeftToeBase",
	"RightUpLeg", "RightLeg", "RightFoot", "RightToeBase",
]

@export_group("Crouch")
## How far the hips drop (metres) at full crouch.
@export var crouch_drop: float = 0.42
@export var crouch_hip_back: float = 0.08
@export var crouch_lean_degrees: float = 10.0
## How far the knees swing outward (0 = straight ahead).
@export var crouch_knee_out: float = 0.18

@export_group("Prone")
@export var prone_hip_height: float = 0.13
## Distance of the hips behind the character's origin.
@export var prone_hip_back: float = 0.36
@export var prone_pitch_up_limit_degrees: float = 28.0
@export var prone_pitch_down_limit_degrees: float = 10.0
@export var prone_smoothing: float = 10.0
@export var crawl_leg_lift: float = 0.6

# Inputs, set by CharacterVisual each frame (world space).
var crouch_amount: float = 0.0
var prone_amount: float = 0.0
var forward_world: Vector3 = Vector3.FORWARD
var up_world: Vector3 = Vector3.UP
var right_world: Vector3 = Vector3.RIGHT
var origin_world: Vector3 = Vector3.ZERO
var aiming: bool = false
var sniper: bool = false
var weapon_kind: String = ""
var aim_pitch_radians: float = 0.0
var crawl_speed: float = 0.0
var crawl_phase: float = 0.0
var kick: float = 0.0
var delta_time: float = 0.016
## Grip pivot of the equipped weapon relative to the WeaponR bone.
var pivot_basis: Basis = Basis.IDENTITY
var pivot_position: Vector3 = Vector3.ZERO
## Where the left hand holds the rifle, in the rifle pivot's space.
var rifle_left_grip: Vector3 = Vector3(0.0, -0.03, 0.4)

var _skeleton: Skeleton3D
var _bones: Dictionary = {}
var _checked: bool = false
var _f: Vector3 = Vector3.FORWARD
var _u: Vector3 = Vector3.UP
var _r: Vector3 = Vector3.RIGHT
var _o: Vector3 = Vector3.ZERO
## Smoothed prone pose numbers (see _prone_targets).
var _ps: PackedFloat32Array = PackedFloat32Array()


func _process_modification() -> void:
	_skeleton = get_skeleton()
	if _skeleton == null:
		return
	if not _checked:
		_cache_bones()
	if _bones.is_empty():
		return
	if crouch_amount < 0.002 and prone_amount < 0.002:
		return
	var inverse := _skeleton.global_transform.affine_inverse()
	_f = (inverse.basis * forward_world).normalized()
	_u = (inverse.basis * up_world).normalized()
	_r = (inverse.basis * right_world).normalized()
	_o = inverse * origin_world
	if crouch_amount > 0.002:
		_apply_crouch(crouch_amount)
	if prone_amount > 0.002:
		_apply_prone(prone_amount)


func _cache_bones() -> void:
	_checked = true
	for bone_name in REQUIRED:
		var index := _skeleton.find_bone(bone_name)
		if index < 0:
			push_warning("StanceModifier: bone '%s' not found; stances disabled." % bone_name)
			_bones.clear()
			return
		_bones[bone_name] = index


# --- helpers ---------------------------------------------------------------


func _pose(bone_name: String) -> Transform3D:
	return _skeleton.get_bone_global_pose(_bones[bone_name])


func _pos(bone_name: String) -> Vector3:
	return _pose(bone_name).origin


func _set_pose(bone_name: String, pose: Transform3D) -> void:
	_skeleton.set_bone_global_pose(_bones[bone_name], pose)


## Turns the bone (shortest arc, so its roll is kept) until the vector to its
## child bone points along `direction`.
func _point(bone_name: String, direction: Vector3) -> void:
	var pose := _pose(bone_name)
	var current := _pos(CHILD[bone_name]) - pose.origin
	if current.length() < 0.0001 or direction.length() < 0.0001:
		return
	pose.basis = Basis(Quaternion(current.normalized(), direction.normalized())) * pose.basis
	_set_pose(bone_name, pose)


## Direction `degrees` above horizontal, along the character's forward.
func _dir(degrees: float) -> Vector3:
	var radians := deg_to_rad(degrees)
	return (_f * cos(radians) + _u * sin(radians)).normalized()


## Two-bone IK: root and mid are turned so the end bone reaches `target`;
## `pole` says which way the middle joint bends.
func _solve(root: String, mid: String, end: String, target: Vector3, pole: Vector3) -> void:
	var root_pos := _pos(root)
	var length_1 := root_pos.distance_to(_pos(mid))
	var length_2 := _pos(mid).distance_to(_pos(end))
	var to_target := target - root_pos
	if to_target.length() < 0.001:
		return
	var reach := clampf(to_target.length(), absf(length_1 - length_2) + 0.01, length_1 + length_2 - 0.002)
	var axis := to_target.normalized()
	var along := (length_1 * length_1 - length_2 * length_2 + reach * reach) / (2.0 * reach)
	var height := sqrt(maxf(length_1 * length_1 - along * along, 0.0))
	var bend := pole - axis * pole.dot(axis)
	if bend.length() < 0.001:
		bend = _f - axis * _f.dot(axis)
	bend = bend.normalized()
	var middle := root_pos + axis * along + bend * height
	_point(root, middle - root_pos)
	_point(mid, root_pos + axis * reach - middle)


# --- crouch ----------------------------------------------------------------


func _apply_crouch(amount: float) -> void:
	var feet: Dictionary = {}
	for side in ["Left", "Right"]:
		feet[side] = _pose(side + "Foot")
	var hips := _pose("Hips")
	hips.basis = Basis((_u.cross(_f)).normalized(), deg_to_rad(crouch_lean_degrees) * amount) * hips.basis
	hips.origin += -_u * crouch_drop * amount - _f * crouch_hip_back * amount
	_set_pose("Hips", hips)
	for side in ["Left", "Right"]:
		var foot_pose: Transform3D = feet[side]
		var outward := -_r if side == "Left" else _r
		var pole := _f + outward * crouch_knee_out
		_solve(side + "UpLeg", side + "Leg", side + "Foot", foot_pose.origin, pole)
		var restored := _pose(side + "Foot")
		restored.basis = foot_pose.basis
		_set_pose(side + "Foot", restored)


# --- prone -----------------------------------------------------------------


func _apply_prone(amount: float) -> void:
	var before: Dictionary = {}
	for bone_name in BLEND_ORDER:
		before[bone_name] = _pose(bone_name)
	_solve_prone()
	if amount >= 0.999:
		return
	var target: Dictionary = {}
	for bone_name in BLEND_ORDER:
		target[bone_name] = _pose(bone_name)
	for bone_name in BLEND_ORDER:
		var from: Transform3D = before[bone_name]
		var to: Transform3D = target[bone_name]
		_set_pose(bone_name, from.interpolate_with(to, amount))


## Numbers: spine, spine1, spine2, neck-base angles, neck angle, head angle
## (degrees above horizontal), grip forward / down from the right shoulder (m),
## left-hand mode (0 handguard, 1 stock, 2 pistol support).
func _prone_targets() -> PackedFloat32Array:
	if weapon_kind == "pistol":
		return PackedFloat32Array([12.0, 20.0, 26.0, 33.0, 42.0, 84.0, 0.40, 0.07, 2.0])
	if weapon_kind == "rifle" and aiming and sniper:
		return PackedFloat32Array([8.0, 13.0, 17.0, 22.0, 28.0, 62.0, 0.19, 0.09, 1.0])
	if aiming:
		return PackedFloat32Array([12.0, 20.0, 26.0, 33.0, 42.0, 84.0, 0.21, 0.11, 0.0])
	return PackedFloat32Array([14.0, 24.0, 30.0, 40.0, 52.0, 92.0, 0.21, 0.18, 0.0])


func _solve_prone() -> void:
	var targets := _prone_targets()
	if _ps.size() != targets.size():
		_ps = targets.duplicate()
	var blend := 1.0 - exp(-prone_smoothing * delta_time)
	for index in targets.size():
		_ps[index] = lerpf(_ps[index], targets[index], blend)
	var pitch := clampf(aim_pitch_radians,
			-deg_to_rad(prone_pitch_down_limit_degrees), deg_to_rad(prone_pitch_up_limit_degrees))
	var pitch_degrees := rad_to_deg(pitch)
	var walking := clampf(crawl_speed / 0.8, 0.0, 1.0)

	# Torso, from the hips up. The hips go on the ground behind the origin.
	var hips := _pose("Hips")
	hips.origin = _o - _f * prone_hip_back + _u * prone_hip_height
	_set_pose("Hips", hips)
	_point("Hips", _dir(_ps[0]))
	_point("Spine", _dir(_ps[1] + pitch_degrees * 0.1))
	_point("Spine1", _dir(_ps[2] + pitch_degrees * 0.15))
	_point("Spine2", _dir(_ps[3] + pitch_degrees * 0.2))
	_point("Neck", _dir(_ps[4] + pitch_degrees * 0.3))
	_point("Head", _dir(_ps[5] + pitch_degrees * 0.5))

	# Legs lie straight back; while crawling they take turns drawing a knee up.
	for side in ["Left", "Right"]:
		var outward := -_r if side == "Left" else _r
		var phase := crawl_phase + (0.0 if side == "Left" else PI)
		var lift := maxf(sin(phase), 0.0) * walking * crawl_leg_lift
		var thigh := -_f * (0.95 - 0.8 * lift) + outward * (0.12 + 0.45 * lift) + _u * (0.0 + 0.22 * lift)
		var shin := -_f * (0.99 - 0.45 * lift) + outward * 0.05 + _u * (0.06 + 0.8 * lift)
		_point(side + "UpLeg", thigh)
		_point(side + "Leg", shin)
		_point(side + "Foot", -_f * 0.5 - _u * (0.85 - 0.5 * lift))

	_solve_prone_arms(pitch)


func _solve_prone_arms(pitch: float) -> void:
	var shoulder := _pos("RightArm")
	var aim_dir := (_f * cos(pitch) + _u * sin(pitch)).normalized()
	var up_axis := (_u * cos(pitch) - _f * sin(pitch)).normalized()
	var grip_basis := Basis(up_axis.cross(aim_dir).normalized(), up_axis, aim_dir)
	# Recoil: the weapon steps back and flips up a little.
	grip_basis = Basis((_r), deg_to_rad(-3.0) * kick) * grip_basis
	var grip_pos := shoulder + _f * _ps[6] - _u * _ps[7] - aim_dir * 0.035 * kick
	var grip := Transform3D(grip_basis, grip_pos)

	var hand_rest := _skeleton.get_bone_global_rest(_bones["RightHand"])
	var weapon_rest := _skeleton.get_bone_global_rest(_bones["WeaponR"])
	var hand_to_grip := hand_rest.affine_inverse() * weapon_rest * Transform3D(pivot_basis, pivot_position)
	var hand_target := grip * hand_to_grip.affine_inverse()

	_solve("RightArm", "RightForeArm", "RightHand", hand_target.origin, -_u + _r * 0.45)
	var right_hand := _pose("RightHand")
	right_hand.basis = hand_target.basis
	_set_pose("RightHand", right_hand)

	var left_target := grip * rifle_left_grip
	if _ps[8] > 1.5:
		left_target = grip_pos - _r * 0.03 - up_axis * 0.03
	elif _ps[8] > 0.5:
		left_target = grip * Vector3(0.0, -0.11, -0.12)
	elif _ps[8] > 0.0:
		left_target = grip * rifle_left_grip.lerp(Vector3(0.0, -0.11, -0.12), _ps[8])
	_solve("LeftArm", "LeftForeArm", "LeftHand", left_target, -_u - _r * 0.45)
