class_name HandAlignModifier
extends SkeletonModifier3D
## Rotates one hand bone to match a target node's orientation (plus a tunable
## offset), keeping the hand where IK placed it. Add it AFTER the IK modifier
## that positions the arm. Its `influence` blends the result. Test-environment
## helper: it only changes the pose in memory. (Added in Phase 3B.)

@export var bone_name: String = "LeftHand"
## Extra rotation applied on top of the target's orientation, in degrees.
@export var offset_degrees: Vector3 = Vector3.ZERO

var target: Node3D


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null or target == null or not is_instance_valid(target):
		return
	var index := skeleton.find_bone(bone_name)
	if index < 0:
		return
	var current := skeleton.get_bone_global_pose(index)
	var skeleton_basis := skeleton.global_basis.orthonormalized()
	var desired := skeleton_basis.inverse() * target.global_basis.orthonormalized() \
			* Basis.from_euler(offset_degrees * (PI / 180.0))
	skeleton.set_bone_global_pose(index, Transform3D(Basis(desired.get_rotation_quaternion()), current.origin))
