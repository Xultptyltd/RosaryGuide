#!/usr/bin/env python3
"""Lengthen the hanging strands of the rosary-beads Lottie and make it loop seamlessly.

Every bead and the chain are children of the "sway pivot" layer, and the chain's
feed-in point sits at y=-235, above the composition. Moving the pivot down by DROP
and growing the composition reveals DROP more of each strand without resizing beads
or changing the motion.

Over its 1584 frames the chain feeds exactly one decade (11 beads): bead k at the last
frame sits where bead k-11 sat at frame 0, with the same scale and zero sway at both
ends. The original simply has no beads above "bead 23" (left strand, visible at the
end) or above "bead -12" (right strand, visible at the start), which left bare string
at the top of the longer strands. EXTRA_BEADS rigid copies of each fill those ends.
Their offsets are taken from the bead each copy must match at the other end of the
loop, so the last frame equals frame 0 and LottieLoopMode.loop wraps with no jump.
In the region the copies show, their source bead only slides along the straight
upper strand, so offset copies follow the chain exactly; elsewhere they sit hidden
above the top edge.

Usage: python3 tools/lottie/extend_rosary_beads.py
"""
import json, pathlib, sys
ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/lottie/rosary-beads-original.json"
DST = ROOT / "RosaryGuide/Animations/RosaryBeadsFall.json"
if len(sys.argv) == 3:
    SRC, DST = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
DROP = 200
GROW = 180          # composition height added (bottom trimmed by DROP - GROW)
EXTRA_BEADS = 6     # copies at each strand top
DECADE = 11         # beads fed per loop

d = json.loads(SRC.read_text())
layers = d["layers"]
pivot = next(l for l in layers if l["nm"] == "sway pivot")
p = pivot["ks"]["p"]
assert p.get("a", 0) == 0, "pivot position is expected to be static"
p["k"][1] += DROP
d["h"] += GROW
first, last = d["ip"], d["op"]

def pos(name, frame):
    ks = next(l for l in layers if l["nm"] == name)["ks"]["p"]["k"]
    k = ks[0] if frame <= ks[0]["t"] else ks[-1]
    return k["s"][:2]

def copy_offsets(source, source_frame, targets, target_frame):
    """Offsets making copy n of source match targets[n-1] at the other loop end. Past
    the last unparked target, continue the strand's top spacing (40) straight up."""
    sx, sy = pos(source, source_frame)
    out = []
    for name in targets:
        tx, ty = pos(name, target_frame)
        if ty > -230:  # not parked at the feed point
            out.append((tx - sx, ty - sy))
        else:
            dx, dy = out[-1]
            out.append((dx + (1 if dx > 0 else -1), dy - 40))
    return out

next_ind = max(l["ind"] for l in layers) + 1
def add_copies(source, source_frame, target_frame, targets, names):
    global next_ind
    i = next(j for j, l in enumerate(layers) if l["nm"] == source)
    for n, ((dx, dy), name) in enumerate(zip(copy_offsets(source, source_frame, targets, target_frame), names), 1):
        copy = json.loads(json.dumps(layers[i]))
        copy["nm"] = name; copy["ind"] = next_ind; next_ind += 1
        for k in copy["ks"]["p"]["k"]:
            for key in ("s", "e"):
                if key in k:
                    k[key][0] += dx; k[key][1] += dy
        layers.insert(i + n, copy)

# Left strand: at the last frame, bead 23+n must sit where bead 12+n sat at frame 0.
N = range(1, EXTRA_BEADS + 1)
add_copies("bead 23", last, first, [f"bead {12 + n}" for n in N], [f"bead {23 + n}" for n in N])
# Right strand: at frame 0, bead -12-n must sit where bead -1-n sits at the last frame.
add_copies("bead -12", first, last, [f"bead {-1 - n}" for n in N], [f"bead {-12 - n}" for n in N])
DST.write_text(json.dumps(d, separators=(",", ":")))
print(f"wrote {DST}: {d['w']}x{d['h']}, pivot y {p['k'][1]}, {len(layers)} layers")
