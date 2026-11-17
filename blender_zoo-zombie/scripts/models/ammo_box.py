"""Small olive military shotgun-ammo box with a label band and loose shells on the lid."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib import export_utils, mesh_utils as mu  # noqa: E402

args = export_utils.parse_args(default_output=export_utils.GODOT_MODELS / "props" / "ammo_box.glb")
export_utils.reset_scene()
P = mu.PartBuilder()

L, W = 0.34, 0.18
# body and lid (lid slightly larger, with a seam)
P.add("ammo_green", mu.box((L, W, 0.12), (0, 0, 0.06), bevel=0.006))
P.add("ammo_green", mu.box((L + 0.01, W + 0.01, 0.05), (0, 0, 0.145)))
# label band on the front (-Y) face
P.add("label_white", mu.box((0.17, 0.004, 0.06), (0, -(W + 0.01) / 2 - 0.001, 0.12)))
P.add("metal_dark", mu.box((0.12, 0.003, 0.008), (0, -(W + 0.01) / 2 - 0.003, 0.125)))
# latches and carry handle
for sx in (-1, 1):
    P.add("metal_dark", mu.box((0.03, 0.01, 0.07), (sx * 0.11, -W / 2 - 0.004, 0.11)))
    P.add("metal_dark", mu.box((0.02, 0.012, 0.025), (sx * 0.06, 0, 0.18)))
P.add("metal_dark", mu.box((0.14, 0.012, 0.012), (0, 0, 0.198)))
# ridges on lid ends
for sx in (-1, 1):
    P.add("metal_dark", mu.box((0.02, W - 0.02, 0.006), (sx * 0.15, 0, 0.171)))

# shotgun shells lying along X on the lid
def shell(x, y, z, rz):
    body = mu.cylinder(0.0105, 0.05, (0.035, 0, 0), 8, axis="X")
    base = mu.cylinder(0.0112, 0.022, (-0.001, 0, 0), 8, axis="X")
    rim = mu.cylinder(0.0125, 0.003, (-0.0135, 0, 0), 8, axis="X")
    for bm, key in ((body, "shell_red"), (base, "ammo_brass"), (rim, "ammo_brass")):
        mu.rotated(bm, (0, 0, rz))
        for v in bm.verts:
            v.co += mu.Vector((x, y, z))
        P.add(key, bm)

top = 0.17
shell(-0.12, 0.045, top + 0.0105, 0.08)
shell(-0.11, 0.022, top + 0.0105, -0.05)
shell(-0.115, 0.034, top + 0.0315, 0.02)
shell(0.0, -0.045, top + 0.0105, 0.1)
shell(0.02, -0.065, top + 0.0105, 0.0)

objs = P.build("AmmoBox")
P.report(objs, "ammo_box")
export_utils.export_glb(args.output, animations=False)
