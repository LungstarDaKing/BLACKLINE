class_name FingerCurlModifier
extends SkeletonModifier3D
## Procedural finger curl for a Mixamo-style hand (isolated test only).
##
## Sets only the local rotation of the finger joints, so it never moves the
## hand: the weapon grip, left-hand IK and hand alignment are unaffected.
## 0 = hand as animated (open), 1 = full grip.

@export var curl_axis: Vector3 = Vector3(0.0, 0.0, 1.0)
@export var thumb_axis: Vector3 = Vector3(0.0, 0.0, 1.0)
## Sign of the curl on each side (the two hands are mirrored).
@export var left_sign: float = 1.0
@export var right_sign: float = 1.0
@export var proximal_degrees: float = 55.0
@export var middle_degrees: float = 80.0
@export var distal_degrees: float = 50.0
@export var thumb_degrees: Vector3 = Vector3(18.0, 30.0, 30.0)

# Driven by JackPresentation every frame.
var left_amount: float = 0.0
var right_amount: float = 0.0
var left_thumb: float = 0.0
var right_thumb: float = 0.0

const FINGERS: Dictionary = {"Index": 0.88, "Middle": 1.0, "Ring": 1.06, "Pinky": 1.14}


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	_curl_hand(skeleton, "Left", left_amount, left_thumb, left_sign)
	_curl_hand(skeleton, "Right", right_amount, right_thumb, right_sign)


func _curl_hand(skeleton: Skeleton3D, side: String, amount: float, thumb: float, sign: float) -> void:
	if amount < 0.001 and thumb < 0.001:
		return
	var joint_degrees := [proximal_degrees, middle_degrees, distal_degrees]
	for finger: String in FINGERS.keys():
		var stagger: float = FINGERS[finger]
		for joint in 3:
			var index := skeleton.find_bone("%sHand%s%d" % [side, finger, joint + 1])
			if index < 0:
				continue
			var angle: float = deg_to_rad(float(joint_degrees[joint]) * amount * stagger) * sign
			var rest := skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
			skeleton.set_bone_pose_rotation(index, rest * Quaternion(curl_axis.normalized(), angle))
	for joint in 3:
		var index := skeleton.find_bone("%sHandThumb%d" % [side, joint + 1])
		if index < 0:
			continue
		var angle: float = deg_to_rad(thumb_degrees[joint] * thumb) * sign
		var rest := skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
		skeleton.set_bone_pose_rotation(index, rest * Quaternion(thumb_axis.normalized(), angle))
