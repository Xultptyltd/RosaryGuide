#!/usr/bin/env python3
"""Lengthen the hanging strands of the rosary-beads Lottie.

Every bead and the chain are children of the "sway pivot" layer, and the chain's
feed-in point sits at y=-235, above the composition. Moving the pivot down by DROP
and growing the composition by the same amount reveals DROP more of each strand
(on the right, beads already queued above the frame come into view; on the left,
EXTRA_BEADS copies of the last bead fill the strand) without resizing beads or
changing the motion. DROP must stay below ~235 - bead radius so the feed point
and the parked beads stay hidden above the top edge.

Usage: python3 tools/lottie/extend_rosary_beads.py
"""
import json, pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/lottie/rosary-beads-original.json"
DST = ROOT / "RosaryGuide/Animations/RosaryBeadsFall.json"
DROP = 200
GROW = 180          # composition height added (bottom trimmed by DROP - GROW)
EXTRA_BEADS = 5     # beads added above "bead 23" so the left strand stays filled
STEP = (-1.0, -46.0)  # spacing along the left strand, matching bead 22 -> 23

d = json.loads(SRC.read_text())
pivot = next(l for l in d["layers"] if l["nm"] == "sway pivot")
p = pivot["ks"]["p"]
assert p.get("a", 0) == 0, "pivot position is expected to be static"
p["k"][1] += DROP
d["h"] += GROW

# The left strand ends at "bead 23" (settles at y=1), so revealing more strand would
# show bare string there. In that region bead 23 only slides along the straight strand,
# so rigid offset copies of it follow the chain exactly and start hidden above the top.
layers = d["layers"]
i23 = next(i for i, l in enumerate(layers) if l["nm"] == "bead 23")
next_ind = max(l["ind"] for l in layers) + 1
for n in range(1, EXTRA_BEADS + 1):
    copy = json.loads(json.dumps(layers[i23]))
    copy["nm"] = f"bead {23 + n}"
    copy["ind"] = next_ind; next_ind += 1
    for k in copy["ks"]["p"]["k"]:
        for key in ("s", "e"):
            if key in k:
                k[key][0] += STEP[0] * n
                k[key][1] += STEP[1] * n
    layers.insert(i23 + n, copy)
DST.write_text(json.dumps(d, separators=(",", ":")))
print(f"wrote {DST.relative_to(ROOT)}: {d['w']}x{d['h']}, pivot y {p['k'][1]}, {len(layers)} layers")
