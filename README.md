# Gunpla Vault

**Build. Collect. Remember.**

Native iOS companion app for Gunpla collectors.

## Open in Xcode

```bash
open GunplaVault.xcodeproj
```

## Phase 5 — Launch Prep

### Brand & Splash
- **App icon** — mecha helmet in hexagon (`Assets.xcassets/AppIcon`)
- **4-stage splash** — Initialize → Assembling → Powering Up → Final logo
- **Launch screen** — adaptive background color matching app theme
- Regenerate icons: `./Scripts/generate_app_icons.sh`

### Legal & About
- **Profile → Privacy Policy / Terms of Use**
- Version number shown on Profile

### Accessibility
- Reduce Motion skips splash animation
- VoiceOver labels on welcome, splash, and primary actions

### Before App Store / TestFlight
1. Enroll in [Apple Developer Program](https://developer.apple.com/programs/) ($99/year)
2. Configure App Store Connect listing, screenshots, description
3. Add real `Secrets.plist` for production Supabase
4. Archive in Xcode → Distribute → TestFlight
5. Update contact emails in `LegalViews.swift` when domain is live

## Phase 4 Features

### Analytics & Insights (Pro charts + free basics)
- **Overview** — total kits, completion rate, kits added this year
- **Collection** — backlog / building / completed + timeline bar chart (Pro)
- **Spending** — total spent, average price per kit
- **Grade donut chart** (Pro) — collection breakdown by grade
- **Export CSV / PDF** (Pro) — share via system share sheet

### Virtual Shelves
- Photo shelves for your physical displays
- **Free:** 1 shelf · **Pro:** unlimited
- Profile → Virtual Shelves

### Achievements
- 9 unlockable badges (First Kit, Collector, Master Builder, etc.)
- Shown on Profile with progress count

## Access Points

| Feature | Path |
|---------|------|
| Analytics | Home → Insights card, or Profile → Analytics |
| Shelves | Profile → Virtual Shelves |
| Achievements | Profile scroll section |
| Export | Analytics → Export CSV / PDF (Pro) |
| Legal | Profile → Privacy Policy / Terms |

## Testing

1. Run on simulator — splash animation on cold launch
2. Settings → Accessibility → Reduce Motion — splash should skip to logo
3. Profile → verify version, Privacy, Terms
4. Home screen icon should show brand helmet
5. Collection grid should show kit box art for catalog entries
6. Refresh brand logos from design sheet: `python3 Scripts/generate_splash_assets.py`

## Seed database box art

The catalog has **~1,850 real Gunpla kits** (most with box art URLs) sourced from Gunpla Wiki, GunplaDB, and HLJ.

```bash
# Full import pipeline (mobile branch scripts)
python3 Scripts/import_kits_with_images.py

# Wiki-only refresh for existing seed entries
python3 Scripts/fetch_box_art.py
```

## Completed Phases

- **Phase 0** — Architecture, auth, design system
- **Phase 1** — Collection CRUD, seed DB, profile
- **Phase 2** — StoreKit Pro, cloud sync
- **Phase 3** — Build Mode Level B
- **Phase 4** — Analytics, export, shelves, achievements
- **Phase 5** — Icons, splash, legal, launch prep

## Post v1.0

- v1.1 — AI Scanner (Apple on-device, Pro)
- v2.0 — Android
