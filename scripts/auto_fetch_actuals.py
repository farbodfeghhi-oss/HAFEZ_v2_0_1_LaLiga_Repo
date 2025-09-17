
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Auto-fetch actuals from FBref/Understat for all eligible matchdays.
It scans public/data for RB_ALL + Actuals_Extended files and runs the fetcher
for those weeks that are missing or appear incomplete.

Usage:
  python scripts/auto_fetch_actuals.py --season 2025-26 --data-dir public/data
"""
import argparse, json, re, subprocess, sys
from pathlib import Path

def md_numbers_for(season: str, data_dir: Path):
    r = []
    for p in sorted(data_dir.glob(f"HAFEZ_LaLiga_{season}_MD*_RB_ALL.json")):
        m = re.search(r"_MD(\d+)_RB_ALL\.json$", p.name)
        if m:
            r.append(int(m.group(1)))
    return sorted(set(r))

def needs_enrich(fpath: Path) -> bool:
    # If file missing -> True
    if not fpath.exists():
        return True
    try:
        data = json.loads(fpath.read_text(encoding="utf-8"))
        # If any of these are None for any match, we consider it enrichable.
        for m in data.get("matches", []):
            if m.get("halftime_score") is None or m.get("xG",{}).get("home") is None or m.get("corners_total") is None:
                return True
    except Exception:
        return True
    return False

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--season", required=True)
    ap.add_argument("--data-dir", default="public/data")
    args = ap.parse_args()

    data_dir = Path(args.data_dir)
    mds = md_numbers_for(args.season, data_dir)
    print("Found RB weeks:", mds)

    todo = []
    for md in mds:
        target = data_dir / f"HAFEZ_LaLiga_{args.season}_MD{md}_Actuals_Extended.json"
        if needs_enrich(target):
            todo.append(md)

    if not todo:
        print("No matchdays need enrichment.")
        return

    print("Enriching:", todo)
    for md in todo:
        cmd = [
            sys.executable, "scripts/fetch_actuals_fbref_understat.py",
            "--season", args.season, "--matchday", str(md), "--data-dir", str(data_dir),
            "--name-map", "mappings/name_maps_la_liga.json"
        ]
        print("Running:", " ".join(cmd))
        subprocess.check_call(cmd)

if __name__ == "__main__":
    main()
