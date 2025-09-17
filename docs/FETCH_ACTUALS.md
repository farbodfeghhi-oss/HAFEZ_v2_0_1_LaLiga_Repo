# Fetch Actuals — FBref + Understat (La Liga)

این بسته اسکریپت و ورک‌فلو برای تزریق خودکار داده‌های واقعی به `*_Actuals_Extended.json` را فراهم می‌کند.

## فایل‌ها
- `scripts/fetch_actuals_fbref_understat.py`
- `scripts/team_aliases_laliga.json`
- `.github/workflows/fetch-actuals.yml`

## اجرا در لوکال (Windows)
1) Python 3.10+ نصب کن، سپس:
   ```bat
   pip install requests beautifulsoup4 lxml
   python scripts\fetch_actuals_fbref_understat.py --season 2025-26 --matchday 4 --data_dir public\data
   ```
2) اگر داده پیدا شود، فایل هدف همان‌جا به‌روز می‌شود.

## اجرا در GitHub Actions
- تب **Actions** → Workflow **Fetch Actuals (FBref + Understat)** → Run.
- ورودی‌ها: `season=2025-26`, `matchday=5`.
- اگر داده‌ای تغییر کند، اتوماتیک commit/push می‌شود.

## نکات
- اگر نام تیمی هماهنگ نبود، فایل `scripts/team_aliases_laliga.json` را اصلاح کن.
- برای corner/xG/first goal مواردی که در یک منبع نبود از منبع دیگر پر می‌شود؛ اگر هردو در دسترس نباشند مقدار `null` باقی می‌ماند.
