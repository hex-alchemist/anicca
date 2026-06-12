# Anicca — Collaborator Onboarding & Ticket Backlog

**Project:** Anicca (chakra-inspired mood & energy tracking iOS app) · Screen Sage Studios
**Stack:** iOS 17+ · SwiftUI · SwiftData · Supabase · Gemini 2.5 Flash · RevenueCat
**Goal:** App Store launch by end of July 2026, hard deadline mid-August 2026
**[Linear project →](https://linear.app/yggdrasil-journal/team/SS/overview)**

---

## Table of Contents

1. [Welcome & Project Context](#1-welcome--project-context)
2. [The App](#2-the-app)
3. [Tech Stack](#3-tech-stack)
4. [Setup: Your Development Environment](#4-setup-your-development-environment)
5. [Codebase Structure](#5-codebase-structure)
6. [Architecture Patterns You Need to Know](#6-architecture-patterns-you-need-to-know)
7. [Coding Standards](#7-coding-standards)
8. [Supabase Data Model](#8-supabase-data-model)
9. [Working on a Task](#9-working-on-a-task)
10. [Git Workflow & Pull Requests](#10-git-workflow--pull-requests)
11. [Testing](#11-testing)
12. [Design System](#12-design-system)
13. [Deployment & Release](#13-deployment--release)
14. [Things You Must Not Do](#14-things-you-must-not-do)
15. [Resources](#15-resources)
16. [Ticket Backlog](#ticket-backlog)

---

## 1. Welcome & Project Context

Anicca is an iOS app for mood and energy tracking built around the 7 chakra energy centers. Users log how they feel — by typing freely (Gemini maps the text to emotions and energy centers) or by browsing a curated emotion library — and the app surfaces patterns, balance scores, and AI-generated weekly insights.

The name *Anicca* (Pāli for "impermanence") reflects the philosophy: feelings and states of energy are always changing, and the app helps you witness and understand those shifts without judgment.

**Target launch:** App Store, end of July 2026 (hard cap mid-August).

### What you need to know about working here

Isa owns all architecture and App Store decisions. Collaborators implement clearly scoped, self-contained tasks. If anything is unclear — **ask before starting**. The codebase is substantially built; most remaining work is polish, fixes, and content-layer work, not new infrastructure.

The app also has a companion app, **Yggdrasil** (a separate Next.js journaling app). They are **completely different codebases and different projects**. Do not mix them up.

---

## 2. The App

Anicca has four main tabs:

| Tab | What it does |
|---|---|
| **Home** | Greeting, quick stats (streak, week count, most active center), a "Log now" card, and a Pro-gated AI suggestion for the user's most underactive center. |
| **Log** | Default view is a free-text field — type how you feel, tap "Map my feelings," and Gemini maps the text to emotions and energy centers. Users can also browse the emotion library directly. After selecting emotions, an intensity sheet (sliders 1–5) captures depth before saving. |
| **Insights** | Radar chart (balance across 7 centers), weekly summary, mood timeline (day dots), centers breakdown (entry counts + status badges), Pro-gated AI weekly insight, and a recent check-ins list with swipe-to-delete. |
| **Settings** | Account info, subscription management, Pro-gated reminders, data export (JSON free / PDF Pro), Yggdrasil web link, app version + developer override, privacy/terms/rate, sign out, and delete account. |

### Subscription tiers

| Feature | Free | Pro |
|---|---|---|
| Check-ins per month | 30 | Unlimited |
| Radar chart | ✅ (7-day) | ✅ (14-day + all-time) |
| Mood timeline | ✅ (7-day) | ✅ (14-day + monthly) |
| Centers breakdown | ✅ | ✅ |
| Streak tracking | ❌ | ✅ |
| Daily reminders | ❌ | ✅ |
| Weekly summary | ❌ (blurred) | ✅ |
| AI weekly insight | ❌ (blurred) | ✅ |
| Today's suggestion | ❌ | ✅ |
| PDF export | ❌ | ✅ |
| JSON export | ✅ | ✅ |
| Bundle (Yggdrasil integration) | ❌ | Post-launch, out of scope |

Free users hit a paywall at 30 check-ins/month and at 25 (warning threshold). They can upgrade to Pro at $4.99/month or $39.99/year.

### The 7 energy centers

Anicca is built around 7 chakras, each with a domain of emotional experience:

| Center | Domain | Color |
|---|---|---|
| Root | Safety & security | Red `#C0392B` |
| Sacral | Creativity & flow | Orange `#E67E22` |
| Solar Plexus | Power & confidence | Yellow `#F1C40F` |
| Heart | Love & compassion | Green `#27AE60` |
| Throat | Expression & truth | Blue `#2980B9` |
| Third Eye | Intuition & insight | Indigo `#3F51B5` |
| Crown | Connection & transcendence | Violet `#8E44AD` |

---

## 3. Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9, strict concurrency (`SWIFT_STRICT_CONCURRENCY = complete`) |
| UI | SwiftUI, iOS 17.0+ |
| Local persistence | SwiftData (`@Model` classes: `CheckIn`, `EmotionEntry`, `UserProfile`) |
| Cloud sync & auth | Supabase Swift 2.0+ (`Supabase`, `Auth`, `PostgREST`) |
| AI | Google Gemini 2.5 Flash — called **directly from the device** via REST |
| Subscriptions | RevenueCat 5.0+ (`Purchases`) |
| Sign-in | Supabase email/password, `AuthenticationServices` (Apple), `GoogleSignIn-iOS` 7.0+ |
| Payments | StoreKit (via RevenueCat) |
| Notifications | `UNUserNotificationCenter` (local only — no push infrastructure) |
| Export | `PDFKit` |
| Project generation | XcodeGen (`project.yml` → `Anicca.xcodeproj`) |

**Dependencies are declared in `project.yml` and resolved via Swift Package Manager.** Never add packages manually in Xcode — regenerate the project via `./setup.sh` after editing `project.yml`.

---

## 4. Setup: Your Development Environment

### Prerequisites

- **Xcode 16** or later
- **XcodeGen** — `brew install xcodegen`
- **Git**

### Clone and generate the project

```bash
git clone https://github.com/astrayama/anicca.git
cd anicca
./setup.sh        # generates Anicca.xcodeproj from project.yml
open Anicca.xcodeproj
```

`setup.sh` runs `xcodegen generate`. Re-run it whenever `project.yml` changes.

### Secrets

Copy the example secrets file and fill in values Isa provides:

```bash
cp Secrets.xcconfig.example Secrets.xcconfig
```

**Never commit `Secrets.xcconfig`.** It is in `.gitignore`.

| Key | What it's for |
|---|---|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase public anon key |
| `GEMINI_API_KEY` | Google Gemini API key |
| `REVENUECAT_API_KEY` | RevenueCat public iOS API key |
| `GIDClientID` | Google Sign-In OAuth client ID |
| `GOOGLE_URL_SCHEME` | Reversed Google client ID for URL scheme |

### Run the app

Open `Anicca.xcodeproj`, select a simulator or connected device, and run. You can test on any iOS 17+ simulator or physical device. **Only Isa submits to TestFlight and the App Store.**

---

## 5. Codebase Structure

```
Anicca/
├── project.yml                     # XcodeGen project definition — source of truth
├── setup.sh                        # Run this to regenerate Anicca.xcodeproj
├── Secrets.xcconfig                # Local secrets — NOT committed
├── Secrets.xcconfig.example        # Committed template with keys but no values
│
└── Anicca/
    ├── AniccaApp.swift             # App entry point, AppDelegate, AppRouter
    ├── Assets.xcassets             # App icon, colors, images
    │
    ├── Config/
    │   ├── AppConfig.swift         # Secrets + constants (limits, keys, URLs)
    │   └── Strings.swift           # All user-facing strings — use these, no raw literals
    │
    ├── Models/
    │   ├── CheckIn.swift           # @Model CheckIn + EmotionEntry; DTOs for Supabase
    │   ├── EnergyCenter.swift      # enum EnergyCenter (7 cases) + CenterStatus
    │   ├── Emotion.swift           # struct Emotion (name, center, valence, synonyms)
    │   ├── EmotionLibrary.swift    # Static library of all emotions by center
    │   ├── AIInsight.swift         # AIInsight struct + Supabase DTOs
    │   ├── UserProfile.swift       # @Model UserProfile + PlanTier enum + DTOs
    │   └── AppError.swift          # Typed error enum used throughout the app
    │
    ├── Services/
    │   ├── AuthService.swift       # Supabase auth (email/Apple/Google), profile CRUD
    │   ├── CheckInService.swift    # Offline-first save, Supabase sync, retry
    │   ├── InsightsService.swift   # Pure analytics: balance, streak, timeline, status
    │   ├── AIService.swift         # Gemini: weekly insight + center suggestion
    │   ├── EmotionMappingService.swift  # Gemini: free-text → emotion list
    │   ├── EntitlementManager.swift     # Publishes planTier, exposes isPro/isBundle
    │   ├── RevenueCatService.swift      # RevenueCat SDK wrapper
    │   ├── NotificationService.swift    # Local daily reminders, 7 weekday messages
    │   ├── ExportService.swift          # JSON (free) + PDF (Pro) export
    │   └── YggdrasilIntegrationProtocol.swift  # STUB — reserved for post-launch
    │
    ├── ViewModels/
    │   ├── AuthViewModel.swift
    │   ├── OnboardingViewModel.swift
    │   ├── LogViewModel.swift      # Manages all log flow state + saving
    │   ├── InsightsViewModel.swift
    │   ├── PaywallViewModel.swift
    │   └── SettingsViewModel.swift
    │
    ├── Views/
    │   ├── MainTabView.swift       # Root tab bar (Home, Log, Insights, Settings)
    │   ├── Auth/
    │   │   ├── SplashScreen.swift
    │   │   └── AuthView.swift
    │   ├── Home/
    │   │   └── HomeView.swift
    │   ├── Log/
    │   │   ├── LogView.swift               # Coordinator (routes modes)
    │   │   ├── FreeTextEntryView.swift     # Default check-in screen (Gemini mapping)
    │   │   ├── EmotionMappingResultView.swift  # Shows Gemini-mapped emotions
    │   │   └── EmotionBrowseView.swift     # Manual browse/search emotion library
    │   ├── Insights/
    │   │   ├── InsightsView.swift
    │   │   ├── RadarChartView.swift
    │   │   └── CheckInDetailView.swift
    │   ├── Onboarding/
    │   │   └── OnboardingView.swift        # 4 steps: welcome, centers, how it works, reminders
    │   ├── Paywall/
    │   │   └── PaywallView.swift
    │   ├── Settings/
    │   │   └── SettingsView.swift
    │   └── Shared/
    │       └── ShareSheet.swift
    │
    ├── Theme/
    │   └── AniccaTheme.swift       # Colors, spacing, radius, animations, typography
    │
    ├── Extensions/
    │   ├── View+Modifiers.swift    # .aniccaCard(), etc.
    │   ├── Date+Helpers.swift
    │   └── Color+Hex.swift
    │
    └── Resources/
        ├── Info.plist
        └── SupabaseSetup.md        # SQL + RLS setup instructions for Supabase
```

---

## 6. Architecture Patterns You Need to Know

### MVVM — one ViewModel per feature surface

Views are dumb. All business logic, state, and service calls live in the corresponding ViewModel. `@StateObject` in the view, `@Published` properties in the VM, `@EnvironmentObject` for globally shared state (`AuthService`, `EntitlementManager`).

```swift
// ✅ Logic in the ViewModel
await viewModel.mapFreeText()

// ❌ Never call services directly from a View
await EmotionMappingService.shared.mapFreeText(text)
```

### Offline-first: SwiftData first, Supabase second

`CheckInService.saveCheckIn()` writes to SwiftData immediately, then syncs to Supabase asynchronously. A `syncedToSupabase: Bool` flag on `CheckIn` tracks unsynced records. `retryUnsyncedCheckIns()` is called on every app foreground.

Do not make the UI wait on Supabase. The local write is the source of truth for display; the remote sync is background work.

### Gemini is called directly from the device

Unlike Yggdrasil (which routes all AI through Cloud Functions), Anicca calls the Gemini REST API **directly from the device** using a URLSession actor. The API key lives in `Secrets.xcconfig` and is read via `AppConfig.geminiAPIKey` from the Info.plist at runtime.

This means the key is embedded in the app binary. It is gated appropriately (not exposed in source control). Do not log it, expose it to the UI, or include it in error messages.

```swift
// ✅ Use the shared actors
await AIService.shared.generateWeeklyInsight(checkIns: checkIns)
await EmotionMappingService.shared.mapFreeText(text)

// ❌ Never instantiate a new Gemini caller
```

### EntitlementManager drives all Pro gating

`EntitlementManager` (an `@EnvironmentObject` injected at the root) is the single source of truth for the user's plan. Read from it; never check `UserProfile.planTier` directly in views.

```swift
// ✅
@EnvironmentObject private var entitlements: EntitlementManager
if entitlements.isPro { ... }

// ❌
if auth.currentUser?.planTier == .pro { ... }
```

Pro state also syncs with RevenueCat on every foreground. The developer override (5-tap version tap in Settings) writes to `UserDefaults` key `developer_override_pro` and is surfaced by `EntitlementManager`.

### SwiftData context management

The `ModelContainer` is created in `AniccaApp.init()` and injected via `.modelContainer()`. `CheckInService` receives `mainContext` via `setContext(_:)` called from `.onAppear` on the root view. Do not create secondary contexts or pass the container around.

### Routing

`AppRouter` (an `@StateObject` on `AniccaApp`) owns the top-level route: `.splash → .auth → .onboarding → .main`. Within the main tab bar, `router.selectedTab` controls which tab is active — `NotificationService` deep-links to `.log` on notification tap.

---

## 7. Coding Standards

### Swift conventions

- Swift 5.9 with strict concurrency (`SWIFT_STRICT_CONCURRENCY = complete`). All async code must be properly isolated; suppress warnings only with a documented reason.
- `@MainActor` on all ViewModels and Services that touch UI. `actor` for pure data services (`AIService`, `EmotionMappingService`).
- `async`/`await` everywhere. No completion handlers. Use `try/catch` — do not swallow errors silently.
- No `force-unwrap` (`!`) except where the compiler cannot know something is non-nil and the invariant is obvious (e.g., a URL from a compile-time string literal). Add a comment when you do.
- Use types from `Models/` for all domain objects. Do not redefine inline.

### UI conventions

- **SwiftUI only.** No UIKit views unless wrapping a missing system component.
- Use `AniccaTheme` tokens for all colors, spacing, and typography. No magic numbers or hex strings in views.
- Use `.aniccaCard()` (from `View+Modifiers.swift`) for card containers. Use `.anicca(_:)` text modifier for all body copy.
- `MeshGradientBackground()` on the root `ZStack` of every full-screen view.
- Use strings from `Strings.swift` — never raw string literals in views.

### No stubs or TODOs

If you can't complete the full implementation in one pass, flag it in the PR and describe what's missing. Do not commit placeholder comments or disabled code paths.

---

## 8. Supabase Data Model

Full SQL and RLS setup is in `Anicca/Resources/SupabaseSetup.md`. Here is the schema at a glance:

```
profiles
    id           uuid  (mirrors auth.users.id)
    email        text
    display_name text
    plan_tier    text  ('free' | 'pro' | 'bundle')
    check_in_streak      integer
    last_check_in_date   timestamptz
    total_check_ins      integer
    reminder_enabled     boolean
    reminder_time        timestamptz
    yggdrasil_user_id    text  (reserved — null until post-launch integration)
    created_at   timestamptz

check_ins
    id           uuid
    user_id      uuid  → profiles(id)  ON DELETE CASCADE
    note         text  (optional free-text note attached to the check-in)
    created_at   timestamptz

emotion_entries
    id           uuid
    check_in_id  uuid  → check_ins(id) ON DELETE CASCADE
    user_id      uuid  → profiles(id)  ON DELETE CASCADE
    emotion_name text
    energy_center text
    intensity    integer  (1–5)
    created_at   timestamptz

ai_insights
    id           uuid
    user_id      uuid  → profiles(id)  ON DELETE CASCADE
    week_start   date
    insight_text text
    dominant_center      text
    suggested_practices  text[]
    created_at   timestamptz
    UNIQUE(user_id, week_start)
```

**RLS is enabled on all tables.** Each user can only access rows where `user_id = auth.uid()`. The `profiles` table uses `id = auth.uid()`. There are no admin-write paths from the client — plan tier is updated via `AuthService.updatePlanTier()` (called after RevenueCat entitlement check, not by the user directly).

**Cascade deletes** are set up so deleting a `profiles` row removes all associated `check_ins`, `emotion_entries`, and `ai_insights`. This is what the delete account flow relies on.

---

## 9. Working on a Task

### Before you start

- Read the full ticket before writing any code — acceptance criteria are the contract.
- Check `Models/` for the relevant data shapes.
- Check `Views/Shared/` and `Theme/AniccaTheme.swift` for existing components and tokens.
- Check `Strings.swift` for string keys before adding new ones.
- **If anything is unclear — ask Isa on Discord before starting.**

### Scope discipline

Do not reach outside the ticket boundaries. If you notice something adjacent that needs fixing, flag it in the PR description — do not silently fix it. Isa handles integration between components.

### Communication

Discord DM `@isa23_` for questions. Ask clearly in one message rather than sending a chain of follow-ups.

---

## 10. Git Workflow & Pull Requests

### Branch naming

Branch off `main`. Prefix:

| Type | Pattern | Example |
|---|---|---|
| Feature | `feat/<description>` | `feat/circumplex-emotion-library` |
| Bug fix | `fix/<description>` | `fix/fretext-keyboard-dismiss` |
| Docs/content | `docs/<description>` | `docs/privacy-policy` |
| Chores | `chore/<description>` | `chore/upgrade-supabase-sdk` |

Lowercase, hyphens, no spaces.

### Commit messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short summary, imperative mood>
```

Examples:
```
feat(emotions): replace emotion library with circumplex model
fix(log): add dismiss button to FreeTextEntryView keyboard trap
feat(insights): implement valence trend in weekly summary
```

### PR checklist

Before opening a PR:
- Build succeeds in Release configuration
- No new warnings introduced (strict concurrency is enforced)
- All new strings are in `Strings.swift`
- All new colors/spacing use `AniccaTheme` tokens

PR description must include:
- Which ticket this closes
- Screenshot or screen recording for any UI change
- Any new secret keys that need to be added to `Secrets.xcconfig.example`
- Anything Isa needs to do after merge (e.g., Supabase schema change)

**PRs require Isa's approval before merge. Do not merge your own PR.**

---

## 11. Testing

There is no automated test suite currently. The priority is shipping. Manual testing on both a physical device and a simulator is expected before opening a PR.

**Test the golden path and all error states in your ticket's scope.** If you add business logic (especially to `InsightsService` or `CheckInService`), add unit tests for that logic.

For Gemini-calling code, test with the real API key (provided by Isa) and verify the fallback path when the key is missing or the call fails.

---

## 12. Design System

The visual identity is established. Do not redesign anything without Isa's sign-off.

| Element | Value |
|---|---|
| Background | `#F5F0FA` (lavender-white) |
| Brand primary | `#7C5CBF` (purple) |
| Brand secondary | `#A78BDA` |
| Brand accent | `#C4A8FF` |
| Text primary | `#1A1A2E` |
| Card background | White at 85% opacity |
| Card radius | 20pt |
| Button radius | 14pt |

All tokens are in `AniccaTheme.swift`. Use them.

**Voice and tone:** gentle, grounded, spiritually-aware but secular. Non-coercive, never diagnostic. The app witnesses energy — it does not judge or prescribe.

**Do not:**
- Introduce clinical or dashboard-style UI patterns
- Use alert-style reds or greens for normal states (only for errors/success feedback)
- Add loading spinners that block the UI for local operations
- Use language that sounds like a therapy or health app ("your mental health", "your mood disorder")

---

## 13. Deployment & Release

**Only Isa submits to TestFlight and the App Store.**

You can build and run the app on any iOS 17+ simulator or physical device. To install on a physical device, you need a provisioning profile — ask Isa.

When a feature is ready for Isa to review:
1. Open a PR against `main`
2. Isa reviews, approves, and merges
3. Isa builds and submits the archive when a batch of features is ready

**Supabase schema changes** (new tables, columns, RLS updates) must be documented in the PR and communicated to Isa — they need to be applied to the live project before the build ships.

---

## 14. Things You Must Not Do

| Don't | Why |
|---|---|
| Log or expose `AppConfig.geminiAPIKey` | Key is embedded in the binary; logging it makes it trivially extractable |
| Call Gemini with a hardcoded model string | Always use the constant `"gemini-2.5-flash"` or a named constant — no ad-hoc model upgrades |
| Write to `UserProfile.planTier` directly | Plan tier is set by RevenueCat entitlement check only, via `EntitlementManager` |
| Modify the Supabase schema without a migration note | Schema changes must be communicated to Isa for manual application |
| Add Swift Package dependencies without checking | Ask Isa first — SPM package set is managed in `project.yml` |
| Force-push to `main` | Never |
| Submit to TestFlight or App Store | Only Isa does this |
| Copy anything from the Yggdrasil codebase | Different stack, different patterns, different app |
| Implement the Yggdrasil integration | `YggdrasilIntegrationProtocol` is a stub — it ships as-is; integration is post-launch |
| Silence strict concurrency warnings with `@unchecked Sendable` without a comment | Explain why in a code comment if unavoidable |

---

## 15. Resources

| | |
|---|---|
| **GitHub repo** | `https://github.com/astrayama/anicca` |
| **Linear** | [SS team overview](https://linear.app/yggdrasil-journal/team/SS/overview) |
| **Questions** | Discord DM `@isa23_` |
| **Supabase setup** | `Anicca/Resources/SupabaseSetup.md` |

### Key documentation

| Resource | |
|---|---|
| SwiftUI docs | https://developer.apple.com/documentation/swiftui |
| SwiftData | https://developer.apple.com/documentation/swiftdata |
| Supabase Swift | https://supabase.com/docs/reference/swift/introduction |
| RevenueCat iOS | https://www.revenuecat.com/docs/getting-started/installation/ios |
| Gemini REST API | https://ai.google.dev/api/generate-content |
| UNUserNotificationCenter | https://developer.apple.com/documentation/usernotifications |
| Conventional Commits | https://www.conventionalcommits.org/en/v1.0.0/ |

---

---

# Ticket Backlog

Tickets are **atomic** — each is 1–4 hours of focused work, scoped so a collaborator can pick it up, build it, and verify it against the acceptance criteria without needing to consult Isa for routine decisions.

**Effort key:** S = ~1–2hr · M = ~half day · L = ~full day

**Status key:** ✅ DONE (documented as record) · 🔧 PENDING (actionable)

---

## ✅ Built Features (Record)

*These tickets document what is already implemented. They are not actionable — they exist so collaborators understand what is done and why.*

---

### ✅ SCAF-01 — XcodeGen project scaffold

**What was built**
`project.yml` defines the full Xcode project: bundle ID `com.screensagestudios.anicca`, iOS 17.0+, Swift 5.9, strict concurrency, SPM dependencies (Supabase 2.0+, RevenueCat 5.0+, GoogleSignIn-iOS 7.0+), and system frameworks (AuthenticationServices, StoreKit, SafariServices, UserNotifications, PDFKit). `setup.sh` regenerates `Anicca.xcodeproj` from this file. `Secrets.xcconfig` + `Secrets.xcconfig.example` manage secrets outside version control.

**Key files**
`project.yml`, `setup.sh`, `Secrets.xcconfig.example`, `Anicca/Config/AppConfig.swift`

---

### ✅ SCAF-02 — App entry point, routing, and AppDelegate

**What was built**
`AniccaApp.swift`: `ModelContainer` initialization, environment object injection (`AuthService`, `EntitlementManager`, `RevenueCatService`, `AppRouter`). `AppRouter` drives the top-level route: `.splash → .auth → .onboarding → .main`. `AppDelegate` handles Google Sign-In URL scheme and notification delegation (deep-links to Log tab on notification tap).

**Key files**
`AniccaApp.swift`, `Views/MainTabView.swift`

---

### ✅ THEME-01 — AniccaTheme design system

**What was built**
`AniccaTheme.swift`: all brand colors (background `#F5F0FA`, primary `#7C5CBF`, 7 chakra colors), spacing tokens (s4–s32), corner radii, shadow values, spring animation constant. `AniccaTextStyle` enum + `.anicca(_:)` ViewModifier. `View+Modifiers.swift`: `.aniccaCard()` container modifier. `MeshGradientBackground` renders the animated gradient present on all full-screen views.

**Key files**
`Theme/AniccaTheme.swift`, `Extensions/View+Modifiers.swift`

---

### ✅ MODEL-01 — CheckIn + EmotionEntry SwiftData models

**What was built**
`@Model class CheckIn` (id, userId, createdAt, note, entries, syncedToSupabase). `@Model class EmotionEntry` (id, emotionName, energyCenterRaw, intensity 1–5, checkInId). Supabase DTOs: `CheckInDTO`, `CheckInInsert`, `EmotionEntryDTO`, `EmotionEntryInsert`.

**Key files**
`Models/CheckIn.swift`

---

### ✅ MODEL-02 — EnergyCenter enum

**What was built**
`enum EnergyCenter: String, CaseIterable` with 7 cases. Each case has: `displayName`, `subtitle`, `color` (from AniccaTheme), `sfSymbol`, `number` (1–7), `description`, `fallbackSuggestions` (3 per center). `enum CenterStatus: String` (noData, underactive, balanced, overactive) with display name and color.

**Key files**
`Models/EnergyCenter.swift`

---

### ✅ MODEL-03 — Emotion struct + EmotionLibrary

**What was built**
`struct Emotion: Identifiable, Codable, Hashable` (name, center, valence positive/neutral/negative, sfSymbol, description, synonyms). Deterministic UUID derived from center + name. `EmotionLibrary.swift`: static arrays of ~14 emotions per center (98 total), organized by valence, with synonyms for search and Gemini context.

**Key files**
`Models/Emotion.swift`, `Models/EmotionLibrary.swift`

---

### ✅ MODEL-04 — UserProfile SwiftData model

**What was built**
`@Model class UserProfile` (id, email, displayName, planTierRaw, checkInStreak, lastCheckInDate, totalCheckIns, reminderEnabled, reminderTime, createdAt). `enum PlanTier: String` (free, pro, bundle). `UserProfileDTO` + `UserProfileInsert` for Supabase `profiles` table. `yggdrasil_user_id` field reserved for future integration.

**Key files**
`Models/UserProfile.swift`

---

### ✅ MODEL-05 — AIInsight struct + DTOs

**What was built**
`struct AIInsight` (id, insightText, dominantCenter, suggestedPractices[], weekStart). `AIInsightDTO` and `AIInsightInsert` for Supabase `ai_insights` table (unique per user per week).

**Key files**
`Models/AIInsight.swift`

---

### ✅ MODEL-06 — AppError typed error enum

**What was built**
`enum AppError: LocalizedError` covering authentication errors, network errors, Supabase-specific codes, and generic fallbacks. `SupabaseErrorMapper` converts raw Supabase errors to `AppError`.

**Key files**
`Models/AppError.swift`

---

### ✅ SVC-01 — AuthService

**What was built**
`@MainActor final class AuthService`. Supabase auth: email/password sign-up and sign-in, Apple Sign In (nonce + SHA256), Google Sign In (GIDSignIn). Session restore on app launch. Profile management: `createProfile`, `updateDisplayName`, `updatePlanTier`, `updateReminderSettings`, `updateStreakStats`. Delete account cascades via FK on `profiles` table.

**Key files**
`Services/AuthService.swift`

---

### ✅ SVC-02 — CheckInService

**What was built**
`@MainActor final class CheckInService`. Offline-first: `saveCheckIn()` writes to SwiftData immediately, then calls `syncCheckIn()` async. `retryUnsyncedCheckIns()` runs on every foreground. `fetchLocalCheckIns()`, `loadRemoteCheckIns()` (fetches from Supabase, merges into local). `deleteCheckIn()` (local + best-effort remote). `currentMonthCount()` for free-tier gating.

**Key files**
`Services/CheckInService.swift`

---

### ✅ SVC-03 — InsightsService

**What was built**
Pure struct with no side effects. `balanceScore(for:in:)` (0.0–1.0, normalized to personal average). `dominantCenter(in:)`. `streak(from:)`. `moodTimeline(for:from:)` returns `[Date: EnergyCenter?]`. `centerStatus(score:)` (thresholds: ≤0.35 underactive, ≤0.65 balanced, >0.65 overactive). `entriesInLast(days:from:)`, `topEmotions(in:limit:)`, `valenceTrend(in:)`.

**Key files**
`Services/InsightsService.swift`

---

### ✅ SVC-04 — AIService + EmotionMappingService

**What was built**
`actor AIService`: `generateWeeklyInsight()` uses last 14 days of data (top 5 emotions, valence trend), caches result in Supabase `ai_insights` (one per week), falls back to handcrafted insights per dominant center. `generateCenterSuggestion()` returns a suggestion for the user's most underactive center. System instruction enforces: compassionate, grounded, secular, non-coercive, never diagnostic.

`actor EmotionMappingService`: `mapFreeText(_:)` sends free text to Gemini 2.5 Flash with a structured prompt listing all 98 emotions and their centers; parses JSON response into `[MappedEmotion]` with pre-seeded intensities. Falls back gracefully to browse mode on failure.

Both actors share the same endpoint (`gemini-2.5-flash`) and URLSession configuration (30s request, 45s resource timeout). JSON parsing strips markdown code fences defensively.

**Key files**
`Services/AIService.swift`, `Services/EmotionMappingService.swift`

---

### ✅ SVC-05 — EntitlementManager + RevenueCatService

**What was built**
`@MainActor final class EntitlementManager`: publishes `planTier`, exposes `isPro`, `isBundle`. Developer override via `UserDefaults` key `developer_override_pro` (activated by 5-tap on version label in Settings). Posts `Notification.Name("anicca.planUpgraded")` on upgrade.

`@MainActor final class RevenueCatService`: wraps `Purchases` SDK. `configure(apiKey:)`, `fetchOfferings()`, `purchase(package:)`, `restorePurchases()`, `checkEntitlement()` (maps RevenueCat entitlements `bundle`/`pro` to `PlanTier`). `login(userId:)` / `logout()` for identity linking.

**Key files**
`Services/EntitlementManager.swift`, `Services/RevenueCatService.swift`

---

### ✅ SVC-06 — NotificationService

**What was built**
`@MainActor final class NotificationService`. `requestPermission()`, `scheduleDailyReminder(at:)` (schedules 7 day-of-week-specific notifications with chakra-themed body text, identifiers `anicca.daily.reminder.weekday.1` through `.7`), `cancelDailyReminder()`, `clearBadge()`.

**Key files**
`Services/NotificationService.swift`

---

### ✅ SVC-07 — ExportService

**What was built**
`ExportService.shared.exportJSON(checkIns:)`: produces structured JSON with all check-ins and their emotion entries. `ExportService.shared.exportPDF(checkIns:profile:)` (Pro): generates a multi-page PDF with a branded cover, chakra balance summary table, and full check-in history with emotion dots.

**Key files**
`Services/ExportService.swift`

---

### ✅ SVC-08 — YggdrasilIntegrationProtocol (stub)

**What was built**
Protocol interface defining the Yggdrasil integration surface. No implementation. Ships as-is; implementation is reserved for a post-launch release.

**Key files**
`Services/YggdrasilIntegrationProtocol.swift`

---

### ✅ INFRA-01 — Supabase schema + RLS

**What was built**
SQL schema for `profiles`, `check_ins`, `emotion_entries`, `ai_insights`. RLS enabled on all tables with per-user policies (`auth.uid() = user_id`). Cascade deletes from `profiles` to all child tables. Auth provider configuration (email, Apple, Google). Instructions in `SupabaseSetup.md`.

**Key files**
`Anicca/Resources/SupabaseSetup.md`

---

### ✅ VIEW-01 — Auth views (SplashScreen + AuthView)

**What was built**
`SplashScreen`: animated logo, triggers `bootstrap()` on appear. `AuthView`: email/password sign-in and sign-up toggle, Apple Sign In button, Google Sign In button. Error display, loading state. Driven by `AuthViewModel`.

**Key files**
`Views/Auth/SplashScreen.swift`, `Views/Auth/AuthView.swift`, `ViewModels/AuthViewModel.swift`

---

### ✅ VIEW-02 — Onboarding flow (4 steps)

**What was built**
`OnboardingView` with 4 steps + animated transitions + progress dots + skip button:
1. **WelcomeStep** — app name, tagline, feature highlights
2. **CentersStep** — horizontally scrollable cards for all 7 energy centers, each expandable with description and fallback suggestions
3. **HowItWorksStep** — 3-step explanation of the log → insights loop
4. **RemindersStep** — time picker + enable/skip; calls `NotificationService.requestPermission()` and `scheduleDailyReminder(at:)` if granted

`OnboardingViewModel` drives state. On completion, sets `UserDefaults` key `anicca_onboarding_complete`.

**Key files**
`Views/Onboarding/OnboardingView.swift`, `ViewModels/OnboardingViewModel.swift`

---

### ✅ VIEW-03 — Home view

**What was built**
`HomeView`: greeting (time-of-day aware), plan badge, quick stats row (streak [Pro], week check-in count, most active center), Log CTA card (navigates to Log tab), Today's Suggestion card [Pro] (calls `AIService.generateCenterSuggestion()` with fallback to static suggestions), 3-item recent check-ins preview. Driven by a lightweight ViewModel embedded in the view.

**Key files**
`Views/Home/HomeView.swift`

---

### ✅ VIEW-04 — Log flow (coordinator + all sub-views)

**What was built**
`LogView` routes between three modes (`LogEntryMode`):
- `.freeText` → `FreeTextEntryView`: large TextEditor, auto-focus on appear (0.35s delay), "Map my feelings" CTA, "Browse emotions instead" link
- `.mappingResult` → `EmotionMappingResultView`: `MappedEmotionCard` per Gemini result, dot intensity selector (1–5), "Add more" opens browse, "Looks right" → intensity sheet, "Start over" returns to freeText
- `.browse(prefillSearch:)` → `EmotionBrowseView`: grouped by center with collapsible sections, search field

Intensity sheet (`IntensitySheetWrapper`): per-emotion sliders, optional note field, Save button (disabled until all emotions have had intensity confirmed). Free-limit paywall check on save. Success toast shows dominant center + streak.

All state managed by `LogViewModel`.

**Key files**
`Views/Log/LogView.swift`, `Views/Log/FreeTextEntryView.swift`, `Views/Log/EmotionMappingResultView.swift`, `Views/Log/EmotionBrowseView.swift`, `ViewModels/LogViewModel.swift`

---

### ✅ VIEW-05 — Insights view

**What was built**
`InsightsView` with 8 sections:
1. Header (total check-ins, email)
2. Time range filter (Week / 14 Days / Month)
3. Radar chart card (14-day / all-time toggle) — `RadarChartView` with 7-axis radar
4. Weekly summary card [Pro-blurred for free users] — dominant center + top 3 emotions this week
5. Mood timeline card — horizontal scroll of `TimelineDay` dots (colored circle per center, dash for no check-in, popover on tap)
6. Centers breakdown — all 7 centers with entry count + status badge (underactive / balanced / overactive)
7. AI insight card [Pro-blurred] — Gemini weekly narrative with suggested practices
8. Recent check-ins list (last 20, swipe-to-delete, tap for `CheckInDetailView`)

Driven by `InsightsViewModel`.

**Key files**
`Views/Insights/InsightsView.swift`, `Views/Insights/RadarChartView.swift`, `Views/Insights/CheckInDetailView.swift`, `ViewModels/InsightsViewModel.swift`

---

### ✅ VIEW-06 — Paywall view

**What was built**
`PaywallView`: feature comparison table (10 rows), monthly/annual toggle (annual shows savings badge), Pro purchase button + Bundle purchase button, restore purchases, privacy + terms links. Fetches offerings from RevenueCat. Driven by `PaywallViewModel`.

**Key files**
`Views/Paywall/PaywallView.swift`, `ViewModels/PaywallViewModel.swift`

---

### ✅ VIEW-07 — Settings view

**What was built**
`SettingsView`: account section (avatar initials, editable display name, email, plan badge), subscription section (opens PaywallView), reminders section [Pro-gated: toggle + graphical time picker], data export (JSON free / PDF Pro via share sheet), integrations (Yggdrasil web link), about section (app version + 5-tap developer override, privacy policy link, terms link, rate app), sign out (with confirmation), delete account (two-step alert). Driven by `SettingsViewModel`.

**Key files**
`Views/Settings/SettingsView.swift`, `ViewModels/SettingsViewModel.swift`

---

---

## 🔧 Pending Tickets

*These are actionable. Pick one up, build it, and open a PR.*

---

### 🔧 LOG-01 — Fix keyboard trap in FreeTextEntryView

**Problem**
`FreeTextEntryView` auto-focuses the `TextEditor` 0.35 seconds after appearing. On the Log tab, this means the keyboard slides up immediately and there is no way to dismiss it or navigate back without submitting. Users get stuck.

**Feature description**
A visible escape path when the keyboard is up: either a "Back" or "×" button in the navigation area that dismisses the keyboard and returns to the previous state, and/or a toolbar dismiss button above the keyboard.

**Implementation details**
- Add a toolbar item (`.toolbar`) with a leading "Back" or "Cancel" button that calls `viewModel.reset()` and pops/dismisses the view.
- Alternatively, add a keyboard toolbar (`ToolbarItem(placement: .keyboard)`) with a dismiss button.
- Ensure tapping outside the TextEditor (on the background) also dismisses the keyboard (`.onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), ...) }` on the background view).
- The auto-focus delay can stay — just ensure the exit path exists before the keyboard appears.

**Acceptance criteria**
- [ ] User can dismiss the keyboard and/or navigate back from `FreeTextEntryView` at any time
- [ ] A button is visible (not hidden behind the keyboard) that provides the exit
- [ ] Tapping the background outside the text area dismisses the keyboard
- [ ] After dismissal, the Log tab is in a clean state (no residual text if the user chose to cancel)

**Effort estimate**
S — toolbar + background tap gesture.

**Dependencies**
None.

**Notes**
This is the highest-priority UX bug. It will fail App Store review if left unfixed (WCAG navigation requirement and general usability standard).

---

### 🔧 LOG-02 — Redesign emotion library using Russell's circumplex model

**Problem**
The current emotion library (~98 emotions across 7 chakra centers) was built to map neatly to chakras, but the emotion words don't cover the full spectrum of human feeling and have redundancy. Russell's circumplex model of affect (1980) organizes emotions on two axes — **valence** (pleasant ↔ unpleasant) and **arousal** (activated ↔ deactivated) — which provides a principled, comprehensive, non-redundant framework for labeling any affective state.

**Feature description**
Replace `EmotionLibrary.swift` with a new library organized by quadrant on the circumplex, while keeping the chakra center assignment. Each emotion should map to one of four quadrants (high arousal / pleasant, high arousal / unpleasant, low arousal / pleasant, low arousal / unpleasant), covering the full emotional vocabulary without synonym duplication.

**Implementation details**
- Research: the standard circumplex maps ~28–40 distinct affect categories (not 98). Reference Russell (1980) and the PANAS-X, or use the Geneva Emotion Wheel as a secondary reference.
- Add a `circumplex: CircumplexQuadrant` property to `Emotion` (enum: `.highArousalPleasant`, `.highArousalUnpleasant`, `.lowArousalPleasant`, `.lowArousalUnpleasant`). The existing `valence` property stays but should align with the quadrant.
- Assign each new emotion to an `EnergyCenter` based on the chakra that most naturally governs that domain (Root = safety/survival, Sacral = desire/pleasure, etc.). The chakra assignment is the primary UI organization; the circumplex quadrant is metadata.
- Update `EmotionMappingService`'s system prompt to list the new emotions (Gemini needs the full list to map free text correctly).
- Aim for ~40–60 distinct emotions total. Eliminate synonyms that were previously listed as separate entries.
- Preserve the existing `Emotion` struct shape so downstream consumers (`EmotionLibrary.byCenter`, search, Gemini prompt) require minimal changes.

**Acceptance criteria**
- [ ] New library covers all 4 circumplex quadrants with no obvious gaps
- [ ] No two entries in the library are synonyms of each other
- [ ] Each emotion is assigned to exactly one EnergyCenter
- [ ] `EmotionMappingService` system prompt is updated to list the new emotion names
- [ ] The browse UI and search still work correctly with the new library
- [ ] Existing check-in data (stored by `emotion_name` string) degrades gracefully if a name is removed — old entries are not deleted, but the name may not match a library entry

**Effort estimate**
L — content research + data authoring + integration.

**Dependencies**
None. Can be done in isolation.

**Notes**
The goal is completeness and coverage, not strict psychological formalism. Prioritize: can a user always find a word that matches how they feel? If so, the library works. The circumplex is a guide, not a rigid constraint.

---

### 🔧 INSIGHTS-01 — Enrich the weekly summary card

**Problem**
The weekly summary currently shows one line (dominant center this week) plus a list of the top 3 emotions with counts. This is minimal — a Pro-gated card should justify the paywall with meaningful content.

**Feature description**
Add depth to the weekly summary card: valence trend direction, streak context, a center-activity comparison (this week vs. last week), and a qualitative summary sentence.

**Implementation details**
- `InsightsService.valenceTrend(in:)` already exists — surface it. Show whether the week trended positive, negative, or mixed, with an icon.
- Show current check-in streak (from `UserProfile.checkInStreak`) alongside the week count.
- Add a simple comparison: "You checked in more with [center] this week than last week" — using `insightsService.entriesInLast(days:from:)` for days 0–7 vs. 7–14.
- Add a short qualitative sentence combining dominant center + valence: e.g. "A week of [Heart] energy with a positive trend."
- Keep it visual and compact — this is a card, not a report. Aim for 4–6 lines of content max.
- The card stays Pro-blurred/paywalled for free users.

**Acceptance criteria**
- [ ] Valence trend is displayed (positive / negative / mixed) with an appropriate icon
- [ ] Current streak and week check-in count are visible
- [ ] A qualitative summary sentence is shown
- [ ] The card looks intentional and complete, not like a stub
- [ ] Free users still see the card blurred with an upgrade prompt

**Effort estimate**
M — content + layout additions; logic already exists in InsightsService.

**Dependencies**
SVC-03 (InsightsService — already built).

---

### 🔧 INSIGHTS-02 — Improve mood timeline visualization

**Problem**
The current timeline shows small colored dots in a horizontal scroll with a day label and date number. It works but is visually minimal — it doesn't communicate the density or intensity of check-ins, and there's no way to see the pattern at a glance across a month.

**Feature description**
Enhance the timeline to show check-in density (multiple check-ins on one day = larger or stacked dot), and extend the month view to a grid-style layout rather than a horizontal strip.

**Implementation details**
- For the week/14-day views: keep the horizontal strip, but scale dot size by number of check-ins on that day (1 = 28pt, 2+ = 36pt). Show a count badge when count > 1.
- For the month view (30-day range): switch to a 7-column calendar grid. Each cell shows the dominant center color for that day (if any check-ins). Empty days are muted. Tapping a cell opens a list of that day's check-ins.
- `InsightsViewModel.moodTimeline()` currently returns one `EnergyCenter?` per day. Extend it to return `(date: Date, center: EnergyCenter?, count: Int)` to support the density visualization.
- The timeline view component is private to `InsightsView` (`TimelineDay`). Refactor `TimelineDay` to accept the `count` parameter.

**Acceptance criteria**
- [ ] Days with multiple check-ins are visually distinguishable from single-check-in days
- [ ] Month range shows a calendar grid, not a horizontal strip
- [ ] Tapping a day cell shows the check-ins for that day
- [ ] Week and 14-day views retain the horizontal strip with density scaling
- [ ] Empty days remain visually distinct (not just absent)

**Effort estimate**
M — layout work + minor ViewModel extension.

**Dependencies**
SVC-03 (InsightsService — already built).

---

### 🔧 REMIND-01 — Resolve Pro-gating inconsistency and verify reminders end-to-end

**Problem**
There is a conflict between two parts of the app: the onboarding `RemindersStep` lets all users (including free) schedule daily reminders via `NotificationService.scheduleDailyReminder()`, but in Settings, the reminders section is Pro-gated. A free user who enables reminders during onboarding will have them scheduled, but Settings will not let them manage or disable them. This is also likely an App Store guideline issue (features should be consistently gated).

Additionally, the full reminders flow (permission request → schedule → notification delivery → deep link to Log tab on tap) has not been tested end-to-end on a physical device.

**Feature description**
Decide the correct gating: reminders should either be free for everyone or Pro-only everywhere. Implement consistently. Then test the full notification lifecycle on a physical device.

**Implementation details**
- Decision for Isa: make reminders free (removes a barrier to habit formation, which benefits engagement) or keep them Pro (incentivizes upgrade). This ticket assumes Pro-only, consistent with Settings. If free is chosen, remove the `!entitlements.isPro` gate from `remindersSection` in `SettingsView`.
- If Pro-only: add an entitlement check to `OnboardingViewModel.completeWithReminders()` — skip scheduling if the user is on the free tier. Update `RemindersStep` in `OnboardingView` to show a note: "Reminders require Pro — you can enable them in Settings after upgrading."
- Test on a physical device: verify the notification fires at the scheduled time, the chakra-themed body text rotates correctly by day of week, and tapping the notification opens the Log tab.
- Verify `NotificationService.clearBadge()` is called correctly on foreground.

**Acceptance criteria**
- [ ] Reminders are gated consistently (either Pro everywhere or free everywhere — not mixed)
- [ ] A free user going through onboarding does not silently schedule notifications they cannot manage
- [ ] Notification fires at the correct time on a physical device
- [ ] Tapping the notification opens the Log tab
- [ ] Badge is cleared when the app is foregrounded

**Effort estimate**
M — consistency fix + physical device testing.

**Dependencies**
SVC-06 (NotificationService — already built).

**Notes**
Ping Isa on Discord for the gating decision before implementing. Don't block on this — note the question in the PR.

---

### 🔧 AUTH-01 — Complete delete account flow (re-auth + Supabase auth.users cleanup)

**Problem**
The current `deleteAccount()` in `AuthService` deletes the `profiles` row (which cascades to check-ins, emotion entries, and insights) and then calls `client.auth.signOut()`. Two issues:

1. **Apple Sign In requirement:** Apple's App Store Review Guidelines require that apps using Sign in with Apple re-authenticate the user immediately before deleting their account. The current flow skips this step and will likely trigger a rejection.

2. **Supabase auth.users not deleted:** Only the `profiles` row is deleted. The Supabase `auth.users` entry remains, meaning the user's auth identity is not fully removed. If they sign up again with the same Apple ID or email, they may get into a broken state.

**Feature description**
Add re-authentication before deletion for Apple and Google Sign In users, and ensure the Supabase `auth.users` entry is removed.

**Implementation details**
- For Apple Sign In: before calling `deleteAccount()`, trigger `ASAuthorizationAppleIDProvider().createRequest()` to get a fresh credential. Pass the resulting `identityToken` to Supabase's `auth.refreshSession()` or use the token to re-verify. Apple's [account deletion guidance](https://developer.apple.com/news/releases/apns-changes-for-apps-supporting-sign-in-with-apple/) covers the required flow.
- For Google Sign In: call `GIDSignIn.sharedInstance.signIn(withPresenting:)` to get a fresh credential before deletion.
- For email/password: prompt for the current password in the delete confirmation dialog.
- After re-auth, call `client.auth.admin.deleteUser(id:)` — but this requires the service role key (which must never be on-device). Alternative: create a Supabase Edge Function `delete-account` that accepts a valid JWT, verifies it, and calls admin deletion server-side. The iOS client calls this Edge Function after re-auth.
- If the Edge Function approach is used, document the Edge Function SQL/TypeScript in `SupabaseSetup.md`.

**Acceptance criteria**
- [ ] Apple Sign In users are prompted to re-authenticate before the account is deleted
- [ ] Google Sign In users are prompted to re-authenticate before deletion
- [ ] Email/password users must confirm their password before deletion
- [ ] After deletion, the `auth.users` entry in Supabase is removed (not just `profiles`)
- [ ] The app returns to the auth screen after successful deletion
- [ ] On re-auth failure, deletion is cancelled and a clear error is shown

**Effort estimate**
L — three auth provider flows + Supabase Edge Function.

**Dependencies**
SVC-01 (AuthService).

**Notes**
This is a launch blocker — App Store Review will reject an app with Sign in with Apple that does not implement re-auth before deletion. The Edge Function is the cleanest approach for actual `auth.users` deletion since the service role key must not be on-device. Ask Isa for the Supabase service role key for the Edge Function.

---

### 🔧 EXPORT-01 — Verify and polish JSON export

**Problem**
`ExportService.exportJSON(checkIns:)` is implemented but has not been tested end-to-end across edge cases: empty check-in list, very large datasets, emoji in note text, and the share sheet behavior across iOS versions.

**Feature description**
Verify JSON export works correctly and produces well-formed, useful output. Fix any issues found.

**Implementation details**
- Test with: 0 check-ins, 1 check-in, 100+ check-ins, check-in with `nil` note, check-in with emoji/special characters in note.
- Verify the share sheet appears and allows saving to Files, sharing via Messages/Mail.
- Verify the JSON structure is human-readable (pretty-printed, ISO8601 dates).
- Ensure the exported filename includes a date: e.g. `anicca-export-2026-07-01.json`.
- Check that `ShareSheet` in `Views/Shared/ShareSheet.swift` works correctly on iOS 17+.

**Acceptance criteria**
- [ ] Export works with 0, 1, and 100+ check-ins
- [ ] JSON is valid, pretty-printed, and uses ISO8601 date strings
- [ ] Filename includes the export date
- [ ] Share sheet appears and allows saving to Files
- [ ] No crash or blank file on edge cases

**Effort estimate**
S — testing + minor polish.

**Dependencies**
SVC-07 (ExportService — already built).

---

### 🔧 EXPORT-02 — Verify and polish PDF export (Pro)

**Problem**
`ExportService.exportPDF(checkIns:profile:)` is implemented but the output quality and layout have not been verified against real data. PDF generation with PDFKit can produce clipped text, mis-aligned tables, or blank pages if content overflows.

**Feature description**
Verify the PDF export produces a complete, readable, on-brand document. Fix layout issues found with real data.

**Implementation details**
- Test with real check-in data: small dataset (5 entries), medium (30 entries), large (100+ entries).
- Verify: cover page renders correctly, chakra balance table has no clipped columns, check-in history pages don't clip long notes, multi-page pagination is correct.
- Brand check: the cover page should use `AniccaTheme.brandPrimary` (`#7C5CBF`) and the app name/logo. Avoid hard-coded colors in PDFKit drawing code.
- Verify the Pro gate: a free user pressing "Export PDF" should see the paywall, not an error.

**Acceptance criteria**
- [ ] PDF renders correctly for small, medium, and large datasets
- [ ] No text is clipped or cut off at page boundaries
- [ ] Cover page is on-brand
- [ ] Free user sees paywall when attempting PDF export
- [ ] Exported file opens in Preview/Books without errors

**Effort estimate**
M — testing + layout fixes.

**Dependencies**
SVC-07 (ExportService), SVC-05 (EntitlementManager for Pro gate).

---

### 🔧 LEGAL-01 — Host privacy policy page

**Problem**
`AppConfig.privacyPolicyURL` points to `https://anicca.lovable.app/privacy`, which is a placeholder (a Lovable-hosted prototype URL). The App Store requires a valid, accessible privacy policy URL in the app metadata and linked from within the app.

**Feature description**
A hosted privacy policy for Anicca is accessible at a stable URL and linked correctly from Settings.

**Implementation details**
- The policy must cover: data collected (email, check-in content, emotion entries, AI insight text), Supabase storage, Gemini API usage (note that free text entered by the user is sent to Google's API), RevenueCat subscription data, Apple/Google sign-in.
- Hosting options: a simple HTML page on a custom domain, a Notion page made public, or a service like Termly. Ask Isa which she prefers.
- Once hosted, update `AppConfig.privacyPolicyURL` to the final URL.
- The link in Settings must open in `SFSafariViewController` (already done via the existing URL sheet), not in the default browser.

**Acceptance criteria**
- [ ] Privacy policy is accessible at a public, stable URL
- [ ] `AppConfig.privacyPolicyURL` points to the correct URL
- [ ] Policy covers all data collected and third-party services used
- [ ] Settings opens the policy in-app (SFSafariViewController)

**Effort estimate**
M — content writing + hosting setup.

**Dependencies**
None.

**Notes**
This is a launch blocker. App Store submission requires a privacy policy URL. The policy content is Isa's responsibility; the ticket is for ensuring it's hosted and wired in correctly.

---

### 🔧 LEGAL-02 — Host terms of use page

**Problem**
`AppConfig.termsOfUseURL` points to `https://anicca.lovable.app/terms`, a placeholder. While terms of use are not strictly required by the App Store (unlike privacy policy), subscription apps benefit from them for subscription terms, refund policy, and disclaimer of medical advice.

**Feature description**
A hosted terms of use page is accessible at a stable URL and linked from Settings.

**Implementation details**
- Terms should cover: subscription terms (pricing, renewal, cancellation), refund policy (Apple handles refunds per their standard policy), disclaimer (Anicca is not a medical or mental health product), intellectual property.
- Update `AppConfig.termsOfUseURL` to the final URL.

**Acceptance criteria**
- [ ] Terms page is accessible at a public, stable URL
- [ ] `AppConfig.termsOfUseURL` points to the correct URL
- [ ] Terms include subscription terms and a non-medical disclaimer
- [ ] Settings links to it correctly

**Effort estimate**
M — content writing + hosting setup.

**Dependencies**
None.

---

### 🔧 INFRA-02 — Add PrivacyInfo.xcprivacy (required reason APIs)

**Problem**
Apple requires a Privacy Manifest (`PrivacyInfo.xcprivacy`) for all apps submitted to the App Store starting Spring 2024. The manifest declares which "required reason APIs" the app uses (e.g., `UserDefaults`, `NSFileManager`), why, and what data the app collects. Without it, App Store submission is rejected.

**Feature description**
A `PrivacyInfo.xcprivacy` file is present in the Anicca target and declares all required reason API usages.

**Implementation details**
- Create `Anicca/Resources/PrivacyInfo.xcprivacy` (XML/plist format).
- Audit the codebase for required reason API usages:
  - `UserDefaults` — used for: `developer_override_pro`, `anicca_onboarding_complete`, `anicca_last_review_version`. Reason category: `CA92.1` (app functionality).
  - `NSFileManager` / `FileManager` — used in `ExportService` to write temporary export files. Reason: `C617.1`.
  - Check for any other required reason APIs in dependencies (Supabase SDK, RevenueCat SDK, GoogleSignIn).
- Declare the `NSPrivacyCollectedDataTypes` array for data Anicca collects: email address (linked to identity), user-generated content (check-in notes, emotion selections).
- Add `PrivacyInfo.xcprivacy` to the Anicca target in `project.yml` under `sources`.

**Acceptance criteria**
- [ ] `PrivacyInfo.xcprivacy` exists in the Anicca target and is included in the build
- [ ] All `UserDefaults` and `FileManager` usages are declared with correct reason codes
- [ ] `NSPrivacyCollectedDataTypes` accurately reflects collected data
- [ ] Build succeeds after adding the file

**Effort estimate**
S — file creation + API audit.

**Dependencies**
None.

**Notes**
Reference: [Apple's required reason API documentation](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api). Third-party SDKs (Supabase, RevenueCat, GoogleSignIn) provide their own privacy manifests — you only need to declare Anicca's first-party usage.

---

### 🔧 RELEASE-01 — App Store metadata and screenshots

**Problem**
Before submitting to App Store Connect, Anicca needs a complete metadata set: app name, subtitle, description, keywords, promotional text, screenshots for each required device size, and an app preview (optional but recommended).

**Feature description**
All App Store Connect metadata fields are filled in and all required screenshots are captured.

**Implementation details**
- **Required device sizes for screenshots:** iPhone 6.9" (iPhone 16 Pro Max), iPhone 6.5" (iPhone 11 Pro Max), and optionally iPad Pro 12.9" if iPad support is declared. The 6.9" and 6.5" screenshots can often be the same — check App Store Connect's current requirements.
- **5 screenshots per size:** suggest: (1) Log screen / free-text entry, (2) Gemini mapping result, (3) Insights — radar chart, (4) Home with Today's Suggestion, (5) Paywall / Pro features.
- **App description:** ~170 words, covers the core value proposition, 7 energy centers, AI mapping, and privacy-first angle.
- **Keywords:** max 100 characters, comma-separated (e.g., `mood tracking,chakra,energy,wellness,emotions,self-awareness,journaling,ai,mindfulness`).
- **Subtitle:** 30 characters max (e.g., `Track energy. Know yourself.`).
- Screenshots can be captured on a simulator via `Cmd+S` in Xcode or using [Fastlane Snapshot](https://fastlane.tools/snapshot/) if automation is desired.

**Acceptance criteria**
- [ ] All required screenshot sizes are captured and uploaded to App Store Connect
- [ ] App name, subtitle, description, and keywords are set
- [ ] Age rating questionnaire is complete (select "No" for all content descriptors unless applicable)
- [ ] Privacy policy URL is set (from LEGAL-01)
- [ ] Category is set (Health & Fitness is the primary; Lifestyle as secondary)

**Effort estimate**
M — copywriting + screenshot capture.

**Dependencies**
LEGAL-01 (privacy policy URL).

**Notes**
Only Isa submits to App Store Connect. This ticket is for preparing the assets and copy — hand off the final files to Isa via the PR or via a shared folder.

---

### 🔧 RELEASE-02 — First TestFlight build (internal testing)

**Problem**
The app has not been submitted to TestFlight. An internal build is needed to verify the full production flow: Supabase auth, Gemini API calls, RevenueCat entitlement check, and notification delivery on a real device.

**Feature description**
A signed release build is submitted to TestFlight and passes internal testing.

**Implementation details**
- Archive the app in Xcode (Product → Archive) using the Release scheme.
- Submit to App Store Connect via Xcode Organizer.
- Add Isa as an internal tester.
- Test the following flows end-to-end on a physical device:
  - Sign up with email, Apple, and Google
  - Complete onboarding
  - Log a check-in via free text (Gemini mapping)
  - Log a check-in via browse
  - View Insights (radar, timeline, centers breakdown)
  - Trigger the free-tier limit (30 check-ins) and verify paywall
  - Restore a Pro purchase
  - Enable/disable reminders and verify notification fires
  - Export JSON
  - Export PDF (Pro)
  - Delete account

**Acceptance criteria**
- [ ] Build passes App Store Connect processing without errors
- [ ] All flows listed above complete without crash or data loss
- [ ] Supabase data is correctly persisted and synced
- [ ] RevenueCat entitlements reflect correctly in the app
- [ ] No console errors or Supabase auth failures in normal flows

**Effort estimate**
M — archive + upload + testing.

**Dependencies**
All pending tickets should ideally be resolved before this, especially AUTH-01 (delete account) and INFRA-02 (privacy manifest).

**Notes**
Only Isa submits to TestFlight. This ticket is owned by Isa.

---

*Anicca · Screen Sage Studios · App Store launch target: July 2026*
