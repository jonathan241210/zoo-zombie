"""Operator-free mesh helpers (safe in headless mode) for procedural low-poly models."""

import bmesh
import bpy
from mathutils import Matrix, Vector


def new_object(name: str, bm: bmesh.types.BMesh, material: bpy.types.Material | None = None,
               collection: bpy.types.Collection | None = None) -> bpy.types.Object:
    """Turn a bmesh into a linked mesh object with flat shading."""
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    for poly in mesh.polygons:
        poly.use_smooth = False
    if material is not None:
        mesh.materials.append(material)
    obj = bpy.data.objects.new(name, mesh)
    (collection or bpy.context.scene.collection).objects.link(obj)
    return obj


def box(size: Vector | tuple, center: Vector | tuple = (0, 0, 0), bevel: float = 0.0) -> bmesh.types.BMesh:
    """Axis-aligned box of `size` (x, y, z) centered at `center`, optionally beveled."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=Vector(size), verts=bm.verts)
    bmesh.ops.translate(bm, vec=Vector(center), verts=bm.verts)
    if bevel > 0.0:
        bmesh.ops.bevel(bm, geom=bm.edges[:] + bm.verts[:], offset=bevel, segments=1,
                        affect="EDGES", profile=0.5)
    return bm


def cylinder(radius: float, depth: float, center: Vector | tuple = (0, 0, 0),
             segments: int = 8, axis: str = "Z") -> bmesh.types.BMesh:
    """Low-poly capped cylinder along an axis."""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius,
                          radius2=radius, depth=depth)
    if axis == "X":
        bmesh.ops.rotate(bm, verts=bm.verts, matrix=Matrix.Rotation(1.5708, 3, "Y"))
    elif axis == "Y":
        bmesh.ops.rotate(bm, verts=bm.verts, matrix=Matrix.Rotation(1.5708, 3, "X"))
    bmesh.ops.translate(bm, vec=Vector(center), verts=bm.verts)
    return bm


def merge(parts: list[bmesh.types.BMesh]) -> bmesh.types.BMesh:
    """Combine several bmeshes into one (frees the inputs)."""
    result = bmesh.new()
    for part in parts:
        temp = bpy.data.meshes.new("__merge_tmp")
        part.to_mesh(temp)
        part.free()
        result.from_mesh(temp)
        bpy.data.meshes.remove(temp)
    return result


def triangle_count(obj: bpy.types.Object) -> int:
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


# --- Generic additions for procedural props -------------------------------------------------

def rotated(bm: bmesh.types.BMesh, euler: tuple, pivot: Vector | tuple | None = None) -> bmesh.types.BMesh:
    """Rotate a bmesh in place by XYZ euler radians around `pivot` (default: its own origin)."""
    from mathutils import Euler
    pivot = Vector(pivot) if pivot is not None else Vector((0, 0, 0))
    bmesh.ops.rotate(bm, verts=bm.verts, cent=pivot, matrix=Euler(euler, "XYZ").to_matrix())
    return bm


def blob(radius: tuple | float, center: Vector | tuple = (0, 0, 0), subdivisions: int = 1) -> bmesh.types.BMesh:
    """Low-poly icosphere scaled per axis (radius may be a float or an (x, y, z) tuple)."""
    rx, ry, rz = (radius, radius, radius) if isinstance(radius, (int, float)) else radius
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdivisions, radius=1.0)
    bmesh.ops.scale(bm, vec=Vector((rx, ry, rz)), verts=bm.verts)
    bmesh.ops.translate(bm, vec=Vector(center), verts=bm.verts)
    return bm


def cone(radius1: float, radius2: float, depth: float, center: Vector | tuple = (0, 0, 0),
         segments: int = 6) -> bmesh.types.BMesh:
    """Truncated cone along Z (radius1 at the bottom, radius2 at the top)."""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius1,
                          radius2=radius2, depth=depth)
    bmesh.ops.translate(bm, vec=Vector(center), verts=bm.verts)
    return bm


class PartBuilder:
    """Collect bmesh parts per palette key, then emit one flat-shaded object per material."""

    def __init__(self):
        self.groups: dict[str, list] = {}

    def add(self, key: str, bm: bmesh.types.BMesh) -> None:
        self.groups.setdefault(key, []).append(bm)

    def build(self, prefix: str, **material_kwargs) -> list[bpy.types.Object]:
        from . import materials
        objs = []
        for key, parts in self.groups.items():
            mat = materials.flat_material(key, **material_kwargs.get(key, {}))
            objs.append(new_object(f"{prefix}_{key}", merge(parts), mat))
        return objs

    def report(self, objs, label: str) -> None:
        tris = sum(triangle_count(o) for o in objs)
        print(f"[stats] {label}: {tris} tris")
