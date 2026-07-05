# Vitalis iOS App — Development Guide

Welcome to **Vitalis**! This directory contains the complete source code, packages, and configurations for the iOS application. 

Following a pivot, the application is designed to be **fully local-only**, storing all health records in on-device SwiftData persistence with zero external network or database dependencies.

---

## Milestone Goals

### Milestone 1 Goals
- [x] Integrate SwiftData local persistence schema.
- [x] Set up local profile authentication concept stored in `UserDefaults` to simulate login sessions and profile switching.
- [x] Implement local-first logging of `MoodEntry` records using **SwiftData**.
- [x] Confirm: you can switch mock profiles and verify local database isolation.

### Milestone 2 Goals
- [x] Extend local persistence schema for Nutrition (`meals`, `food_items`) and Readiness (`readiness_scores`).
- [x] Create local `VitalisHealthKit` package to fetch sleep duration and HRV.
- [x] Implement client-side Readiness Score algorithm with progressive reweighting on missing sensors.
- [x] Build Today dashboard showing Readiness ring and Nutrition targets.
- [x] Build Nutrition Logging UI with manual inputs and simulated barcode scanning.

---

## 1. Setting Up Xcode Project

Since we are developing modularly using local packages, you will create a standard SwiftUI Xcode project and link the packages.

1. **Create the Project in Xcode**:
   - Create an iOS App named `Vitalis` using SwiftUI and SwiftData inside the root workspace folder.
2. **Delete Template Boilerplate**:
   - Delete the default `ContentView.swift` and `VitalisApp.swift` created by Xcode.
3. **Add Existing Files**:
   - Right-click the `Vitalis` folder inside Xcode, select **Add Files to "Vitalis"...**
   - Select all the files from `/Users/nithinvenkatesh/Documents/healthio/Vitalis/Vitalis/` to the target app.
4. **Link Local Swift Packages**:
   - Right-click the root project in Xcode, select **Add Package Dependency...** -> **Add Local...**
   - Navigate to `/Users/nithinvenkatesh/Documents/healthio/Packages/` and select:
     - `VitalisCore`
     - `VitalisPersistence` (which now includes `AuthRepository`)
     - `VitalisHealthKit`
   - Link these libraries to your **Vitalis** main target under **Frameworks, Libraries, and Embedded Content** in General Settings.
5. **Configure Entitlements**:
   - Add the **HealthKit** entitlement to request read access for Sleep Analysis and Heart Rate Variability.

---

## 2. Verification Checklists

### Milestone 1 Verification
* **Test 1 (Local Persistence)**: Tap "Get Started" to launch the Local User profile, submit a Mood entry, and verify that the mood entry is saved locally and rendered in the list immediately.

### Milestone 2 Verification

#### Test 1: HealthKit Progressive Reweighting
1. In the simulator, open settings and deny HealthKit permissions.
2. Open Vitalis: verify the Readiness Card displays: *"No HealthKit biometrics available. Enable HealthKit permissions in iOS Settings."* and has a neutral score of 50.
3. Grant **Sleep only**: Verify the Readiness score is calculated using Sleep duration only, and the explanation shows: *"Sleep was X hours. HRV data missing (reweighted 100% on HRV)."*
4. Grant **Sleep and HRV**: Verify both metrics are fetched and the composite score combines them (50% Sleep, 50% HRV).

#### Test 2: Barcode Scanning and Contributed Items
1. Tap **Log Meal** -> enter barcode `0123456789`. Confirm it scans Quaker Oats (150 kcal, 6g protein, 27g carbs, 3g fat).
2. Enter barcode `5555555555`. Confirm it displays: *"Barcode not found. Enter macro details manually below."*
3. Enter `"Greek Yogurt"`, `100` cals, `15`g protein, `6`g carbs, `0`g fat. Tap **Add to Plate** and **Log Meal**. Verify the custom food item is logged successfully.

#### Test 3: Local Database Atomic Integrity
1. Log a meal containing 2 food items.
2. Open your local app: verify that the meal card contains both food items and compiles macros aggregates correctly immediately, confirming atomic writing in SwiftData context.
