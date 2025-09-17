
# HAFEZ — Automation & Metrics UI Add-on

## What you get
- **Scheduled Actuals Fetch** (daily) → تکمیل خودکار `Actuals_Extended` با FBref/Understat
- **Scheduled Metrics Build** (weekly) → تولید خودکار Calibration / Buckets / RPS / Accuracy
- **Metrics UI** (static) → صفحه‌ی ساده در `public/metrics/index.html`

## How to install
1) محتویات این بسته را در ریشه‌ی ریپو کپی کنید (فولدرها: `scripts/`, `.github/workflows/`, `public/metrics/`, `docs/`).
2) Commit & Push.
3) در تب **Actions** دو workflow جدید خواهید دید:
   - **Scheduled Fetch Actuals** (با cron روزانه 03:30 UTC) – همچنین دستی قابل اجراست.
   - **Scheduled Build Metrics** (با cron هر دوشنبه 04:00 UTC) – همچنین دستی قابل اجراست.

> ساعت‌های بالا UTC هستند؛ GitHub از UTC استفاده می‌کند. اگر خواستید زمان دیگری باشد، فیلد `cron` را تغییر دهید.

## Manual runs
- **Fetch actuals** فوراً:
  - از تب Actions → Scheduled Fetch Actuals → Run workflow → در صورت نیاز مقدار `season` را تغییر دهید.
- **Build metrics** فوراً:
  - از تب Actions → Scheduled Build Metrics → Run workflow.

## Notes
- اسکریپت `scripts/auto_fetch_actuals.py` همهٔ هفته‌هایی را که نقص دارند شناسایی و فقط همان‌ها را enrich می‌کند.
- UI ساده‌ی `public/metrics/index.html` به فایل‌هایی که CI تولید می‌کند لینک می‌دهد.
- اگر ساختار داده‌های FBref/Understat تغییر کند، فقط لازم است اسکریپت‌های داخل `scripts/` را به‌روزرسانی کنید.
