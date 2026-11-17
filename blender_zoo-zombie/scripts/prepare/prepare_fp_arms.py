"""Prepare the first-person arms (assets/models/brazo_escopeta.glb) for Godot.

- Flattens the rig hierarchy and keeps only the actions the game uses, renamed to the
  project standard (spec 001 RF-113):
    shotgun_idle / shotgun_fire / shotgun_draw   (P_/D_/E_Escopeta)
    axe_idle / axe_swing                         (P_/E_Martillo: reused for the axe)
- Scales the viewmodel to real size (arm + shotgun ~0.9 m long) and centers it.
The rig has a single (right) arm, so carrying a food crate does not use it: the arms
are hidden and the crate is shown in front of the camera with a procedural bob.
The reload animation is procedural in Godot (Tween on the viewmodel and the shotgun
slide node "Corredera"), see docs/plans/001-zoo-survival.md.

Run:
    Blender -b --python blender_zoo-zombie/scripts/prepare/prepare_fp_arms.py
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import bpy  # noqa: E402
from mathutils import Matrix  # noqa: E402

from lib import export_utils, rig_prep  # noqa: E402

SOURCE = export_utils.SOURCE_MODELS / "brazo_escopeta.glb"
OUTPUT = export_utils.GODOT_MODELS / "weapons" / "fp_arms_shotgun.glb"
LENGTH = 0.9

ACTIONS = {
    "P_Escopeta": "shotgun_idle",
    "D_Escopeta": "shotgun_fire",
    "E_Escopeta": "shotgun_draw",
    "P_Martillo": "axe_idle",
    "E_Martillo": "axe_swing",
}


def scale_and_center(length: float) -> None:
    """Scale to `length` (largest dimension in the shotgun idle pose) and move the
    pose's bounds center to the origin. The source origin is ~7 m away from the arms,
    so Godot places the viewmodel in front of the camera with a parent offset instead.
    """
    low, high = rig_prep.mesh_bounds(rest_pose=False)
    factor = length / max(high - low)
    center = (low + high) * 0.5 * factor
    transform = Matrix.Translation(-center) @ Matrix.Scale(factor, 4)
    for obj in export_utils.root_objects():
        obj.matrix_world = transform @ obj.matrix_world
    bpy.context.view_layer.update()
    low, high = rig_prep.mesh_bounds(rest_pose=False)
    print(f"[fp_arms] scale x{factor:.1f} -> bounds min {tuple(round(v, 2) for v in low)} "
          f"max {tuple(round(v, 2) for v in high)}")


def main() -> None:
    args = export_utils.parse_args(needs_input=True, default_output=OUTPUT, default_input=SOURCE)
    armature = rig_prep.load_downloaded(args.input)
    rig_prep.rename_and_filter_actions(ACTIONS)
    rig_prep.assign_action(armature, bpy.data.actions["shotgun_idle"])
    scale_and_center(LENGTH)
    export_utils.export_glb(args.output)


if __name__ == "__main__":
    main()
