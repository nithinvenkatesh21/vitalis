# VITALIS — Master ECC Build Prompt
### The Single Source of Truth for iOS Development (v1.0)

> **Purpose of this document:** This is the persistent reference ECC (or any agentic coding tool) should re-read at the start of every session, before every new module, and whenever a decision feels ambiguous. Nothing should be built that contradicts this document. If a requirement here is unclear, ECC should design/document a resolution *before* writing code, and append that decision to Section 20 (Architectural Decision Log).

---

## 1. Complete Product Vision

Vitalis is the unified health operating system for iOS — the single app that replaces the 10–15 disconnected apps (MyFitnessPal, Strava, WHOOP, Oura, Calm, Flo, pill reminders, etc.) a serious health-conscious user currently juggles. It aggregates every category of personal health data like Apple Health, but unlike Apple Health it *reasons* about that data continuously and *acts* on it — adjusting today's workout, tomorrow's meals, and this week's schedule automatically.

**North star:** a person should be able to delete every other health app on their phone within 90 days of adopting Vitalis, because Vitalis does everything those apps do, better, and connects it all together.

**Non-negotiable qualities:**
- Feels like a first-party Apple app — respects Human Interface Guidelines, platform conventions, and Apple's design language, while introducing an original visual identity (not a HealthKit clone).
- Logging is fast (sub-15-second meal/workout logging) — friction is the #1 killer of health apps.
- Every metric connects to at least one other module — no orphaned data.
- Privacy-first by architecture, not just by policy.
- Built to scale from MVP to a platform (marketplace, clinician-share, B2B) without a rewrite.

---

## 2. Design Philosophy

1. **Calm technology, not a dashboard of anxiety.** Data is surfaced as clear, prioritized signal — one Readiness Score and one or two "focus for today" cards — not twenty charts competing for attention.
2. **Automate first, log second.** Prefer camera/wearable/passive capture over manual typing everywhere possible.
3. **Explainability over black boxes.** Every AI-driven suggestion shows *why* in one tappable line ("Workout lightened — HRV down 18% vs your baseline").
4. **Native materials, original character.** Use SF Symbols, system typography (SF Pro / New York where editorial), standard navigation patterns, Dynamic Type, and platform gestures — but establish Vitalis's own accent palette, iconography for feature categories, and a distinct chart/data-visualization language so it never feels like a HealthKit reskin.
5. **Depth is opt-in, simplicity is default.** A new user sees a clean, guided home screen; a power user can drill into every underlying data point.
6. **One-handed, glanceable, interruption-tolerant.** Every primary action (log a meal, log a set, check readiness) must be completable one-handed in under 3 taps.

---

## 3. Information Architecture

```
Vitalis
├── Today (Home)                — Readiness, AI Coach entry, adjusted plan, quick-log actions
├── Nutrition
│   ├── Log (camera/barcode/voice/manual)
│   ├── Diary (daily/weekly)
│   ├── Recipes & Meal Plan
│   ├── Micronutrients
│   └── Glucose (if CGM connected)
├── Train
│   ├── Today's Session
│   ├── History & Analytics
│   ├── Exercise Library
│   ├── Personal Records
│   └── Programs
├── Recover
│   ├── Sleep
│   ├── Readiness / HRV
│   ├── Stress
│   └── Modalities (sauna, cold, massage, stretch)
├── Mind
│   ├── Mood & Journal
│   ├── Meditate / Breathe
│   └── Burnout Trend
├── Medical
│   ├── Medications & Supplements
│   ├── Labs
│   ├── Symptoms
│   ├── Records & Documents
│   └── Appointments
├── Life Stage (adaptive: Cycle / Pregnancy / Menopause)
├── Body
│   ├── Weight & Composition
│   ├── Progress Photos
│   └── Measurements
├── Family
├── Community
└── Timeline (universal longitudinal log + Digital Medical Passport + Settings)
```

**Navigation pattern:** Tab bar with 5 primary destinations (Today, Nutrition, Train, Recover, More), where "More" houses Mind/Medical/Life Stage/Body/Family/Community/Timeline in a searchable grid — this keeps the tab bar within Apple's recommended 5-item limit while preserving full IA depth. Deep-linkable via Spotlight, widgets, and Siri.

---

## 4. Navigation Hierarchy & Screen-by-Screen Breakdown (Representative Set)

**Today (Home)**
- Hero card: Readiness Score (ring + one-line explanation) → tap for full breakdown.
- "Vital" AI Coach entry (floating action button, persistent across app).
- Adjusted Plan card: today's workout (auto-modified), meal targets, calendar conflicts.
- Quick-log row: Meal / Workout / Water / Mood / Weight (icon buttons).
- Rings: Activity, Nutrition, Sleep debt.

**Nutrition → Log**
- Full-screen camera default; barcode toggle; voice-log toggle; manual search fallback.
- Post-capture: editable food-item list with confidence indicators, portion sliders, "looks right?" confirm.
- Post-confirm: macro ring update animation, glycemic-response prediction chip (if CGM connected).

**Train → Today's Session**
- Card stack of exercises (auto-generated), each expandable to log sets.
- Rest-timer overlay (Live Activity + Dynamic Island support).
- Post-workout: RPE slider → session summary → training-load update.

**Recover → Readiness**
- Full-bleed trend chart (7/30/90-day), component breakdown (HRV, sleep, load, illness signal), tap any component for its own detail screen.

**Medical → Records**
- Timeline-style document list, OCR-parsed lab trend charts, "Prepare for Appointment" button generating a shareable one-pager.

**Timeline**
- Infinite vertical scroll, filterable by category, each entry deep-links to its source screen — this is the connective-tissue screen that makes cross-feature correlation visible to the user.

Each screen above should get its own SwiftUI View + ViewModel + Coordinator pairing per the architecture in Section 12.

---

## 5–6. Feature Categories & Sub-Features

*(Full behavioral spec — why/how/connects/data/insight/AI — for each category should be pulled from and remain consistent with the companion document "Vitalis Master Product Specification v1.0." ECC should treat that document as the authoritative feature-behavior reference and this document as the authoritative build/architecture reference. Core categories, unchanged: Nutrition Intelligence, Training & Movement, Recovery & Readiness Engine, Mental Wellbeing, Medical & Medication Management, Reproductive & Life-Stage Health, Body Composition & Progress, Environmental & Contextual Health, Habit & Behavior Intelligence, Family & Household Health, Social & Community — plus the net-new categories: Longevity Score/Biological Age, AI Health Coach ("Vital"), Health Risk Prediction, Nutrient Deficiency Prediction, Injury Prevention Engine, Energy/Burnout Prediction, Smart Recovery-Aware Scheduling, Continuous Health Timeline, Digital Medical Passport, Household Health Constellation, Travel Health Mode, Genetic/Multi-Omic Integration, Health Gamification, Predictive Grocery/Supply.)*

---

## 7. User Journeys

- **Onboarding → First Value in <5 minutes:** connect HealthKit → grant only needed permissions (progressive, not all-at-once) → 3-question goal survey → first Readiness Score computed from any available Health data → first AI-generated meal + workout suggestion shown immediately, even before manual logging begins.
- **Daily loop:** morning readiness push → adjusted plan → passive logging throughout day → evening reflection prompt (mood + tomorrow preview).
- **Clinical loop:** symptom logged → correlation surfaced → optional appointment booked → AI-drafted visit summary → post-visit note logged back into Timeline.
- **Life-stage transition:** cycle tracking auto-detects pregnancy signals (opt-in) → offers to switch modes → Life Stage section reconfigures without losing history.

---

## 8. UI/UX Recommendations (Apple HIG Alignment)

- Use **NavigationStack** (not deprecated NavigationView), **SF Symbols 6** for all iconography with custom category glyphs layered on top via symbol composition, **Dynamic Type** support to accessibility XXL sizes tested on every screen, **SwiftUI's native charts** (Swift Charts framework) for all data visualization rather than third-party chart libraries, **Haptics** (CoreHaptics/UIFeedbackGenerator) on every log-confirmation action, **Dark Mode** as a fully first-class, separately-designed palette (not just inverted colors), **Sheet-based modals** for logging flows (`.presentationDetents`), **Context menus** and **swipe actions** for power-user speed on list rows, respect **Reduce Motion** and **Increase Contrast** accessibility settings everywhere animations/color are used for meaning.

---

## 9. Design System

- **Color:** A core semantic palette — `vitalPrimary` (brand accent, distinct from Apple's red Health branding), `readinessGreen/Amber/Red`, `nutritionBlue`, `recoveryPurple`, `mindTeal` — each with light/dark variants defined as Color Assets, never hardcoded hex in views.
- **Typography:** SF Pro for UI, SF Pro Rounded for scores/big numbers (Readiness Score, calorie totals), New York (serif) reserved for journal/reflection text to create emotional distinction from data screens.
- **Spacing:** 4pt base grid (4/8/12/16/24/32/48).
- **Components:** RingProgressView, ScoreCard, TrendChart (Swift Charts wrapper), QuickLogButton, TimelineRow, InsightChip (the "why" explainer), PlanCard, EmptyStateView — all built as a shared `DesignSystem` Swift package so every module consumes the same primitives.
- **Animation:** Spring-based transitions (`response: 0.4, dampingFraction: 0.8`) as the house style, matched-geometry transitions between Today card and detail screens.

---

## 10–11. SwiftUI Component Hierarchy & App Architecture

**Architecture: MVVM-C (MVVM + Coordinators) inside a Clean-Architecture-inspired layering**, packaged as local Swift Packages for compile-time modularity and enforced boundaries:

```
Vitalis (App target)
├── VitalisCore            (SPM) — shared models, protocols, utilities, DesignSystem
├── VitalisNetworking       (SPM) — API client, auth token handling, request builders
├── VitalisPersistence      (SPM) — SwiftData/CoreData stack, repositories, CloudKit sync
├── VitalisHealthKit        (SPM) — HealthKit read/write wrappers, background delivery
├── VitalisAI               (SPM) — AI Coach client, on-device CoreML models (vision, form-check)
├── Features/
│   ├── Today               (SPM) — View + ViewModel + Coordinator + local UseCases
│   ├── Nutrition           (SPM)
│   ├── Training            (SPM)
│   ├── Recovery            (SPM)
│   ├── Mind                (SPM)
│   ├── Medical             (SPM)
│   ├── LifeStage           (SPM)
│   ├── Body                (SPM)
│   ├── Family              (SPM)
│   ├── Community           (SPM)
│   └── Timeline            (SPM)
└── VitalisWatch / VitalisWidgets / VitalisIntents  (separate targets, depend only on VitalisCore/Persistence)
```

**Per-feature module pattern:**
```
Feature/
├── Presentation/  (SwiftUI Views, ViewModels — @Observable, not legacy ObservableObject)
├── Domain/        (UseCases, domain models, protocols — no framework imports)
├── Data/          (Repository implementations, DTOs, mappers)
└── Coordinator.swift  (navigation logic, isolated from Views)
```
Each feature module depends only on `VitalisCore` + `VitalisPersistence` protocols — never directly on another feature module — cross-feature communication happens through a shared `TimelineEventBus` (Combine/AsyncStream-based) in VitalisCore, which is the architectural embodiment of "One Timeline, One Model" from the product spec.

**State management:** Swift's `@Observable` macro (Observation framework) for ViewModels, `@Environment` for dependency injection of repositories/services, no third-party state-management library needed.

---

## 12. Folder Structure (Xcode Project)

```
Vitalis.xcworkspace
├── Vitalis/                      (App target: App.swift, scenes, root coordinator)
├── Packages/
│   ├── VitalisCore/
│   ├── VitalisNetworking/
│   ├── VitalisPersistence/
│   ├── VitalisHealthKit/
│   ├── VitalisAI/
│   ├── DesignSystem/
│   └── Features/{Today,Nutrition,Training,...}/
├── VitalisWatch/                 (watchOS app target)
├── VitalisWidgets/                (WidgetKit extension: Today ring, Readiness, Streaks)
├── VitalisIntents/                (App Intents / Shortcuts extension)
├── VitalisTests/                  (per-package unit tests mirror structure)
└── VitalisUITests/
```

---

## 13–14. Database Schema & Data Models

**Local persistence:** SwiftData as the primary local store (iOS 17+/18+ target), using sandboxed SQLite files on the device. Core Data escape hatch only if a specific SwiftData limitation is hit (document any such case in Section 20). There is no external backend database (such as PostgreSQL/Neon/Supabase).

**Data Schema & Entities:**
The local SwiftData entities mirror the following schema layout:

```swift
// SwiftData model properties mirror this structured layout:
users(id, demographics, goals_json, family_group_id, created_at)
biometric_samples(id, user_id, type, value, unit, timestamp, source_device)
sleep_sessions(id, user_id, start, end, stages_json, efficiency, latency)
meals(id, user_id, timestamp, method, macros_json, micros_json)
food_items(id, meal_id, name, brand, macros_json, confidence_score)
workout_sessions(id, user_id, timestamp, type, rpe, training_load)
set_logs(id, workout_session_id, exercise_id, load, reps, tempo, rest_seconds)
readiness_scores(id, user_id, date, composite_score, components_json, explanation_json)
mood_entries(id, user_id, timestamp, valence, tags_json, free_text)
medications(id, user_id, drug_name, dose, schedule_json)
medication_adherence(id, medication_id, timestamp, taken_bool)
lab_results(id, user_id, panel, marker, value, unit, reference_range, date, source_doc_url)
symptom_logs(id, user_id, timestamp, symptom, severity, body_location, correlations_json)
cycle_data(id, user_id, date, phase, flow, symptoms_json)
body_composition(id, user_id, date, weight, body_fat_pct, measurements_json, photo_ref)
habits(id, user_id, name, cadence, streak, adherence_model_json)
timeline_events(id, user_id, timestamp, type, payload_json, linked_entity_ids)  -- universal spine
family_groups(id, shared_permissions_json)
```

The `timeline_events` table/entity is denormalized/append-only and powers the Timeline screen and cross-feature correlation queries — every write to a domain table triggers a corresponding `timeline_events` insert locally.

---

## 15. HealthKit Integration

- Request the minimum necessary HealthKit read/write types per feature at the point of need (progressive permissioning), not one giant upfront prompt.
- Background delivery (`HKObserverQuery` + `enableBackgroundDelivery`) for HR, HRV, sleep, steps so Readiness Score updates without the app open.
- Write back Vitalis-derived data (custom workouts, water intake, mindful minutes) to HealthKit so Apple's ecosystem (and other apps) benefit too — Vitalis should be a good citizen of HealthKit, not just a consumer.
- Use `HKWorkoutBuilder`/`HKLiveWorkoutBuilder` for real-time workout sessions synced with Apple Watch.
- Clinical Health Records API (FHIR-based) integration for hospital-sourced lab/medication data where the user grants access.

## 16. Apple Watch Integration

- Standalone watchOS app (not just a mirrored extension) capable of independent workout tracking, complications for Readiness Score, and a dedicated rest-timer/set-logging UI for strength sessions.
- watchOS complications: Readiness ring, next-medication reminder, hydration progress.
- Always-On display support for in-workout metrics.

## 17. Widget Support

- Lock Screen widgets: Readiness Score, hydration ring, next medication.
- Home Screen widgets (small/medium/large): Today's Plan, Nutrition rings, Streak tracker.
- Interactive widgets (iOS 17+ `AppIntent`-backed): log water, mark medication taken, directly from widget without opening app.

## 18. Live Activities

- Active workout session (rest timer, current set, elapsed time) on Lock Screen + Dynamic Island.
- Fasting-window countdown.
- Active meditation/breathwork session timer.

## 19. Siri / App Intents & Shortcuts Integration

- App Intents for: "Log water", "Log weight", "Start workout", "What's my readiness today?", "Log [food] for [meal]".
- Siri phrase support via natural invocation ("Hey Siri, log breakfast in Vitalis").
- Shortcuts app support for automations (e.g., "When I arrive at the gym, start a Vitalis workout").
- Spotlight indexing of exercises, recipes, and Timeline entries for system-wide search.

---

## 20. AI Architecture

- **On-device (CoreML/Vision):** meal-photo segmentation and portion estimation, workout form-check joint-angle analysis, body-composition photo estimation — chosen on-device specifically for latency and for keeping sensitive imagery off servers by default.
- **On-device / Client-side (LLM + retrieval):** the "Vital" AI Coach — a client-side context-assembly system that compiles the relevant slice of the user's local Timeline (recent biometrics, logs, goals) into a retrieval-augmented prompt before each coach interaction, backed by local or privacy-preserving API models with function-calling/tool-use to take real actions (reschedule a workout, adjust a meal plan, draft an appointment summary).
- **Predictive models (calculated locally on-device):** personalized Readiness Score weighting, glycemic-response prediction, injury-risk scoring, burnout/energy forecasting, deficiency prediction — implemented as lightweight, local Bayesian/statistical models.
- **Architectural Decision Log:** *(ECC appends entries here as real decisions are made during build — e.g., "Chose SwiftData over CoreData because X; revisit if Y.")*

## 21. Local Persistence Architecture

- Primary persistence is completely local using **SwiftData** (SQLite database in the app sandbox).
- Background calculations (e.g., HRV, sleep processing, and Readiness Score recomputation) are processed on-device via standard iOS background tasks.
- All data imports (such as HealthKit histories, CSV lab records) are parsed and committed directly to the local database container.
- No backend servers, external GraphQL APIs, or hosted SQL databases are used.

## 22. Authentication

- Sign in with Apple as the primary/default method for local user profile creation.
- Local session credentials stored securely in `UserDefaults` and/or the Keychain.
- Biometric app-lock (Face ID/Touch ID) as a required gate for the Medical section specifically, configurable to gate the whole app.
- No external OAuth or server-side authentication databases.

## 23. Privacy & Security

- Per-category granular sharing permissions (Section 11 of the product spec) enforced in local repositories.
- On-device processing for sensitive computer vision by default (Section 20).
- Explicit, separate opt-in toggles for: research data sharing, insurance program integration, any third-party data use — none bundled into a general ToS acceptance.
- Full data export (structured JSON) and full account/data deletion available in-app, self-service, instantly executed locally.
- Architected to HIPAA-adjacent standards given medical-record storage and local data encryption, even where not strictly legally mandated for a consumer app.

## 24. Accessibility

- VoiceOver labels and custom rotor support on every screen, tested with VoiceOver on before merging any feature (add to Definition of Done).
- Full Dynamic Type support up to accessibility sizes; layouts verified not to clip or truncate at largest sizes.
- Voice-first logging path for users with motor impairments.
- Reduce Motion / Increase Contrast respected in every custom animation and chart.
- Cognitive-accessibility "Simple Mode" — reduced choices, larger targets, for elderly/cognitively-impaired users or caregiver-proxy logging.

## 25. Local-Only Offline Design

- The application is 100% server-free and offline-first. All writes and reads access the local SwiftData container directly. No sync outbox or remote database merging is needed, eliminating conflict resolution issues.
- Readiness Score is computed locally on-device using cached HealthKit data.

## 26. Cloud Synchronization (Removed)

- Cloud backup and synchronization are currently out of scope. The database operates entirely within the device sandbox.

## 27. Premium Features & Monetization Strategy

*(Mirrors Section 9 of the product spec — Free / Vitalis+ / Vitalis Care tiers, marketplace take-rate, B2B employer/insurer partnerships.)* Implementation note for ECC: gate premium features via a single `EntitlementService` protocol consumed across all feature modules, never via scattered feature-flag checks — this keeps monetization logic centralized and testable as pricing/tiers evolve.

## 28. Future Roadmap

*(Mirrors Section 12 of the product spec — Year 1–2 core unification through Year 7–10 ambient sensing and clinician-facing companion product.)*

---

## 29. Step-by-Step Implementation Phases for ECC

**Phase 0 — Foundation (before any feature UI):**
1. Set up workspace, SPM package skeleton per Section 12.
2. Build `VitalisCore` domain models + `TimelineEventBus`.
3. Build `VitalisPersistence` (SwiftData schema + CloudKit container).
4. Build `VitalisHealthKit` wrapper with permission-request flow.
5. Build `DesignSystem` package (Section 9 primitives) with a SwiftUI Previews gallery.

**Phase 1 — Core Loop MVP:**
6. Today (Home) module — static layout first, wired to real HealthKit data.
7. Nutrition Log (manual + barcode first; camera AI recognition second).
8. Training Log (manual logging first; auto-generated programming second).
9. Basic Readiness Score (HRV + sleep + training load only — expand components later).
10. Onboarding flow.

**Phase 2 — Recovery & Mind:**
11. Full Recovery module (sleep architecture, stress).
12. Mind module (mood, meditation library).
13. Habit tracker.

**Phase 3 — Medical Depth:**
14. Medication/supplement tracking + interaction checks.
15. Lab result OCR import + trend charts.
16. Symptom tracker with basic correlation.
17. Digital Medical Passport.

**Phase 4 — AI Layer:**
18. Meal-photo recognition (CoreML).
19. "Vital" AI Coach (retrieval + function-calling, read-only actions first, write-actions second).
20. Predictive models (deficiency, injury-risk, burnout) once sufficient data volume exists.

**Phase 5 — Platform Expansion:**
21. Watch app, Widgets, Live Activities, App Intents/Shortcuts.
22. Family/Caregiver mode.
23. Community/Challenges.
24. Genetic integration, Environmental health layer, Travel mode.

**At every phase boundary:** ECC should pause, review this document against what was built, update the Architectural Decision Log (Section 20), and confirm the next phase's scope before writing its first line of code.

---

## 30. Companion Document

This build prompt should always be read alongside **"Vitalis Master Product Specification v1.0"**, which is the authoritative source for feature-level behavior (the why/how/connects/data/insight/AI breakdown per category). This document is the authoritative source for how that vision gets built on iOS. Where the two ever appear to conflict, feature *behavior* wins from the product spec, and technical *implementation* wins from this document — ECC should flag the conflict rather than silently resolving it.
