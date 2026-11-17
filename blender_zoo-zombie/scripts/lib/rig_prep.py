"""Preparation of downloaded rigged models (scale, cleanup, extra actions).

Works with Blender 5 layered/slotted actions. All edits happen in a fresh scene; the
source GLB in assets/models is never modified.
"""

import math
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector

from . import export_utils

JUNK_PREFIXES = ("Icosphere",)  # bone display shape created by Blender's glTF importer


def load_downloaded(path: Path) -> bpy.types.Object:
    """Import a downloaded GLB into an empty scene, drop junk and return its armature."""
    export_utils.reset_scene()
    export_utils.import_glb(path)
    removed = export_utils.remove_objects(lambda o: o.name.startswith(JUNK_PREFIXES))
    armature = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
    flattened = flatten_hierarchy(armature)
    print(f"[rig_prep] imported {path.name}, removed {removed} junk objects, "
          f"flattened {flattened} empties")
    return armature


def flatten_hierarchy(armature: bpy.types.Object) -> int:
    """Make the armature a root object (keeping its world transform) and delete the
    empties ABOVE it. Sketchfab/FBX conversions wrap rigs in chains of empties with
    compensating scales (e.g. x34 then x0.01). Empties below the armature are kept:
    they may be bone-parented attachments or animated parts (e.g. a shotgun slide).
    """
    bpy.context.view_layer.update()
    ancestors = set()
    parent = armature.parent
    while parent is not None:
        ancestors.add(parent)
        parent = parent.parent
    world = armature.matrix_world.copy()
    armature.parent = None
    armature.matrix_world = world
    descendants = set(armature.children_recursive)
    return export_utils.remove_objects(
        lambda o: o.type == "EMPTY" and (o in ancestors or o not in descendants))


def mesh_bounds(rest_pose: bool = True) -> tuple[Vector, Vector]:
    """World-space bounds of all deformed meshes (rest pose by default)."""
    armatures = [o for o in bpy.context.scene.objects if o.type == "ARMATURE"]
    previous = {a: a.data.pose_position for a in armatures}
    if rest_pose:
        for armature in armatures:
            armature.data.pose_position = "REST"
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    low = Vector((1e9, 1e9, 1e9))
    high = -low
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        for vertex in mesh.vertices:
            world = obj.matrix_world @ vertex.co
            low = Vector(map(min, low, world))
            high = Vector(map(max, high, world))
        evaluated.to_mesh_clear()
    for armature, mode in previous.items():
        armature.data.pose_position = mode
    bpy.context.view_layer.update()
    return low, high


def normalize_transform(target_size: float, axis: int = 2) -> float:
    """Scale root objects so the model measures target_size on `axis` and stands on z=0.

    Returns the applied scale factor.
    """
    low, high = mesh_bounds()
    factor = target_size / (high[axis] - low[axis])
    scale = Matrix.Scale(factor, 4)
    for obj in export_utils.root_objects():
        obj.matrix_world = scale @ obj.matrix_world
    bpy.context.view_layer.update()
    low, high = mesh_bounds()
    center = (low + high) * 0.5
    offset = Matrix.Translation(Vector((-center.x, -center.y, -low.z)))
    for obj in export_utils.root_objects():
        obj.matrix_world = offset @ obj.matrix_world
    bpy.context.view_layer.update()
    low, high = mesh_bounds()
    print(f"[rig_prep] scale x{factor:.3f} -> size {tuple(round(v, 2) for v in high - low)}")
    return factor


def action_fcurves(action: bpy.types.Action) -> list[bpy.types.FCurve]:
    """All F-curves of an action (layered actions in Blender 5)."""
    curves: list[bpy.types.FCurve] = []
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                curves.extend(bag.fcurves)
    return curves


def assign_action(armature: bpy.types.Object, action: bpy.types.Action) -> None:
    if armature.animation_data is None:
        armature.animation_data_create()
    armature.animation_data.action = action
    if action.slots:
        armature.animation_data.action_slot = action.slots[0]


def rename_and_filter_actions(mapping: dict[str, str]) -> None:
    """Rename the actions we keep (old -> new) and delete every other action."""
    keep = set()
    for old, new in mapping.items():
        action = bpy.data.actions.get(old)
        if action is None:
            raise KeyError(f"Action '{old}' not found: {[a.name for a in bpy.data.actions]}")
        action.name = new
        action.use_fake_user = True
        keep.add(action)
    for action in list(bpy.data.actions):
        if action not in keep:
            bpy.data.actions.remove(action)
    print(f"[rig_prep] actions: {sorted(a.name for a in bpy.data.actions)}")


def _new_keyed_action(armature: bpy.types.Object, name: str) -> bpy.types.Action:
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    if armature.animation_data is None:
        armature.animation_data_create()
    armature.animation_data.action = action
    return action


def _key_pose_bone(pose_bone: bpy.types.PoseBone, frame: int) -> None:
    pose_bone.rotation_mode = "QUATERNION"
    for path in ("location", "rotation_quaternion", "scale"):
        pose_bone.keyframe_insert(path, frame=frame)


def _key_all_rest(armature: bpy.types.Object, frame: int) -> None:
    for pose_bone in armature.pose.bones:
        pose_bone.location = (0, 0, 0)
        pose_bone.rotation_mode = "QUATERNION"
        pose_bone.rotation_quaternion = (1, 0, 0, 0)
        pose_bone.scale = (1, 1, 1)
        _key_pose_bone(pose_bone, frame)


def _root_bone(armature: bpy.types.Object) -> bpy.types.PoseBone:
    return next(b for b in armature.pose.bones if b.parent is None)


def _world_delta_to_basis(armature: bpy.types.Object, bone_name: str,
                          world_delta: Matrix) -> Matrix:
    """matrix_basis for a parentless bone that applies world_delta to the whole rig."""
    arm_delta = armature.matrix_world.inverted() @ world_delta @ armature.matrix_world
    rest = armature.data.bones[bone_name].matrix_local
    return rest.inverted() @ arm_delta @ rest


def add_death_action(armature: bpy.types.Object, lift: float, sink: float,
                     name: str = "death", roll_degrees: float = 90.0,
                     buckle_frame: int = 10, fall_frame: int = 30, end_frame: int = 54) -> None:
    """Collapse: knees buckle (sink), then the body rolls onto its side around its
    length axis (world Y, the model faces -Y) and rests lifted by `lift` so the torso
    lies on the ground instead of intersecting it. Other bones stay at rest pose.
    """
    _new_keyed_action(armature, name)
    root = _root_bone(armature)
    _key_all_rest(armature, 0)

    poses = {
        buckle_frame: Matrix.Translation((0, 0, -sink)) @ Matrix.Rotation(0.15, 4, "Y"),
        fall_frame: Matrix.Translation((0, 0, lift)) @ Matrix.Rotation(
            -math.radians(roll_degrees), 4, "Y"),
        end_frame: Matrix.Translation((0, 0, lift)) @ Matrix.Rotation(
            -math.radians(roll_degrees), 4, "Y"),
    }
    for frame, delta in poses.items():
        basis = _world_delta_to_basis(armature, root.name, delta)
        location, rotation, scale = basis.decompose()
        root.location = location
        root.rotation_quaternion = rotation
        root.scale = scale
        _key_pose_bone(root, frame)
    print(f"[rig_prep] added '{name}' ({end_frame} frames)")


def add_weak_action(armature: bpy.types.Object, source: str, bone_offsets: dict[str, Quaternion],
                    name: str = "weak", time_scale: float = 1.6) -> None:
    """Copy `source` (e.g. idle), slow it down and add a constant local rotation offset
    to some bones (typically neck/head drooping)."""
    source_action = bpy.data.actions[source]
    weak = source_action.copy()
    weak.name = name
    weak.use_fake_user = True
    curves = action_fcurves(weak)
    for curve in curves:
        for point in curve.keyframe_points:
            point.co.x *= time_scale
            point.handle_left.x *= time_scale
            point.handle_right.x *= time_scale

    # Group quaternion curves per bone so each key can be multiplied by the offset.
    for bone_name, offset in bone_offsets.items():
        path = f'pose.bones["{bone_name}"].rotation_quaternion'
        quat_curves = sorted((c for c in curves if c.data_path == path), key=lambda c: c.array_index)
        if len(quat_curves) != 4:
            # Bone not animated in the source: add a constant key with the offset.
            assign_action(armature, weak)
            pose_bone = armature.pose.bones[bone_name]
            pose_bone.rotation_mode = "QUATERNION"
            pose_bone.rotation_quaternion = offset
            pose_bone.keyframe_insert("rotation_quaternion", frame=0)
            continue
        frames = sorted({p.co.x for c in quat_curves for p in c.keyframe_points})
        values = {f: Quaternion([c.evaluate(f) for c in quat_curves]) for f in frames}
        for frame, value in values.items():
            new_value = value @ offset
            for index, curve in enumerate(quat_curves):
                for point in curve.keyframe_points:
                    if abs(point.co.x - frame) < 1e-4:
                        delta = new_value[index] - point.co.y
                        point.co.y += delta
                        point.handle_left.y += delta
                        point.handle_right.y += delta
    for curve in curves:
        curve.update()
    print(f"[rig_prep] added '{name}' from '{source}' (x{time_scale} slower)")
