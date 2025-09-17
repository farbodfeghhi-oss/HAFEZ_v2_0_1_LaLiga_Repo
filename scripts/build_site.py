import shutil, os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
public = ROOT / "public"
site = ROOT / "site"
if site.exists():
    shutil.rmtree(site)
site.mkdir(parents=True, exist_ok=True)

def cp(src_glob, dst_subdir=""):
    dst = site / dst_subdir
    dst.mkdir(parents=True, exist_ok=True)
    for p in public.rglob(src_glob):
        if p.is_file():
            rel = p.relative_to(public)
            out = site / rel
            out.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(p, out)

# copy index, assets, data, metrics, datapack zips if any
cp("index.html")
cp("assets/*")
cp("data/*.json")
cp("metrics/*")
cp("datapack/*.zip")

print("Site assembled at:", site)
