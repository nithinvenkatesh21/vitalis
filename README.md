# Vitalis iOS App — Milestone 1 Development Guide

Welcome to **Vitalis**! This directory contains the complete source code, packages, and database configurations for **Milestone 1** of the Vitalis build plan.

## Milestone 1 Goals
- [x] Configure a real Supabase/Postgres backend.
- [x] Set up compile-time gated debug Mock Authentication.
- [x] Implement local-first logging of `MoodEntry` records using **SwiftData**.
- [x] Integrate **Supabase client** for remote uploads.
- [x] Sync `MoodEntry` and `TimelineEvent` records as an **atomic, single Postgres transaction** (using Postgres RPC function).
- [x] Support automatic outbox queue sync on network connection restoration.

---

## 1. Supabase Project Setup

1. **Create a Project**:
   - Go to [Supabase Console](https://database.new) and create a new project.
2. **Execute Database Migrations**:
   - Navigate to the **SQL Editor** tab in your Supabase dashboard.
   - Click **New Query**, copy the contents of [backend/schema.sql](file:///Users/nithinvenkatesh/Documents/healthio/vitalis-ios/backend/schema.sql) into the editor, and click **Run**.
   - Verify that three tables are created: `users`, `mood_entries`, and `timeline_events`.
   - Verify that the function `log_mood_with_timeline` is present in the database schemas under RPCs.
3. **Configure Authentication (For native Sign in with Apple in production)**:
   - Go to **Authentication** -> **Providers** -> **Apple**.
   - Toggle **Enable Apple provider** and fill in your Apple Developer Details (Team ID, Service ID, Private Key, Key ID).
   *(Note: For simulator testing, you can use the debug mock login buttons which use Supabase email/password providers under the hood to bypass Apple credential checking on simulators).*

---

## 2. Setting Up Xcode Project

Since we are developing modularly using local packages, you will create a standard SwiftUI Xcode project and link the packages.

1. **Create the Project in Xcode**:
   - Open Xcode and choose **File** -> **New** -> **Project**.
   - Choose **iOS** -> **App**. Click Next.
   - Set **Product Name** to: `Vitalis`.
   - Set **Organization Identifier** to your domain (e.g. `com.vitalis`).
   - Set **Interface** to: `SwiftUI`.
   - Set **Language** to: `Swift`.
   - Make sure **Storage** is set to `SwiftData`. Click Next.
   - Choose the target folder to save the project (save it inside `/Users/nithinvenkatesh/Documents/healthio/vitalis-ios`). Make sure it is named `Vitalis`.
2. **Delete Template Boilerplate**:
   - Inside Xcode, delete the default `ContentView.swift` and `VitalisApp.swift` created by Xcode.
3. **Add Existing Files**:
   - Right-click the `Vitalis` folder inside Xcode, select **Add Files to "Vitalis"...**
   - Select the following files from `/Users/nithinvenkatesh/Documents/healthio/vitalis-ios/Vitalis/`:
     - `VitalisApp.swift`
     - `ContentView.swift`
     - `DashboardView.swift`
     - `DashboardViewModel.swift`
     - `OnboardingView.swift`
   - Make sure they are added to the `Vitalis` app target.
4. **Link Local Swift Packages**:
   - Right-click the root project file in Xcode, select **Add Package Dependency...**
   - Click **Add Local...** button at the bottom.
   - Navigate to `/Users/nithinvenkatesh/Documents/healthio/vitalis-ios/Packages/` and select:
     - `VitalisCore`
     - `VitalisNetworking`
     - `VitalisPersistence`
   - Link these libraries to your `Vitalis` main target:
     - Open the project settings -> Select the **Vitalis** target -> Select **General** tab.
     - Scroll to **Frameworks, Libraries, and Embedded Content**.
     - Ensure `VitalisCore`, `VitalisNetworking`, and `VitalisPersistence` are added.
5. **Configure Entitlements & Background Services**:
   - Add the **Keychain Sharing** entitlement to allow Supabase Auth sessions to persist across runs.
   - Make sure your deployment target is set to **iOS 17.0** or later.

---

## 3. Credentials Configuration

Before building, open [Packages/VitalisNetworking/Sources/VitalisNetworking/SupabaseConfig.swift](file:///Users/nithinvenkatesh/Documents/healthio/vitalis-ios/Packages/VitalisNetworking/Sources/VitalisNetworking/SupabaseConfig.swift) and replace placeholders with your project details:

```swift
public enum SupabaseConfig {
    public static var supabaseURL = URL(string: "https://<your-project-id>.supabase.co")!
    public static var supabaseAnonKey = "<your-anon-public-key>"
}
```

---

## 4. Verification Checklist

Follow these steps to manually verify Milestone 1:

### Test 1: Atomic Sync and Timeline Linkage
1. Run the app in the Simulator.
2. Use a debug Mock button to sign in as **User A**.
3. Tap **Log Mood Entry (Test)**.
4. Open the Supabase SQL editor or Table Editor:
   - Check the `mood_entries` table: confirm one new row belongs to User A.
   - Check the `timeline_events` table: confirm one new row was created with type `mood_entry`.
   - Verify the `linked_entity_ids` column in `timeline_events` contains the UUID of the inserted `mood_entry` row, proving successful atomic linkage.

### Test 2: RLS Data Isolation
1. Sign out of **User A**.
2. Sign in as **User B** on the simulator.
3. Observe that the dashboard list is completely empty (User B cannot fetch User A's logs).
4. Tap **Log Mood Entry (Test)** for User B.
5. Inspect the database: verify that the new entries have User B's UUID.
6. Verify User B can only see their own entry in the app.

### Test 3: Offline outbox & Connection Re-establishment
1. While logged in, disconnect the Xcode simulator from the network (e.g. disable Wi-Fi on the host Mac or disable cellular in Simulator settings).
2. Tap **Log Mood Entry (Test)**.
3. Observe the row renders in the list with a badge marked **"Pending"** in orange.
4. Verify the database in the Supabase console shows no new entries (verifying offline caching).
5. Turn the network connection back on.
6. The `NWPathMonitor` triggers `processOutbox()` automatically.
7. Verify that the row badge transitions to a green checkmark indicating **"Synced"**.
8. Refresh/check the database: verify the new records exist in Supabase.
