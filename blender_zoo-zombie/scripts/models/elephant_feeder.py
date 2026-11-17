"""Low concrete ground trough for the elephant, filled with hay and produce."""
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib import export_utils, mesh_utils as mu  # noqa: E402

args = export_utils.parse_args(default_output=export_utils.GODOT_MODELS / "props" / "elephant_feeder.glb")
export_utils.reset_scene()
rnd = random.Random(11)
P = mu.PartBuilder()

L, W, H, WALL, FLOOR = 1.8, 0.8, 0.6, 0.12, 0.14
# concrete trough: floor + four walls
P.add("concrete", mu.box((L, W, FLOOR), (0, 0, FLOOR / 2)))
for s in (-1, 1):
    P.add("concrete", mu.box((L, WALL, H), (0, s * (W / 2 - WALL / 2), H / 2), bevel=0.01))
    P.add("concrete", mu.box((WALL, W - 2 * WALL, H), (s * (L / 2 - WALL / 2), 0, H / 2), bevel=0.01))
# wooden rim caps and metal straps for a worn zoo look
for s in (-1, 1):
    P.add("wood_dark", mu.box((L + 0.04, 0.05, 0.04), (0, s * (W / 2 - 0.06), H + 0.02)))
for s in (-0.55, 0.0, 0.55):
    P.add("metal_dark", mu.box((0.05, W + 0.02, 0.03), (s, 0, H - 0.1)))
# filling: hay mound
P.add("hay", mu.blob((0.78, 0.26, 0.2), (0, 0, 0.5), 2))
for _ in range(14):
    s = mu.box((0.3, 0.015, 0.015), (0, 0, 0))
    mu.rotated(s, (rnd.uniform(-.4, .4), rnd.uniform(-.4, .4), rnd.uniform(0, 3.14)))
    for v in s.verts:
        v.co += mu.Vector((rnd.uniform(-.65, .65), rnd.uniform(-.2, .2), rnd.uniform(0.55, 0.68)))
    P.add("hay", s)
# produce on top
for x, y in ((-0.5, 0.0), (-0.1, 0.08), (0.45, -0.05)):
    P.add("produce_green", mu.blob(0.11, (x, y, 0.63), 1))
for x, y in ((0.2, 0.1), (-0.3, -0.12)):
    P.add("produce_red", mu.blob(0.07, (x, y, 0.65), 1))
for x, y, rz in ((0.05, -0.1, 0.5), (0.6, 0.08, -0.4), (-0.7, 0.1, 0.2)):
    c = mu.cone(0.03, 0.005, 0.24, (0, 0, 0), 6)
    mu.rotated(c, (0, 1.5708, 0))
    mu.rotated(c, (0, 0, rz))
    for v in c.verts:
        v.co += mu.Vector((x, y, 0.68))
    P.add("produce_orange", c)

objs = P.build("ElephantFeeder")
P.report(objs, "elephant_feeder")
export_utils.export_glb(args.output, animations=False)
