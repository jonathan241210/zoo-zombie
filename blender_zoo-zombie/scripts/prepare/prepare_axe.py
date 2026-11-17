"""Prepare the downloaded axe (assets/models/hacha.glb) as the secondary weapon.

The source is ~8.8 m long and lies along X. This script scales it to a real fire axe
(~0.75 m), stands the handle along +Z (Godot +Y) with the head on top, and puts the
origin at the grip point near the bottom of the handle, so Godot can attach it to the
viewmodel hand bone with a BoneAttachment3D.

Run:
    Blender -b --python blender_zoo-zombie/scripts/prepare/prepare_axe.py
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

from lib import export_utils, rig_prep  # noqa: E402

SOURCE = export_utils.SOURCE_MODELS / "hacha.glb"
OUTPUT = export_utils.GODOT_MODELS / "weapons" / "axe.glb"
LENGTH = 0.75
GRIP_FROM_BOTTOM = 0.12  # ratio of the length where the hand holds the handle


def head_is_on_positive_x(objects: list[bpy.types.Object]) -> bool:
    """The axe head is the end with the larger cross-section."""
    spans = {1: [1e9, -1e9], -1: [1e9, -1e9]}
    for obj in objects:
        for vertex in obj.data.vertices:
            world = obj.matrix_world @ vertex.co
            side = 1 if world.x > 0 else -1
            spans[side][0] = min(spans[side][0], world.z)
            spans[side][1] = max(spans[side][1], world.z)
    return (spans[1][1] - spans[1][0]) > (spans[-1][1] - spans[-1][0])


def main() -> None:
    args = export_utils.parse_args(needs_input=True, default_output=OUTPUT, default_input=SOURCE)
    export_utils.reset_scene()
    export_utils.import_glb(args.input)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    bpy.context.view_layer.update()

    low, high = rig_prep.mesh_bounds(rest_pose=False)
    center = (low + high) * 0.5
    factor = LENGTH / max(high - low)
    # Center, scale, then rotate the X-aligned axe so the head points up (+Z).
    angle = -math.pi / 2 if head_is_on_positive_x(meshes) else math.pi / 2
    transform = Matrix.Rotation(angle, 4, "Y") @ Matrix.Scale(factor, 4) @ Matrix.Translation(-center)
    for obj in export_utils.root_objects():
        obj.matrix_world = transform @ obj.matrix_world
    bpy.context.view_layer.update()

    low, high = rig_prep.mesh_bounds(rest_pose=False)
    grip = Vector(((low.x + high.x) * 0.5, (low.y + high.y) * 0.5,
                   low.z + (high.z - low.z) * GRIP_FROM_BOTTOM))
    for obj in export_utils.root_objects():
        obj.matrix_world = Matrix.Translation(-grip) @ obj.matrix_world
    bpy.context.view_layer.update()
    low, high = rig_prep.mesh_bounds(rest_pose=False)
    print(f"[axe] scale x{factor:.3f}, bounds min {tuple(round(v, 2) for v in low)} "
          f"max {tuple(round(v, 2) for v in high)}")
    export_utils.export_glb(args.output, animations=False)


if __name__ == "__main__":
    main()
