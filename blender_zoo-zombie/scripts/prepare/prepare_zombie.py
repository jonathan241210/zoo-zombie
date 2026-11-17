"""Prepare the downloaded zombie (assets/models/animation_zombie_2.glb) for Godot.

- Removes junk objects and unused actions, renames actions to the project standard.
- Scales to a 1.8 m tall adult standing on the ground.

Run:
    Blender -b --python blender_zoo-zombie/scripts/prepare/prepare_zombie.py
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lib import export_utils, rig_prep  # noqa: E402

SOURCE = export_utils.SOURCE_MODELS / "animation_zombie_2.glb"
OUTPUT = export_utils.GODOT_MODELS / "zombies" / "zombie.glb"
HEIGHT = 1.8

ACTIONS = {
    "idle01": "idle",
    "idle02": "idle_2",
    "walk01": "walk",
    "walk02": "walk_2",
    "run": "run",
    "attack01": "attack",
    "attack02": "attack_2",
    "damage": "hit",
    "death": "death",
}


def main() -> None:
    args = export_utils.parse_args(needs_input=True, default_output=OUTPUT, default_input=SOURCE)
    rig_prep.load_downloaded(args.input)
    rig_prep.rename_and_filter_actions(ACTIONS)
    rig_prep.normalize_transform(HEIGHT)
    export_utils.export_glb(args.output)


if __name__ == "__main__":
    main()
