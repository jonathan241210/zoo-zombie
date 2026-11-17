"""Prepare the downloaded giraffe (assets/models/girafa_animada.glb) for Godot.

Scales it to ~5 m, renames actions to idle/walk/run/eat/attack and adds the missing
`death` and `weak` actions (spec 001 RF-111, RF-113).

Run:
    Blender -b --python blender_zoo-zombie/scripts/prepare/prepare_giraffe.py
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lib import export_utils  # noqa: E402
from lib.animal_prep import AnimalSpec, prepare  # noqa: E402

SPEC = AnimalSpec(
    source=export_utils.SOURCE_MODELS / "girafa_animada.glb",
    output=export_utils.GODOT_MODELS / "animals" / "giraffe.glb",
    height=5.0,
    actions={
        "01_Idle_Ruminating": "idle",
        "02_Walk": "walk",
        "03_Run_Gallop": "run",
        "04_Eat_Browsing": "eat",
        "05_Attack_Kick": "attack",
    },
    death_sink=0.15,
    death_lift=0.59,
    weak_offsets={
        "neck_T1_37": ((1.0, 0.0, 0.0), 25.0),
        "skull_21": ((1.0, 0.0, 0.0), 15.0),
    },
)

if __name__ == "__main__":
    prepare(SPEC)
