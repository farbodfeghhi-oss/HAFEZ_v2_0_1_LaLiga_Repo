# HAFEZ v2.0.1 — La Liga (Rolling-Back) — Quickstart (Windows)

## 1) اجرای داشبورد با داده‌های آماده
- فایل‌ها در `public/data/` قرار دارند (MD1..5).
- برای اجرای سریع:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\Run-Me-Plus.ps1 -Mode metrics -Season "2025-26" -AutoRange -OpenUI -DashboardPath "public\index.html" -OpenServer
```

## 2) به‌روزرسانی داده‌ها
- بعد از افزودن/ویرایش JSON در `public/data/`، می‌توانید DataPack بسازید:
```powershell
python scripts\datapack_pack.py 2025-26
```
- یا از GitHub Actions استفاده کنید: تب Actions → **Build & Commit DataPack** → `season=2025-26` → Run.

## 3) محل فایل‌ها
```
public/index.html                # داشبورد Pro
public/assets/hafez_bench_bg.svg # تصویر پس‌زمینه
public/data/*.json               # داده‌ها (RB/Conservative/Risky/Shortlist/Corners/Actuals_Extended)
scripts/datapack_pack.py         # ساخت DataPack zip
.github/workflows/datapack-build.yml  # ورک‌فلو تولید DataPack و commit
scripts/windows/Start-LocalServer.ps1 # اجرای سرور محلی ساده
Run-Me-Plus.ps1                  # اسکریپت جامع fetch/metrics/open/git
```

## 4) نکات
- نام فصل باید با خط‌تیره معمولی باشد: `2025-26`
- اگر داشبورد مستقیماً با `file://` باز شود، مرورگر ممکن است `fetch` را بلاک کند → از سرور محلی استفاده کنید.
