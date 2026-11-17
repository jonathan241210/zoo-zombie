"""Prepare the downloaded elephant (assets/models/elefante_animado.glb) for Godot.

Scales it to ~3.2 m, renames actions to idle/walk/run/eat/attack and adds the missing
`death` and `weak` actions (spec 001 RF-111, RF-113).

Run:
    Blender -b --python blender_zoo-zombie/scripts/prepare/prepare_elephant.py
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lib import export_utils  # noqa: E402
from lib.animal_prep import AnimalSpec, prepare  # noqa: E402

SPEC = AnimalSpec(
    source=export_utils.SOURCE_MODELS / "elefante_animado.glb",
    output=export_utils.GODOT_MODELS / "animals" / "elephant.glb",
    height=3.2,
    actions={
        "01_Idle": "idle",
        "02_Walk": "walk",
        "03_Run": "run",
        "04_Eating": "eat",
        "05_Attack": "attack",
    },
    death_sink=0.12,
    death_lift=0.87,
    weak_offsets={
        "DEF-neck_01_58": ((1.0, 0.0, 0.0), 15.0),
        "DEF-head_56": ((1.0, 0.0, 0.0), 15.0),
    },
)

if __name__ == "__main__":
    prepare(SPEC)
