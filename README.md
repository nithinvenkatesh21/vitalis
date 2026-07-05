# Vitalis iOS App — Development Guide

Welcome to **Vitalis**! This directory contains the complete source code, packages, and database configurations for the iOS application.

---

## Milestone 1 Goals
- [x] Configure a real Supabase/Postgres backend.
- [x] Set up compile-time gated debug Mock Authentication.
- [x] Implement local-first logging of `MoodEntry` records using **SwiftData**.
- [x] Integrate **Supabase client** for remote uploads.
- [x] Sync `MoodEntry` and `TimelineEvent` records as an **atomic, single Postgres transaction** (using Postgres RPC function).
- [x] Support automatic outbox queue sync on network connection restoration.

## Milestone 2 Goals
- [x] Extend schema for Nutrition (`meals`, `food_items`) and Readiness (`readiness_scores`).
- [x] Implement atomic sync Postgres RPC function `log_meal_with_items`.
- [x] Create local `VitalisHealthKit` package to fetch sleep duration and HRV.
- [x] Implement client-side Readiness Score algorithm with progressive reweighting on missing sensors.
- [x] Build Today dashboard showing Readiness ring and Nutrition targets.
- [x] Build Nutrition Logging UI with manual inputs and simulated barcode scanning.

---

## 1. Supabase Project Setup

1. **Create a Project**:
   - Go to [Supabase Console](https://database.new) and create a new project.
2. **Execute Database Migrations**:
   - Navigate to the **SQL Editor** tab in your Supabase dashboard.
   - Run the contents of [backend/schema.sql](file:///Users/nithinvenkatesh/Documents/healthio/vitalis-ios/backend/schema.sql) first.
   - Then, run the contents of [backend/schema_milestone_2.sql](file:///Users/nithinvenkatesh/Documents/healthio/vitalis-ios/backend/schema_milestone_2.sql) to add nutrition tables and RPC functions.
   - Verify that all tables are created and the RPC functions `log_mood_with_timeline`, `log_meal_with_items`, and `log_readiness_with_timeline` are present.
3. **Configure Authentication**:
   - Go to **Authentication** -> **Providers** -> **Apple** to configure production Sign in with Apple, or use the mock sign-in buttons on simulator testing.

---

## 2. Setting Up Xcode Project

Since we are developing modularly using local packages, you will create a standard SwiftUI Xcode project and link the packages.

1. **Create the Project in Xcode**:
   - Create an iOS App named `Vitalis` using SwiftUI and SwiftData inside the `vitalis-ios` folder.
2. **Delete Template Boilerplate**:
   - Delete the default `ContentView.swift` and `VitalisApp.swift` created by Xcode.
3. **Add Existing Files**:
   - Right-click the `Vitalis` folder inside Xcode, select **Add Files to "Vitalis"...**
   - Select the following files from `/Users/nithinvenkatesh/Documents/healthio/vitalis-ios/Vitalis/`:
     - `VitalisApp.swift`
     - `ContentView.swift`
     - `DashboardView.swift`
     - `DashboardViewModel.swift`
     - `OnboardingView.swift`
     - `TodayView.swift`
     - `TodayViewModel.swift`
     - `NutritionLogView.swift`
     - `NutritionLogViewModel.swift`
4. **Link Local Swift Packages**:
   - Right-click the root project in Xcode, select **Add Package Dependency...** -> **Add Local...**
   - Navigate to `/Users/nithinvenkatesh/Documents/healthio/Packages/` and select:
     - `VitalisCore`
     - `VitalisNetworking`
     - `VitalisPersistence`
     - `VitalisHealthKit`
   - Link these four libraries to your **Vitalis** main target under **Frameworks, Libraries, and Embedded Content** in General Settings.
5. **Configure Entitlements**:
   - Add **Keychain Sharing** entitlement for Supabase Auth.
   - Add **HealthKit** entitlement to request read access for Sleep Analysis and Heart Rate Variability.

---

## 3. Credentials Configuration

Open [Packages/VitalisNetworking/Sources/VitalisNetworking/SupabaseConfig.swift](file:///Users/nithinvenkatesh/Documents/healthio/Packages/VitalisNetworking/Sources/VitalisNetworking/SupabaseConfig.swift) and ensure your credentials are set:

```swift
public enum SupabaseConfig {
    public static var supabaseURL = URL(string: "https://<your-project-id>.supabase.co")!
    public static var supabaseAnonKey = "<your-anon-public-key>"
}
```

---

## 4. Verification Checklists

### Milestone 1 Verification
* **Test 1 (Atomic Linkage)**: Log a Mood entry, verify a row in `mood_entries` and a row in `timeline_events` are inserted with matching linked IDs in a single transaction.
* **Test 2 (RLS Data Isolation)**: Log in as User A and User B. Verify User B cannot view User A's logs, showing that Row-Level Security isolates data.
* **Test 3 (Offline Sync Outbox)**: Disconnect Wi-Fi, log a mood, verify it queues locally as "Pending", reconnect, and verify it updates to "Synced" and uploads to Supabase.

### Milestone 2 Verification

#### Test 1: HealthKit Progressive Reweighting
1. In the simulator, open settings and deny HealthKit permissions.
2. Open Vitalis: verify the Readiness Card displays: *"No HealthKit biometrics available. Enable HealthKit permissions in iOS Settings."* and has a neutral score of 50.
3. Grant **Sleep only**: Verify the Readiness score is calculated using Sleep duration only, and the explanation shows: *"Sleep was X hours. HRV data missing (reweighted 100% on Sleep)."*
4. Grant **Sleep and HRV**: Verify both metrics are fetched and the composite score combines them (50% Sleep, 50% HRV).

#### Test 2: Barcode Scanning and Contributed Items
1. Tap **Log Meal** -> enter barcode `0123456789`. Confirm it scans Quaker Oats (150 kcal, 6g protein, 27g carbs, 3g fat).
2. Enter barcode `5555555555`. Confirm it displays: *"Barcode not found. Enter macro details manually below."*
3. Enter `"Greek Yogurt"`, `100` cals, `15`g protein, `6`g carbs, `0`g fat. Tap **Add to Plate** and **Log Meal**. Verify the custom food item is logged successfully.

#### Test 3: Atomic Nutrition Sync
1. Log a meal containing 2 food items.
2. Inspect your Supabase database:
   - Verify **one** row was added to `meals`.
   - Verify **two** rows were added to `food_items` containing the parent `meal_id`.
   - Verify **one** row was added to `timeline_events` containing the `meal_id` in `linked_entity_ids`.
3. Put the device offline, log a meal, verify it caches locally as "Pending", restore connection, and verify the meal, items, and event sync atomically.
