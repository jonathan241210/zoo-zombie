"""Shared flat-color palette so procedural props match the map's low-poly look.

Colors are linear RGBA (Blender's color space for node inputs).
"""

import bpy

PALETTE: dict[str, tuple[float, float, float, float]] = {
    "wood_light": (0.55, 0.36, 0.18, 1.0),
    "wood_dark": (0.30, 0.18, 0.09, 1.0),
    "metal_dark": (0.10, 0.11, 0.11, 1.0),
    "metal_galvanized": (0.45, 0.47, 0.48, 1.0),
    "rust": (0.40, 0.18, 0.08, 1.0),
    "hay": (0.78, 0.62, 0.22, 1.0),
    "produce_green": (0.20, 0.45, 0.10, 1.0),
    "produce_orange": (0.85, 0.35, 0.05, 1.0),
    "produce_red": (0.60, 0.08, 0.05, 1.0),
    "ammo_green": (0.16, 0.24, 0.12, 1.0),
    "ammo_brass": (0.80, 0.58, 0.20, 1.0),
    "shell_red": (0.55, 0.05, 0.04, 1.0),
    "label_white": (0.85, 0.85, 0.80, 1.0),
    "concrete": (0.50, 0.49, 0.46, 1.0),
    "water": (0.10, 0.25, 0.30, 1.0),
}


def flat_material(key: str, roughness: float = 0.8, metallic: float = 0.0,
                  emission_strength: float = 0.0) -> bpy.types.Material:
    """Return (creating once) a Principled material with a palette color."""
    name = f"M_{key}"
    material = bpy.data.materials.get(name)
    if material is not None:
        return material
    color = PALETTE[key]
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    material.diffuse_color = color
    bsdf = next(n for n in material.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if emission_strength > 0.0:
        bsdf.inputs["Emission Color"].default_value = color
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    return material
