# Anicca

> Read your energy. Understand yourself.

A chakra-inspired mood & energy tracking app for iOS — SwiftUI, Supabase, RevenueCat, Gemini Flash.

## Stack

- **iOS 17.0+**, SwiftUI, SwiftData
- **Auth & Backend:** Supabase (email, Apple, Google)
- **AI:** Google Gemini Flash 1.5
- **Subscriptions:** RevenueCat
- **Notifications:** UNUserNotificationCenter (local)

## Getting Started

```bash
# 1. Fill in your API keys
cp Secrets.xcconfig.example Secrets.xcconfig
# edit Secrets.xcconfig

# 2. Regenerate Xcode project (if needed)
brew install xcodegen   # if not already installed
./setup.sh

# 3. Open the project
open Anicca.xcodeproj
```

In Xcode:
1. Select the `Anicca` target → Signing & Capabilities → set your Team.
2. Pick a simulator or device and press ⌘R.

## Backend Setup

Run the SQL in [Anicca/Resources/SupabaseSetup.md](Anicca/Resources/SupabaseSetup.md) in your Supabase SQL editor. That file also documents RevenueCat entitlement/product setup.

## Architecture

```
Anicca/
├── AniccaApp.swift           Entry point + app delegate
├── Config/                   AppConfig, SupabaseConfig, Strings
├── Theme/                    AniccaTheme (single source of truth)
├── Models/                   EnergyCenter, Emotion, CheckIn, UserProfile, AIInsight, AppError, EmotionLibrary
├── Services/                 Auth, CheckIn, Insights, AI (Gemini), Notifications, RevenueCat, Entitlements, Export, Yggdrasil stub
├── ViewModels/               One per feature surface
├── Views/
│   ├── Auth/                 Splash, AuthView
│   ├── Onboarding/           OnboardingView (4 steps)
│   ├── Home/                 HomeView
│   ├── Log/                  LogView
│   ├── Insights/             InsightsView, RadarChartView, CheckInDetailView
│   ├── Paywall/              PaywallView
│   ├── Settings/             SettingsView
│   └── Shared/               ShareSheet
├── Extensions/               Color+Hex, Date+Helpers, View+Modifiers (cards, mesh gradient)
└── Resources/                Info.plist, SupabaseSetup.md, Assets.xcassets
```

## Secrets

All secrets live in `Secrets.xcconfig` at the project root. The file is gitignored. `Secrets.xcconfig.example` documents the required keys:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GEMINI_API_KEY`
- `REVENUECAT_API_KEY`
- `GOOGLE_CLIENT_ID` (optional — for Google Sign-In)
- `GOOGLE_URL_SCHEME` (optional — reversed Google client ID)

These are surfaced through `Info.plist` substitution and read in `AppConfig.swift`. No secrets appear in Swift source.

## Free vs Pro

Free users get 30 check-ins/month, the radar chart, and a 7-day timeline. Pro unlocks unlimited check-ins, the AI weekly insight (Gemini), 14-day/monthly timeline, weekly summary, streak tracking, reminders, and PDF export. Bundle adds the Yggdrasil integration (interface defined; implementation reserved for a future release).
