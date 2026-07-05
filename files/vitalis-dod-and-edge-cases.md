# Vitalis — Definition of Done & Edge Case Catalog
### Companion to the ECC Master Build Prompt

> Use Section 1 as a per-feature checklist before marking any module "complete." Use Section 2 as a catalog to check against when building — most "unfinished-feeling" agent-built apps fail here, not in the happy path.

---

## 1. Definition of Done (apply to every feature module)

A feature is **not done** until all of the following are true:

**Functional**
- [ ] Happy path works fully offline (logs locally, syncs when reconnected).
- [ ] Works with zero HealthKit permissions granted (degrades gracefully, doesn't crash or block).
- [ ] Works with zero prior data (empty state is designed, not a blank screen).
- [ ] Every write path produces a corresponding `TimelineEvent` (ECC Master Prompt §14/§21).

**UI/UX**
- [ ] Tested at largest Dynamic Type accessibility size — nothing clips or overlaps.
- [ ] Tested in both Light and Dark Mode as distinct designs, not just color inversion.
- [ ] Tested with VoiceOver on — every interactive element has a meaningful label.
- [ ] Tested with Reduce Motion on — animations degrade to instant/simple transitions.
- [ ] Primary action completable in 3 taps or fewer, one-handed.

**Data & Privacy**
- [ ] Feature respects per-category sharing permission settings (doesn't leak data to Family/Community views without explicit grant).
- [ ] Any new data type added to the data-export bundle and deletion routine — nothing new that opts out of the account-deletion guarantee silently.

**Testing**
- [ ] Unit tests exist for the ViewModel/UseCase layer (not just UI snapshot tests).
- [ ] At least one edge case from Section 2 relevant to this feature has an explicit test or manual QA pass.

**Documentation**
- [ ] Any deviation from the ECC Master Prompt or Product Spec is logged in the Architectural Decision Log (ECC Master Prompt §20).

---

## 2. Edge Case Catalog by Module

### Cross-Cutting (applies everywhere)
- No internet connection on first launch (onboarding must still be completable).
- HealthKit permission denied or later revoked mid-use (feature should degrade, not error-loop).
- User has no wearable at all — every "wearable-enhanced" feature needs a phone-only fallback.
- App backgrounded mid-log (camera capture, workout session) — state must be recoverable.
- Two devices editing the same day's data offline, then both come online (conflict resolution per ECC Master Prompt §25).
- Time zone changes mid-session (travel) — dates/streaks must not double-count or skip a day.
- User revokes a previously-granted permission (Family sharing, HealthKit) — access must be cut immediately, not on next sync.

### Nutrition
- Camera meal recognition returns low-confidence or no match — must offer manual search, never block logging.
- Barcode scan finds no product in database — offer manual entry with an option to contribute the product.
- CGM disconnects mid-day — glucose-response predictions should silently fall back to non-CGM estimates, not show stale/wrong data.
- Restaurant meal has no menu data available — macro estimate should say "estimated" clearly, not present as precise.

### Training
- User logs a workout with no prior history for that exercise (no 1RM baseline yet) — auto-programming must have a cold-start default.
- Wearable disconnects mid-workout (rest timer, HR zones) — session must still be loggable from manual RPE/set entry.
- User skips several planned sessions in a row — auto-regulation should adjust the program down, not keep prescribing an unrealistic plan.

### Recovery/Readiness
- Insufficient data to compute a component (e.g., no HRV sensor) — Readiness Score must reweight remaining components and disclose it's a partial score, not silently substitute a guess.
- Illness detected (elevated resting HR + temperature deviation) — Readiness should flag this distinctly from normal fatigue, not just show a low number with no context.

### Medical
- OCR lab import misreads a value — user must be able to correct it before it enters the trend, and correction should be easy, not buried.
- Drug interaction check flags a false positive — must show the flag with severity and a "discuss with pharmacist/doctor" framing, never auto-block logging entirely.
- User has multiple prescribers/pharmacies — medication list must support duplicate-name conflict resolution.

### Life-Stage
- Cycle tracking detects a likely pregnancy — mode-switch prompt must be opt-in, sensitively worded, and reversible without data loss.
- User skips logging for a full cycle (missed data) — predictions must clearly show reduced confidence rather than presenting stale predictions as current.

### AI Coach (Vital)
- Insufficient data to answer a query confidently — Vital must say so and suggest what data would help, never fabricate a confident-sounding answer.
- User pushes back on or undoes an autonomous action — must be one tap, and Vital should not repeat the same auto-action again without being asked.
- Crisis-language input (self-harm, medical emergency) — no tool calls attempted; supportive response + resources only (see Compliance Checklist §6).

### Family/Caregiver
- A family member revokes shared access — caregiver view must lose access immediately, including cached data on-device.
- Minor's account reaching age of majority — data-ownership transition flow must exist, not be an afterthought.

### Offline/Sync
- User logs the same workout twice from two devices while offline — dedup logic must exist before both syncs are accepted.
- Large data import (bulk HealthKit history on first connect) — must be chunked/background-processed, not block the UI or timeout.
