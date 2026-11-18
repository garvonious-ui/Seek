#!/usr/bin/env python3
"""
Renders the code-drawn iOS screens (ios-screens/screens.html) used inside the
paid ads: frame sequences in ads/screens/ios/<name>/ plus a still <name>.png.
Content lives in refresh_slate.IOS_SCREENS; verse text comes from the NLT seed.

Usage: python3 render_ios_screens.py [name ...]
Needs Node + Playwright (Chromium).
"""
import json, os, subprocess, sys
from refresh_slate import IOS_SCREENS
from render_hook_reels import verse, HERE

FPS = 30
JOBS = os.path.join(HERE, "ios-screens", "jobs.json")

def cfg_for(name, s):
    c = {"screen": s["screen"]}
    if s["screen"] == "chat":
        c.update(user=s["user"], intro=s["intro"], prayer=s["prayer"],
                 verses=[{"ref": r, "text": verse(r), "context": ctx} for r, ctx in s["verses"]],
                 timing={"type": 1.3, "send": 1.6, "intro": 2.1, "gap": 0.5})
    elif s["screen"] == "home":
        c.update(greeting=s["greeting"], streak=s["streak"], verse={"ref": s["ref"], "text": verse(s["ref"])})
    else:
        c.update(verse={"ref": s["ref"], "text": verse(s["ref"])}, templates=s["templates"],
                 per=s["dur"] / len(s["templates"]))
    return c

if __name__ == "__main__":
    pick = set(sys.argv[1:])
    jobs = [{"out": f"../ads/screens/ios/{n}", "dur": s["dur"], "fps": FPS, "cfg": cfg_for(n, s)}
            for n, s in IOS_SCREENS.items() if not pick or n in pick]
    json.dump(jobs, open(JOBS, "w"), indent=1)
    subprocess.run(["node", os.path.join(HERE, "ios-screens", "render_ios_screens.js"), JOBS], check=True)
