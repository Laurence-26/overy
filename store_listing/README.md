# Cyclus — Google Play listing pack (REAL device UI)

Screenshots and the demo video are built from **actual Android captures of your APK**, not AI mockups.

## What’s inside

| Asset | Path | Source |
|---|---|---|
| AAB | `Cyclus.aab` / `../Cyclus.aab` | Flutter release bundle |
| Phone screenshots | `screenshots/*.png` | Your WhatsApp device photos of Cyclus |
| Feature graphic | `graphics/feature_graphic.png` | Soft pink banner + **your real Today screens** in phone frames |
| App icon | `graphics/play_icon_512.png` | Flower icon for Play |
| Demo video | `demo_slideshow.mp4` | Slideshow of the real screenshots |
| Descriptions | `short_description.txt`, `long_description.txt` | Copy/paste into Play Console |
| Privacy | `privacy_policy.html` | Host publicly, paste URL |

## Rebuild from device photos

1. Drop more real phone screenshots into Cursor chat (Calendar / Insights preferred).
2. Or add files under `assets/` and update `build_from_device_shots.py`.
3. Run:

```powershell
python store_listing\build_from_device_shots.py
```

## Better promo video

Record 30–40s on the phone with Android’s built-in recorder while tapping through Today → Card view → Calendar → Theme studio → Log period. Upload to YouTube and paste the link in Play Console. The slideshow is only a stand-in until you record live.

## Signing

Release builds still use the debug keystore. Create an upload key before production Play publishing.
