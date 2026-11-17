"""Headless preview renders for visual verification of models and animations.

Adds a temporary camera and sun, renders with EEVEE and removes them again, so the
exported GLB never contains them.
"""

import math
from pathlib import Path

import bpy
from mathutils import Vector


def render_views(output_dir: Path, prefix: str, frames: list[int] | None = None,
                 action: bpy.types.Action | None = None, armature: bpy.types.Object | None = None,
                 direction: Vector = Vector((1.0, -1.0, 0.45)), resolution: int = 480,
                 target_bounds: tuple[Vector, Vector] | None = None) -> list[Path]:
    """Render the scene (optionally an action at several frames) from one direction."""
    output_dir.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    if action is not None and armature is not None:
        from .rig_prep import assign_action
        assign_action(armature, action)
    low, high = target_bounds if target_bounds else _bounds()
    center = (low + high) * 0.5
    radius = max((high - low).length * 0.5, 0.1)

    camera_data = bpy.data.cameras.new("__preview_cam")
    camera_data.lens = 50
    camera = bpy.data.objects.new("__preview_cam", camera_data)
    scene.collection.objects.link(camera)
    distance = radius / math.tan(camera_data.angle * 0.5) * 1.15
    camera.location = center + direction.normalized() * distance
    camera.rotation_euler = (center - camera.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = camera

    sun_data = bpy.data.lights.new("__preview_sun", "SUN")
    sun_data.energy = 3.0
    sun = bpy.data.objects.new("__preview_sun", sun_data)
    sun.rotation_euler = (math.radians(50), 0, math.radians(30))
    scene.collection.objects.link(sun)
    if scene.world is None:
        scene.world = bpy.data.worlds.new("__preview_world")
    scene.world.color = (0.35, 0.37, 0.4)

    try:
        scene.render.engine = "BLENDER_EEVEE"
    except TypeError:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = resolution
    scene.render.resolution_y = resolution
    scene.render.image_settings.file_format = "PNG"

    paths = []
    for frame in frames or [scene.frame_current]:
        scene.frame_set(frame)
        path = output_dir / f"{prefix}_f{frame:03d}.png"
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        paths.append(path)

    bpy.data.objects.remove(camera, do_unlink=True)
    bpy.data.objects.remove(sun, do_unlink=True)
    bpy.data.cameras.remove(camera_data)
    bpy.data.lights.remove(sun_data)
    return paths


def _bounds() -> tuple[Vector, Vector]:
    from .rig_prep import mesh_bounds
    return mesh_bounds(rest_pose=False)
