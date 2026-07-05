# Vitalis — API Schema (GraphQL SDL)
### Companion to the ECC Master Build Prompt, Section 21

> Core schema for the entities defined in the ECC Master Prompt §13–14. This is a starting contract — extend it as features are built, but do not casually rename existing fields; treat this file as versioned (bump a comment header when breaking changes are made).

---

## 1. Scalars & Shared Enums

```graphql
scalar Date
scalar DateTime
scalar JSON

enum LoggingMethod { PHOTO BARCODE VOICE MANUAL }
enum WorkoutType { STRENGTH RUN BIKE SWIM ROW HIKE MOBILITY OTHER }
enum CyclePhase { MENSTRUAL FOLLICULAR OVULATION LUTEAL PREGNANCY POSTPARTUM PERIMENOPAUSE MENOPAUSE NOT_TRACKED }
enum PermissionScope { READ WRITE NONE }
```

---

## 2. Core Types

```graphql
type User {
  id: ID!
  displayName: String!
  demographics: JSON
  goals: JSON
  familyGroupId: ID
  createdAt: DateTime!
}

type BiometricSample {
  id: ID!
  userId: ID!
  type: String!        # "heart_rate" | "hrv" | "spo2" | "resp_rate" | "skin_temp" | "vo2_max" | ...
  value: Float!
  unit: String!
  timestamp: DateTime!
  sourceDevice: String
}

type SleepSession {
  id: ID!
  userId: ID!
  start: DateTime!
  end: DateTime!
  stages: JSON          # [{stage, start, end}]
  efficiency: Float
  latencyMinutes: Int
}

type FoodItem {
  id: ID!
  name: String!
  brand: String
  macros: JSON!
  micros: JSON
  confidenceScore: Float
}

type Meal {
  id: ID!
  userId: ID!
  timestamp: DateTime!
  method: LoggingMethod!
  items: [FoodItem!]!
  estimatedMacros: JSON!
  estimatedMicros: JSON
}

type SetLog {
  id: ID!
  exerciseId: ID!
  load: Float
  reps: Int
  tempo: String
  rpe: Float
  restSeconds: Int
}

type WorkoutSession {
  id: ID!
  userId: ID!
  timestamp: DateTime!
  type: WorkoutType!
  sets: [SetLog!]
  rpe: Float
  trainingLoad: Float
}

type ReadinessScore {
  id: ID!
  userId: ID!
  date: Date!
  compositeScore: Float!
  components: JSON!      # {hrv: 0.3, sleep: 0.3, training_load: 0.2, illness_signal: 0.2}
  explanation: [String!]!
}

type MoodEntry {
  id: ID!
  userId: ID!
  timestamp: DateTime!
  valence: Float!
  tags: [String!]
  freeText: String
}

type Medication {
  id: ID!
  userId: ID!
  drugName: String!
  dose: String!
  schedule: JSON!
}

type MedicationAdherenceEvent {
  id: ID!
  medicationId: ID!
  timestamp: DateTime!
  taken: Boolean!
}

type LabResult {
  id: ID!
  userId: ID!
  panel: String!
  marker: String!
  value: Float!
  unit: String!
  referenceRange: String
  date: Date!
  sourceDocUrl: String
}

type SymptomLog {
  id: ID!
  userId: ID!
  timestamp: DateTime!
  symptom: String!
  severity: Int!
  bodyLocation: String
  correlations: JSON
}

type CycleDataPoint {
  id: ID!
  userId: ID!
  date: Date!
  phase: CyclePhase!
  flow: String
  symptoms: [String!]
}

type BodyCompositionEntry {
  id: ID!
  userId: ID!
  date: Date!
  weight: Float
  bodyFatPct: Float
  measurements: JSON
  photoRef: String
}

type Habit {
  id: ID!
  userId: ID!
  name: String!
  cadence: String!
  streak: Int!
  adherenceModel: JSON
}

type TimelineEvent {
  id: ID!
  userId: ID!
  timestamp: DateTime!
  type: String!
  payload: JSON!
  linkedEntityIds: [ID!]
}

type FamilyGroup {
  id: ID!
  members: [User!]!
  sharedPermissions: JSON!
}
```

---

## 3. Queries

```graphql
type Query {
  me: User!

  readinessScore(date: Date!): ReadinessScore
  readinessTrend(startDate: Date!, endDate: Date!): [ReadinessScore!]!

  meals(startDate: Date!, endDate: Date!): [Meal!]!
  nutritionSummary(date: Date!): JSON!   # rollup: macros vs targets, micronutrient gaps

  workoutSessions(startDate: Date!, endDate: Date!): [WorkoutSession!]!
  personalRecords: [JSON!]!

  sleepSessions(startDate: Date!, endDate: Date!): [SleepSession!]!

  moodEntries(startDate: Date!, endDate: Date!): [MoodEntry!]!

  medications: [Medication!]!
  medicationAdherence(medicationId: ID!, startDate: Date!, endDate: Date!): [MedicationAdherenceEvent!]!

  labResults(panel: String): [LabResult!]!
  symptomLogs(startDate: Date!, endDate: Date!): [SymptomLog!]!
  symptomCorrelations(symptom: String!, lookbackDays: Int!): JSON!

  cycleData(startDate: Date!, endDate: Date!): [CycleDataPoint!]!
  bodyCompositionTrend(startDate: Date!, endDate: Date!): [BodyCompositionEntry!]!

  habits: [Habit!]!

  timeline(startDate: Date!, endDate: Date!, types: [String!]): [TimelineEvent!]!

  familyGroup: FamilyGroup
}
```

---

## 4. Mutations

```graphql
type Mutation {
  logMeal(method: LoggingMethod!, items: [JSON!]!, timestamp: DateTime!): Meal!
  logWorkoutSession(type: WorkoutType!, sets: [JSON!], rpe: Float): WorkoutSession!
  logMoodEntry(valence: Float!, tags: [String!], freeText: String): MoodEntry!
  logMedicationTaken(medicationId: ID!, timestamp: DateTime!, taken: Boolean!): MedicationAdherenceEvent!
  logSymptom(symptom: String!, severity: Int!, bodyLocation: String): SymptomLog!
  logBodyComposition(weight: Float, bodyFatPct: Float, measurements: JSON, photoRef: String): BodyCompositionEntry!
  logCycleData(date: Date!, phase: CyclePhase!, flow: String, symptoms: [String!]): CycleDataPoint!

  upsertMedicationSchedule(drugName: String!, dose: String!, schedule: JSON!): Medication!
  updateHabit(id: ID!, cadence: String, name: String): Habit!

  # Vital (AI Coach) action tools — mirrors vitalis-ai-coach-spec.md §4
  adjustWorkout(sessionDate: Date!, adjustmentType: String!, reasoning: String!): WorkoutSession!
  adjustMealPlan(date: Date!, constraintChanges: String!): JSON!
  proposeCalendarChange(eventId: ID!, proposedChange: String!, reasoning: String!): JSON!
  draftAppointmentSummary(startDate: Date!, endDate: Date!, focusSymptoms: [String!]): String!

  updatePermissionScope(category: String!, scope: PermissionScope!): JSON!
  requestDataExport: String!   # returns a signed URL to the export bundle
  requestAccountDeletion: Boolean!
}
```

---

## 5. Subscriptions (Real-Time)

```graphql
type Subscription {
  readinessScoreUpdated(userId: ID!): ReadinessScore!
  timelineEventAdded(userId: ID!): TimelineEvent!
  medicationReminderDue(userId: ID!): Medication!
}
```
Used for: live Readiness updates after a wearable sync, Timeline live-scroll updates, and push-equivalent in-app medication reminders while the app is foregrounded (background reminders still go through APNs, not this subscription).

---

## 6. Notes for ECC

- Every mutation that writes to a domain table must also enqueue a corresponding `TimelineEvent` — enforce this at the resolver layer with a shared `withTimelineEvent()` wrapper rather than remembering to do it per-resolver.
- All queries/mutations are scoped to the authenticated user via row-level security; `familyGroup`/caregiver queries require an explicit granted-permission check, not just group membership.
- `JSON` scalar fields (macros, components, schedule, etc.) should still have a documented shape maintained in `VitalisCore` shared types on the client, even though GraphQL treats them as opaque — keep a `Codable` struct in Swift mirroring each JSON field to avoid silent shape drift between client and server.
