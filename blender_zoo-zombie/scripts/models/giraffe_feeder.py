"""Elevated giraffe feeder: tall wooden post on a metal base plate with a hay rack on top."""
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib import export_utils, mesh_utils as mu  # noqa: E402

args = export_utils.parse_args(default_output=export_utils.GODOT_MODELS / "props" / "giraffe_feeder.glb")
export_utils.reset_scene()
rnd = random.Random(3)
P = mu.PartBuilder()

RACK_Z = 3.6            # rack floor height
# base plate with bolts
P.add("metal_dark", mu.box((1.0, 1.0, 0.06), (0, 0, 0.03)))
for sx in (-1, 1):
    for sy in (-1, 1):
        P.add("metal_galvanized", mu.cylinder(0.04, 0.03, (sx * 0.42, sy * 0.42, 0.075), 6))
# main post
P.add("wood_dark", mu.box((0.22, 0.22, RACK_Z - 0.06), (0, 0, 0.06 + (RACK_Z - 0.06) / 2)))
P.add("metal_galvanized", mu.box((0.26, 0.26, 0.10), (0, 0, 0.11)))
P.add("metal_galvanized", mu.box((0.26, 0.26, 0.10), (0, 0, 2.0)))
# diagonal base braces (4 sides)
import math
for ang in range(4):
    br = mu.box((0.08, 0.08, 1.0), (0, 0, 0))
    mu.rotated(br, (-0.45, 0, 0))
    for v in br.verts:
        v.co += mu.Vector((0, -0.28, 0.5))
    mu.rotated(br, (0, 0, ang * math.pi / 2))
    P.add("wood_light", br)
# rack floor and support struts
P.add("wood_dark", mu.box((1.0, 1.0, 0.06), (0, 0, RACK_Z + 0.03)))
for ang in range(4):
    st = mu.box((0.07, 0.07, 0.72), (0, 0, 0))
    mu.rotated(st, (0.75, 0, 0))
    for v in st.verts:
        v.co += mu.Vector((0, -0.28, RACK_Z - 0.28))
    mu.rotated(st, (0, 0, ang * math.pi / 2))
    P.add("wood_light", st)
# rack: corner posts and rails (open slats so hay shows through)
top = RACK_Z + 0.06 + 0.55
for sx in (-1, 1):
    for sy in (-1, 1):
        P.add("wood_dark", mu.box((0.07, 0.07, 0.6), (sx * 0.465, sy * 0.465, RACK_Z + 0.36)))
for z in (RACK_Z + 0.22, RACK_Z + 0.42, RACK_Z + 0.62):
    for s in (-1, 1):
        P.add("wood_light", mu.box((1.0, 0.04, 0.06), (0, s * 0.485, z)))
        P.add("wood_light", mu.box((0.04, 0.92, 0.06), (s * 0.485, 0, z)))
# hay inside, mounded above the rim
P.add("hay", mu.blob((0.42, 0.42, 0.3), (0, 0, RACK_Z + 0.33), 2))
P.add("hay", mu.blob((0.3, 0.28, 0.18), (0.05, -0.03, RACK_Z + 0.62), 1))
for _ in range(14):
    s = mu.box((0.34, 0.015, 0.015), (0, 0, 0))
    mu.rotated(s, (rnd.uniform(-.5, .5), rnd.uniform(-.5, .5), rnd.uniform(0, 3.14)))
    for v in s.verts:
        v.co += mu.Vector((rnd.uniform(-.38, .38), rnd.uniform(-.38, .38), RACK_Z + rnd.uniform(0.35, 0.68)))
    P.add("hay", s)

objs = P.build("GiraffeFeeder")
P.report(objs, "giraffe_feeder")
export_utils.export_glb(args.output, animations=False)
