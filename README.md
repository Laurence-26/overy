# Cyclus — fully offline cycle tracker

A private Flutter app for **period**, **conception**, and **pregnancy**.
All data stays on the phone. There is no Firebase, no Google sign-in, and no
network required for tracking, predictions, or reminders.

---

## Features

- **On-device profiles** — name + password, stored only on this phone
- **Three modes** she can switch anytime: Period, Conceive, Pregnancy
- **Adaptive predictions** — weighted recent cycles, outlier filtering, learned
  luteal length from OPK / ovulation-pain / mucus logs, date ranges when irregular
- **Personalized notifications** — her name, mode, usual symptoms, vitamin and
  trimester reminders
- **Mode-aware home, calendar, insights, and daily log**
- **Local partner PIN** — a partner profile on the same device can follow her cycle
- **Local reminders** via `flutter_local_notifications`

---

## Run

```bash
cd cyclus
flutter pub get
flutter run
```

Android release:

```bash
flutter build apk --release
```

No Firebase project or internet account is needed.

---

## Architecture

```
lib/
├── main.dart                 # local store + notifications
├── app.dart
├── core/                     # colors, theme, constants
├── models/
├── services/
│   ├── local_store.dart      # SharedPreferences JSON
│   ├── auth_service.dart     # on-device accounts
│   ├── cycle_service.dart
│   ├── prediction_engine.dart
│   ├── personalization_service.dart
│   └── notification_service.dart
├── providers/
└── screens/
```

Predictions live in `lib/services/prediction_engine.dart` (pure functions, unit-tested).
