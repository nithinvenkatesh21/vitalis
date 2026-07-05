# Vitalis — Solo Build Sequence & Infra Plan
### Companion to the ECC Master Build Prompt — for a one-person team building full architecture from day one

> This document exists because "full architecture from day one" and "build everything at once" are different goals. This doc keeps the former honest without letting it become the latter.

---

## 1. The core strategy: one vertical slice, fully real, before expanding

Pick **one feature** to be the proof that the entire stack works — client, sync, backend API, database, and (if in scope for the slice) the AI Coach reading real data. Everything else stays in Phase 0/1 of the ECC Master Prompt as scaffolding-only until the slice is proven.

**Recommended first slice: Today (Readiness) + Nutrition logging.**
Why this pair specifically:
- Readiness Score is the architectural spine of the whole app (ECC Master Prompt §1.3/§20) — proving it end-to-end early validates the pattern every other feature will follow.
- Nutrition logging is the highest-frequency interaction — proving fast logging + sync early tells you immediately if the UX is actually fast enough, which is the product's core bet.
- Together they exercise: HealthKit read, local persistence, background sync to a real backend, a real Postgres write, a real GraphQL query back to the client, and a Timeline event — i.e., the whole architecture, in miniature.

**What's explicitly *not* in the first slice**, even though it's "full architecture": Watch app, Widgets, Live Activities, App Intents, AI Coach action-taking (read-only Coach queries are fine once the slice works), Family/Community, genetic integration. These are Phase 2+ per the Master Prompt — building them before the first slice works is exactly the shallow-scaffolding trap.

---

## 2. Recommended Infra for a Solo Builder (Practical, Not Aspirational)

The Master Prompt describes the "right" architecture (custom GraphQL service, dedicated background workers, S3-compatible storage). As a solo builder, you should hit that same *shape* using managed services so you're not maintaining infrastructure instead of building product:

| Layer | Master Prompt says | Solo-realistic choice | Why |
|---|---|---|---|
| Database | PostgreSQL | **Local SwiftData Store** (sandboxed SQLite) | 100% offline-first local database managed via SwiftData. Fits the server-free local design. |
| API layer | Custom GraphQL service | **None / Local Repository APIs** | Direct Swift/SwiftData access via protocol-oriented repositories, bypassing any network requests. |
| Background jobs | Dedicated workers | **None / iOS Background Tasks** | Readiness scores and database maintenance processed locally using standard iOS background processes. |
| Object storage | S3-compatible | **Local Documents Directory** | Images and logs stored directly inside the app's sandboxed Documents directory. |
| AI Coach backend | Custom Coach Service | A local mock or direct client-side model helper | Keep all logic local to the app until cloud intelligence is required. |
| Auth | Custom OAuth | **Local Auth (UserDefaults / Mock)** | Locally simulated user profiles persisted in UserDefaults, mapping to local SwiftData records. |
| Push/reminders | APNs | Local Notifications directly | Managed locally via UNUserNotificationCenter. |

This gives you a real, robust, server-free architecture—relying entirely on local SwiftData persistence and sandboxed filesystem storage. You can introduce a synchronization engine layer later if cloud backup is needed.

---

## 3. Milestone Sequence (Solo, Full-Architecture)

**Milestone 1 — Offline Skeleton and Local Storage**
1. Local schema designed and integrated into SwiftData configuration.
2. `VitalisNetworking` package: local mock auth (Sign in with Apple mapped to local session stored in UserDefaults).
3. `VitalisPersistence`: SwiftData local store containing Mood, Nutrition, and Readiness models.
4. Confirm: you can log in and persist/query mock data locally in the SwiftData container.

*Do not proceed to Milestone 2 until Milestone 1's round trip genuinely works.* This is the checkpoint that prevents the shallow-scaffolding trap.

**Milestone 2 — The vertical slice, for real**
5. Nutrition logging (manual + barcode first — camera AI recognition is Milestone 4, not now) writing through the full stack.
6. Basic Readiness Score (HRV + sleep only, from HealthKit) computed client-side first, then mirrored server-side as a background job.
7. Today screen showing both, live.
8. **Checkpoint: you use the app yourself, daily, for at least a week, before adding anything else.** If it's not fast/pleasant enough to actually want to use, fix that before expanding scope — this is the product's core bet and the cheapest point to discover a UX problem.

**Milestone 3 — Training + Timeline**
9. Workout logging (manual first).
10. `TimelineEvent` wired for every write so far — verify the Timeline screen actually shows a coherent cross-feature log.

**Milestone 4 — AI layer**
11. Read-only Vital Coach (answers questions using real Timeline data, no tool-calling yet).
12. Meal-photo recognition (CoreML) — now that manual logging patterns are understood, this is worth the investment.
13. Vital tool-calling (adjust_workout, adjust_meal_plan) — action-taking, per `vitalis-ai-coach-spec.md`.

**Milestone 5 — Everything else**
14. Recovery depth, Mind, Medical, Life-Stage, Body, Family, Community, Watch app, Widgets, Live Activities, App Intents — now built feature-by-feature on top of a proven, real, end-to-end architecture, following the ECC Master Prompt's Section 29 phases for ordering within this stage.

---

## 4. Solo-Specific Guardrails

- **One feature fully done beats three features half-scaffolded.** Apply the Definition of Done checklist (`vitalis-dod-and-edge-cases.md`) per feature before moving on — as a solo builder there's no one else to catch it later.
- **Budget a real number for AI Coach API costs and managed-service tiers before Milestone 4** — context-heavy Coach queries (full Timeline retrieval per `vitalis-ai-coach-spec.md` §3) can get expensive at scale; fine at solo-testing volume, worth checking pricing before any public launch.
- **Re-read the Compliance Checklist before Milestone 4, not after.** The disordered-eating/crisis-handling rules for Vital (Compliance Checklist §6) need to be built into the Coach Service from the start, not retrofitted once the feature already works a different way.
- **It's fine — expected, even — to swap a "solo-realistic" infra choice from Section 2 for the "Master Prompt" version later** if/when you have more resources; the schema and client architecture were designed so that swap doesn't require a rewrite. Log any such swap in the Architectural Decision Log (ECC Master Prompt §20).
