"""Open slatted wooden crate with produce and hay piled on top (first-person carry prop)."""
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib import export_utils, mesh_utils as mu  # noqa: E402

args = export_utils.parse_args(default_output=export_utils.GODOT_MODELS / "props" / "food_crate.glb")
export_utils.reset_scene()
rnd = random.Random(7)
P = mu.PartBuilder()

L, W, H = 0.60, 0.40, 0.30   # crate body; produce rises to ~0.38
T = 0.02                     # slat thickness
# floor boards + corner posts
P.add("wood_dark", mu.box((L - 0.02, W - 0.02, 0.025), (0, 0, 0.0125 + 0.03)))
for sx in (-1, 1):
    for sy in (-1, 1):
        P.add("wood_dark", mu.box((0.045, 0.045, H), (sx * (L / 2 - 0.0225), sy * (W / 2 - 0.0225), H / 2)))
# skids under the floor
for sy in (-1, 1):
    P.add("wood_dark", mu.box((L, 0.04, 0.03), (0, sy * 0.12, 0.015)))
# slats: 3 per wall
for i, z in enumerate((0.08, 0.17, 0.26)):
    for sy in (-1, 1):
        P.add("wood_light", mu.box((L, T, 0.07), (0, sy * (W / 2 - T / 2), z)))
    for sx in (-1, 1):
        P.add("wood_light", mu.box((T, W - 0.09, 0.07), (sx * (L / 2 - T / 2), 0, z)))

# hay bed filling the crate
P.add("hay", mu.blob((0.26, 0.16, 0.05), (0, 0, 0.30), 1))
# cabbages
for pos in ((-0.15, -0.07), (0.02, 0.08), (0.18, -0.05)):
    P.add("produce_green", mu.blob(0.075, (pos[0], pos[1], 0.335), 1))
# carrots lying across the top
for i, (x, y, rz) in enumerate(((-0.08, 0.10, 0.4), (0.10, 0.12, -0.3), (-0.02, -0.14, 0.1))):
    c = mu.cone(0.022, 0.004, 0.17, (0, 0, 0), 6)
    mu.rotated(c, (0, 1.5708, 0))
    mu.rotated(c, (0, 0, rz))
    for v in c.verts:
        v.co += mu.Vector((x, y, 0.36))
    P.add("produce_orange", c)
    leaf = mu.cone(0.02, 0.0, 0.05, (0, 0, 0), 5)
    mu.rotated(leaf, (0, 1.5708, 0))
    mu.rotated(leaf, (0, 0, rz))
    off = mu.Vector((0.1, 0, 0))
    off.rotate(mu.Matrix.Rotation(rz, 3, "Z"))
    for v in leaf.verts:
        v.co += mu.Vector((x, y, 0.36)) - off
    P.add("produce_green", leaf)
# hay bundle tied with a dark band, on the right
bundle = mu.cone(0.05, 0.05, 0.22, (0, 0, 0), 6)
mu.rotated(bundle, (0, 1.5708, 0.0))
mu.rotated(bundle, (0, 0, 0.5))
for v in bundle.verts:
    v.co += mu.Vector((0.07, -0.02, 0.37))
P.add("hay", bundle)
for _ in range(6):
    s = mu.box((0.16, 0.008, 0.008), (0, 0, 0))
    mu.rotated(s, (rnd.uniform(-.3, .3), rnd.uniform(-.3, .3), rnd.uniform(0, 3.14)))
    for v in s.verts:
        v.co += mu.Vector((rnd.uniform(-.2, .2), rnd.uniform(-.12, .12), 0.33))
    P.add("hay", s)

objs = P.build("FoodCrate")
P.report(objs, "food_crate")
export_utils.export_glb(args.output, animations=False)
