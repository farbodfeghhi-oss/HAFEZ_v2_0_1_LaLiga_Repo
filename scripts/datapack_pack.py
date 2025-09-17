import json, re, sys, zipfile
from pathlib import Path

def main():
    data_dir = Path("public/data")
    out = Path("artifacts")
    out.mkdir(parents=True, exist_ok=True)
    season = sys.argv[1] if len(sys.argv)>1 else "2025-26"
    rx = re.compile(rf"HAFEZ_LaLiga_{re.escape(season)}_MD(\d+)_.+\.json$")
    files = sorted([p for p in data_dir.glob(f"HAFEZ_LaLiga_{season}_MD*_*.json")])
    if not files:
        print("No files to package.")
        sys.exit(0)
    zpath = out / f"HAFEZ_LaLiga_{season}_DataPack.zip"
    with zipfile.ZipFile(zpath, "w", zipfile.ZIP_DEFLATED) as z:
        for p in files:
            z.write(p, p.name)
    print("DataPack:", zpath)

if __name__ == "__main__":
    main()
