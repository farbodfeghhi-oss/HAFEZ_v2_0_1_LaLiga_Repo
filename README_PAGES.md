# HAFEZ — GitHub Pages Automation

## What this adds
- **Workflow**: `.github/workflows/refresh-build-deploy.yml`
  - Trigger: on `push` to data/public files or manual `workflow_dispatch`
  - Steps: (optional) Fetch → Build metrics → Package DataPack → Assemble `site` → Deploy to **GitHub Pages**
- **Helper**: `scripts/build_site.py` (copies `public/*` to `site/`)
- **Local Publisher**: `Publish-GHPages.ps1` (اختیاری؛ اگر می‌خواهید بدون Actions روی `gh-pages` پابلیش کنید)

## One-time GitHub setup
1. Settings → Pages → Source = **GitHub Actions**.
2. Settings → Actions → General → Workflow permissions = **Read and write**.

## Manual run
- Actions → **Refresh, Build & Deploy Dashboard** → Run → (season=`2025-26`, do_fetch=`false` or `true`, matchday as needed).

## Local publish (optional)
```powershell
# در ریشهٔ ریپو
python scripts\build_site.py         # ساخت فولدر site
.\Publish-GHPages.ps1 -BuildSite     # انتشار روی gh-pages
```
