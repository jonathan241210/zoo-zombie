"""Shared pipeline for the downloaded animated animals (giraffe, elephant)."""

import math
from dataclasses import dataclass, field
from pathlib import Path

import bpy
from mathutils import Quaternion

from . import export_utils, rig_prep


@dataclass
class AnimalSpec:
    source: Path
    output: Path
    height: float
    actions: dict[str, str]
    # Death collapse: how far the body sinks while the legs buckle, and how much it is
    # lifted once lying on its side so the torso rests on the ground.
    death_sink: float
    death_lift: float
    # Weak pose: local rotation offsets (axis, degrees) per bone added to the idle.
    weak_offsets: dict[str, tuple[tuple[float, float, float], float]] = field(default_factory=dict)


def prepare(spec: AnimalSpec) -> None:
    args = export_utils.parse_args(needs_input=True, default_output=spec.output,
                                   default_input=spec.source)
    armature = rig_prep.load_downloaded(args.input)
    rig_prep.rename_and_filter_actions(spec.actions)
    rig_prep.normalize_transform(spec.height)
    rig_prep.add_death_action(armature, lift=spec.death_lift, sink=spec.death_sink)
    offsets = {bone: Quaternion(axis, math.radians(angle))
               for bone, (axis, angle) in spec.weak_offsets.items()}
    rig_prep.add_weak_action(armature, source="idle", bone_offsets=offsets)
    rig_prep.assign_action(armature, bpy.data.actions["idle"])
    export_utils.export_glb(args.output)
