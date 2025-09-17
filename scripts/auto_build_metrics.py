
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import argparse, re, json, subprocess, sys
from pathlib import Path

def detect_end_md(season: str, data_dir: Path) -> int:
    mds = []
    for p in data_dir.glob(f"HAFEZ_LaLiga_{season}_MD*_RB_ALL.json"):
        m = re.search(r"_MD(\d+)_RB_ALL\.json$", p.name)
        if m:
            mds.append(int(m.group(1)))
    return max(mds) if mds else 0

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--season", required=True)
    ap.add_argument("--data-dir", default="public/data")
    ap.add_argument("--out-dir", default="public/metrics")
    args = ap.parse_args()

    end_md = detect_end_md(args.season, Path(args.data_dir))
    if end_md == 0:
        print("No RB weeks found; skipping metrics.")
        return

    cmd = [sys.executable, "scripts/make_metrics.py", "--season", args.season,
           "--start-md", "1", "--end-md", str(end_md), "--data-dir", args.data_dir, "--out-dir", args.out_dir]
    print("Running:", " ".join(cmd))
    subprocess.check_call(cmd)

if __name__ == "__main__":
    main()
