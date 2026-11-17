"""Helpers for preparing rigged models: action renaming/cleanup and keyframed actions."""

import bpy
from mathutils import Matrix, Quaternion


def rename_actions(mapping: dict[str, str]) -> None:
    """Rename actions (old -> new). Missing names raise so typos surface early."""
    for old, new in mapping.items():
        action = bpy.data.actions.get(old)
        if action is None:
            raise KeyError(f"Action '{old}' not found. Available: {[a.name for a in bpy.data.actions]}")
        action.name = new
        action.use_fake_user = True


def keep_only_actions(names: set[str]) -> None:
    """Delete every action whose name is not in `names`."""
    for action in list(bpy.data.actions):
        if action.name not in names:
            bpy.data.actions.remove(action)


def find_armature() -> bpy.types.Object:
    return next(obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE")


def bone_basis_for_armature_delta(armature: bpy.types.Object, bone_name: str,
                                  delta: Matrix) -> Matrix:
    """Pose `matrix_basis` that applies `delta` (armature space) to a parentless bone."""
    rest = armature.data.bones[bone_name].matrix_local
    return rest.inverted() @ delta @ rest


def key_bone_matrix(armature: bpy.types.Object, bone_name: str, basis: Matrix, frame: int) -> None:
    """Keyframe a pose bone's location/rotation(quaternion)/scale from a basis matrix."""
    pose_bone = armature.pose.bones[bone_name]
    pose_bone.rotation_mode = "QUATERNION"
    loc, rot, scale = basis.decompose()
    pose_bone.location = loc
    pose_bone.rotation_quaternion = rot
    pose_bone.scale = scale
    for path in ("location", "rotation_quaternion", "scale"):
        pose_bone.keyframe_insert(path, frame=frame)


def key_bone_rotation(armature: bpy.types.Object, bone_name: str, rotation: Quaternion,
                      frame: int) -> None:
    pose_bone = armature.pose.bones[bone_name]
    pose_bone.rotation_mode = "QUATERNION"
    pose_bone.rotation_quaternion = rotation
    pose_bone.keyframe_insert("rotation_quaternion", frame=frame)


def new_action(armature: bpy.types.Object, name: str) -> bpy.types.Action:
    """Create an empty action, assign it to the armature and keep it on export."""
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    if armature.animation_data is None:
        armature.animation_data_create()
    armature.animation_data.action = action
    return action


def reset_pose(armature: bpy.types.Object) -> None:
    for pose_bone in armature.pose.bones:
        pose_bone.location = (0, 0, 0)
        pose_bone.rotation_mode = "QUATERNION"
        pose_bone.rotation_quaternion = (1, 0, 0, 0)
        pose_bone.scale = (1, 1, 1)
