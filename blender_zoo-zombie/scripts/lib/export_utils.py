"""Shared helpers to run Blender scripts headless and export game-ready GLB files.

Every model script follows the same pattern:

    import sys; from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    from lib import export_utils

    args = export_utils.parse_args(needs_input=False)
    export_utils.reset_scene()
    ... build or import the model ...
    export_utils.export_glb(args.output)

Run with:
    Blender -b --python <script.py> -- --output <file.glb> [--input <file.glb>]
"""

import argparse
import sys
from pathlib import Path

import bpy

REPO_ROOT = Path(__file__).resolve().parents[3]
GODOT_MODELS = REPO_ROOT / "godot_zoo-zombie" / "zoo-zombie-godot" / "assets" / "models"
SOURCE_MODELS = REPO_ROOT / "assets" / "models"


def parse_args(needs_input: bool = False, default_output: Path | None = None,
               default_input: Path | None = None) -> argparse.Namespace:
    """Parse arguments placed after `--` on the Blender command line."""
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=default_output,
                        required=default_output is None)
    if needs_input:
        parser.add_argument("--input", type=Path, default=default_input,
                            required=default_input is None)
    args = parser.parse_args(argv)
    args.output = args.output.resolve()
    if needs_input:
        args.input = args.input.resolve()
    return args


def reset_scene() -> None:
    """Start from an empty file at 24 fps (the rate used by every downloaded model)."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = 24


def import_glb(path: Path) -> list[bpy.types.Object]:
    """Import a GLB and return the newly created objects.

    guess_original_bind_pose is disabled: on rigs converted from FBX (Sketchfab) the
    guessed bind pose is wrong and the re-exported animations end up rotated 90 degrees.
    """
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(path), guess_original_bind_pose=False)
    return [obj for obj in bpy.data.objects if obj not in before]


def remove_objects(predicate) -> int:
    """Delete every object for which predicate(obj) is True. Returns the count."""
    doomed = [obj for obj in bpy.data.objects if predicate(obj)]
    for obj in doomed:
        bpy.data.objects.remove(obj, do_unlink=True)
    return len(doomed)


def root_objects() -> list[bpy.types.Object]:
    return [obj for obj in bpy.context.scene.objects if obj.parent is None]


def export_glb(output: Path, animations: bool = True) -> None:
    """Export the whole scene: +Y up, modifiers applied, every action as a glTF animation."""
    output.parent.mkdir(parents=True, exist_ok=True)
    kwargs = dict(
        filepath=str(output),
        export_format="GLB",
        export_yup=True,
        export_apply=True,
        export_cameras=False,
        export_lights=False,
        export_animations=animations,
    )
    if animations:
        kwargs.update(export_animation_mode="ACTIONS", export_force_sampling=True,
                      export_def_bones=False)
    bpy.ops.export_scene.gltf(**kwargs)
    size_kb = output.stat().st_size / 1024
    print(f"[export] {output.name}: {size_kb:.0f} KB")
