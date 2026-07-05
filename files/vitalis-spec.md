# VITALIS — The Unified Health Operating System
### Master Product Specification & Vision Prompt v1.0

> **How to use this document:** This is written as both (a) a complete product specification and (b) a reusable "master prompt" — copy any section into a design, engineering, or fundraising context and it will stand on its own. Sections are self-contained but cross-reference each other, mirroring the interconnected architecture of the product itself.

---

## 0. Core Thesis

Every existing health app optimizes one slice of a person's life: MyFitnessPal owns calories, Strava owns workouts, WHOOP owns recovery, Oura owns sleep, Flo owns cycles, Calm owns mindfulness, Apple Health owns aggregation-without-intelligence. The result is a person's health data scattered across 8–15 silos that never talk to each other, forcing *the human* to be the integration layer.

**Vitalis's thesis:** health is one system, not fifteen apps. Sleep affects glucose. Cycle phase affects strength output. Air quality affects HRV. A missed dose affects mood. Travel affects everything. The product that wins is the one that treats the *person* as the unit of analysis, not the metric.

**Vitalis is not a dashboard. It is a continuously-reasoning health operating system with a body.**

Three design principles govern every feature below:
1. **One Timeline, One Model.** Every data point (a meal, a workout, a lab result, a mood entry, a missed pill) feeds a single longitudinal model of the user, not a separate silo.
2. **Insight over Input.** The app should feel like it's doing work *for* the user (predicting, warning, adjusting) not just recording what they tell it.
3. **Closed Loops.** Every tracked metric connects to an action: don't just show HRV is low — change today's workout, meal suggestions, and calendar automatically.

---

## 1. Feature Categories (Complete Taxonomy)

Each category below follows the same structure: **Why it exists → How users interact → Cross-feature connections → Data collected → Insights delivered → AI enhancement → Why it beats today's best app.**

### 1.1 Nutrition Intelligence
**Sub-features:** AI photo meal recognition (multi-item plate segmentation, portion estimation via depth/reference-object computer vision), barcode + restaurant menu OCR scanning, voice logging ("I had two eggs and toast"), macro + full micronutrient tracking (all 13 vitamins, 16+ minerals, fiber types, omega-3/6 ratio), hydration tracking with sweat-rate-adjusted targets, recipe importer (URL/photo → structured recipe), AI meal generation from goals + what's actually in your fridge/pantry (via photo or grocery receipt scan), restaurant meal predictor (estimate macros before you order using GPS + menu DB), continuous glucose response tracking (CGM integration), personalized glycemic response scoring (Levels-style, but merged with training load context), nutrient-timing recommendations tied to workout schedule, food sensitivity pattern detection (correlate symptom logs with ingredients over time), grocery list auto-generation from planned meals, fasting window tracker tied to sleep and circadian data.

- **Why:** Nutrition is the highest-frequency, highest-friction data entry point in health tracking; abandonment is the #1 failure mode of every nutrition app.
- **How users interact:** Primary logging is passive-first — camera, barcode, or receipt scan is the default; typing is the fallback, not the norm.
- **Connects to:** Workout module (pre/post-workout nutrition timing), Recovery engine (glucose variability feeds readiness score), Symptom tracker (food-symptom correlation), Medical records (allergies auto-block suggestions), Family dashboard (shared grocery lists).
- **Data collected:** Meal photos, macro/micronutrient estimates, CGM streams, water intake, fasting windows, restaurant GPS check-ins.
- **Insights:** Weekly micronutrient gap report, glycemic variability trend, "foods that correlate with your afternoon fatigue," optimal pre-workout meal timing personalized to gut response speed.
- **AI enhancement:** Vision transformer for plate segmentation + volumetric portion estimation; personalized glycemic prediction model trained on the user's own CGM history rather than generic tables; LLM-based meal generation constrained by pantry inventory, budget, and macro targets.
- **Beats today's apps because:** Cronometer has the data depth but zero automation; MyFitnessPal has the logging convenience but shallow micronutrients and no glucose context; nobody merges CGM + training load + pantry inventory into one generative meal planner.

### 1.2 Training & Movement
**Sub-features:** Strength training logger (sets/reps/RPE/tempo/rest timer), full exercise library with 3D muscle-activation animations, cardio tracking (run/bike/swim/row/hike with GPS, pace zones, elevation), progressive overload auto-detection and 1RM estimation, personal records wall, auto-regulated programming (adjusts next session's load based on readiness score, not a fixed spreadsheet), muscle-group heat-map showing weekly volume vs. recovery status per muscle group, injury-risk flagging (asymmetry detection from wearable + form-check camera analysis), mobility/flexibility tracking, adaptive workout builder (AI generates today's session from equipment available, time available, and recovery score), form-check via phone camera with joint-angle feedback, VO2 max estimation and trend, training load / ACWR (acute:chronic workload ratio) to flag overtraining risk.

- **Why:** Users abandon rigid programs; the biggest unlock is a program that adapts daily rather than a static PDF.
- **How users interact:** Log during workout (large touch targets, rest timer, voice logging "3 reps at 225"), review a single daily "today's session" card generated automatically.
- **Connects to:** Recovery engine (readiness gates intensity), Nutrition (auto-suggests protein/carb targets on lift days), Sleep (poor sleep → auto-swaps heavy day for technique day), Menstrual cycle (phase-aware programming), Calendar (auto-schedules around meetings/travel).
- **Data collected:** Sets/reps/load/RPE, GPS routes, cadence, power (via smart trainers), heart-rate zones, joint-angle video (optional, on-device processed).
- **Insights:** Volume-per-muscle-group trend vs hypertrophy targets, overtraining risk score, strength plateau detection with auto-deload suggestion.
- **AI enhancement:** RL-style policy that adjusts programming variables (load, volume, exercise selection) based on multi-day readiness trend, not just today's number; computer-vision form scoring done on-device for privacy.
- **Beats today's apps because:** Hevy/Strong are excellent loggers but static planners; Nike Training Club has good content but no biometric adaptation; nobody closes the loop between wearable readiness and next session's actual prescribed weights.

### 1.3 Recovery & Readiness Engine
**Sub-features:** Daily Readiness Score (HRV, RHR, sleep quality/debt, training load, cycle phase, illness signals, travel/jet-lag, stress logs — weighted personalized model), sleep architecture tracking (stages, latency, efficiency, consistency score, temperature/environment correlation), HRV trend with baseline personalization, respiratory rate, skin temperature deviation (illness early-warning), recovery-modality logging (sauna, cold plunge, massage, stretching) with efficacy tracking per-user, smart schedule suggestions ("move your 6am lift to 4pm — your body needs 2 more hours").

- **Why:** This is the single feature that most differentiates WHOOP/Oura from Apple Health, and it should be the *spine* of the whole app, not a side widget — every other module reads from it.
- **Connects to:** Literally every other category (this is the central nervous system of the product).
- **AI enhancement:** Personalized baselines (not population averages) using rolling Bayesian updating; causal-inference-style attribution ("your HRV dropped 12% — most correlated with alcohol + late meal, based on your last 40 days").
- **Beats today's apps because:** WHOOP's recovery score doesn't know what you ate or that you're mid-cycle; Oura doesn't touch your training plan. Vitalis's score directly rewrites today's workout, meal suggestions, and calendar.

### 1.4 Mental Wellbeing
**Sub-features:** Mood journaling (quick tap + optional free text, voice-to-text), guided meditation and breathwork library, real-time stress detection (HRV-based, wearable-triggered "you seem stressed — 2 min breathing?" nudge), CBT-style thought-record tools, gratitude/reflection prompts, burnout-risk trend (workload + sleep debt + mood variance), therapy/journaling export for clinicians, digital detox / screen-time correlation with mood.

- **Connects to:** Recovery engine (stress feeds readiness), Sleep (mood-sleep correlation), Habit tracker (meditation streaks), Calendar (auto-suggests recovery breaks before/after known stressful events).
- **AI enhancement:** Passive stress detection from HRV + typing cadence + calendar density, triggering *just-in-time* interventions rather than requiring the user to remember to check in.
- **Beats today's apps because:** Calm/Headspace are content libraries with no biometric awareness; Vitalis meditations are triggered by actual physiological stress state, and outcomes (did HRV recover after this session?) are measured and used to personalize which technique works best for *this* user.

### 1.5 Medical & Medication Management
**Sub-features:** Prescription logging with refill reminders and interaction/allergy checking, supplement stack tracker with evidence-quality tags and interaction warnings, symptom tracker with body-map input and pattern detection, lab result storage (OCR-imported PDFs parsed into structured trend lines), vaccination records, doctor appointment scheduling with auto-generated visit summaries (from the health timeline) to bring to the doctor, digital medical passport (allergies, conditions, medications, blood type, emergency contacts, accessible from lock screen/NFC for EMTs), telehealth integration hooks, genetic data integration (23andMe/Nebula import for pharmacogenomics and disease-risk context).

- **Why:** This is the category legacy fitness apps ignore entirely and where Apple Health only partially succeeds (great storage, near-zero intelligence).
- **Connects to:** Nutrition (allergy/interaction blocking), Recovery (illness detection auto-adjusts training), Family dashboard (shared pediatric records), Symptom tracker (correlate lab trends with logged symptoms).
- **AI enhancement:** LLM-assisted lab-trend explanation in plain language with flags for "discuss with your doctor," drug-drug and drug-supplement interaction checking, auto-drafted visit summary from the timeline so appointments take 5 minutes instead of 20.
- **Beats today's apps because:** No consumer app currently unifies prescriptions + labs + genetics + symptoms + a doctor-ready summary generator in one longitudinal, patient-owned record.

### 1.6 Reproductive & Life-Stage Health
**Sub-features:** Period and ovulation tracking with symptom correlation, fertility prediction, pregnancy tracking (week-by-week, symptom log, appointment tracker), postpartum recovery tracking, perimenopause/menopause symptom tracking (a massively underserved category), cycle-phase-aware training and nutrition adaptation across the whole app.

- **Connects to:** Training (auto-adjusts intensity expectations by phase), Mood (correlates with hormonal phase), Nutrition (cravings/iron needs by phase).
- **Beats today's apps because:** Flo/Clue are excellent standalone but disconnected from training and nutrition; Vitalis makes cycle phase a first-class variable across the entire app, and extends the category through menopause, which most competitors abandon.

### 1.7 Body Composition & Progress
**Sub-features:** Weight trend (noise-smoothed, not raw daily weigh-ins), body-fat % (smart-scale + photo-based estimation via computer vision), progress photo timeline with auto-alignment/lighting normalization, circumference measurements, posture analysis via photo.

- **AI enhancement:** Computer-vision body composition estimation from photos to reduce dependence on expensive DEXA/BIA hardware, trend-smoothing algorithms (like Trendweight) applied by default so users aren't demoralized by daily fluctuation.

### 1.8 Environmental & Contextual Health
**Sub-features:** Air quality and pollen exposure tracking tied to symptom logs (correlate allergy flare-ups with AQI), UV exposure and sun-safety reminders, travel health mode (jet-lag adjustment plan, destination vaccination requirements, water-safety advisories, time-zone-aware sleep coaching), noise exposure tracking (hearing health, via watch), smart-home integration (thermostat/lighting adjustments for sleep optimization, air purifier triggers on high-pollen days).

- **Beats today's apps because:** This category barely exists today in integrated form — it's the clearest "entirely new category" opportunity.

### 1.9 Habit & Behavior Intelligence
**Sub-features:** Universal habit tracker (any behavior, not just health), streak mechanics, "habit stacking" suggestions, adherence-pattern detection ("you complete habits 80% more often before 10am"), automatic habit-difficulty adjustment.

- **AI enhancement:** Behavioral model per user that learns *when and how* they successfully form habits and reschedules reminders accordingly instead of firing at a fixed time for everyone.

### 1.10 Family & Household Health
**Sub-features:** Multi-profile family dashboard (kids, aging parents, pets optional), shared medication schedules, shared grocery/meal planning, caregiver mode with permissioned access, emergency preparedness checklist (first-aid kit status, emergency contacts, evacuation info).

### 1.11 Social & Community
**Sub-features:** Opt-in challenges (steps, workouts, meditation streaks), friend leaderboards with privacy-respecting metric selection, workout-buddy matching, coach/trainer sharing view, community-verified recipe and workout sharing.

---

## 2. Genuinely New Categories (Beyond Any Current App)

1. **Longevity Score & Biological Age Estimation** — a single, explainable composite (VO2 max, HRV, body comp, sleep consistency, inflammatory-adjacent markers from labs, glucose stability) updated continuously, with a clear breakdown of what's raising/lowering it and *specific, prioritized levers* to improve it — not a black-box number.
2. **AI Health Coach ("Vital")** — a persistent conversational agent with full context of the user's entire timeline (nutrition, training, labs, mood, calendar), able to answer "why am I so tired this week" with an actual causal explanation, and able to *take action* (reschedule a workout, adjust tomorrow's meal plan, draft the doctor-visit summary) rather than just chat.
3. **Health Risk Prediction** — longitudinal-trend-based early warning for conditions with strong lifestyle signals (metabolic syndrome trajectory, cardiovascular risk trend, insomnia-linked risk), always framed as "discuss with a clinician," never a diagnosis.
4. **Nutrient Deficiency Prediction** — inferred from diet logs + labs + symptoms, flagged *before* it becomes a lab-confirmed deficiency.
5. **Injury Prevention Engine** — combines training load, asymmetry data, sleep, and prior injury history to flag elevated injury risk for a specific movement pattern before it happens.
6. **Energy & Burnout Prediction** — forecasts the user's energy levels for the day/week ahead based on sleep debt, training load, and calendar density, and burnout risk over a period of weeks.
7. **Smart Recovery-Aware Scheduling** — two-way calendar integration that proposes moving meetings/workouts based on predicted readiness, and negotiates around fixed commitments.
8. **Continuous Health Timeline & Life-Event Log** — a single infinite scroll of everything (illness, injury, medication change, major life events like a move or job change) so long-term correlations become visible ("every job change year, sleep quality drops for 6 weeks").
9. **Digital Medical Passport** — offline-accessible, NFC/lock-screen emergency medical ID plus a full portable record a user can hand to any new doctor.
10. **Household/Family Health Constellation** — treats the family unit, not just the individual, as a first-class object (shared risk factors, genetics, caregiving logistics).
11. **Environmental Health Layer** — as above, a genuinely missing integrated category.
12. **Travel Health Mode** — a temporary, destination-aware overlay of the whole app (jet lag plan, local health risks, adjusted goals).
13. **Genetic & Multi-Omic Integration** — pharmacogenomic interaction warnings, disease predisposition context blended (not replacing) lifestyle data.
14. **Health Gamification with Real Stakes** — optional integrations with insurance wellness programs or financial-stake commitment contracts (e.g., Stickk-style), tied to *verified* wearable data.
15. **Predictive Grocery & Supply Chain** — auto-reordering supplements/medications before they run out, predictive grocery lists based on the AI meal plan for the week.

---

## 3. Core User Flows

**Flow A — Morning Check-In (10 seconds):** Wake → watch syncs overnight data → push notification with Readiness Score → tap opens home screen already reconfigured: today's workout auto-adjusted, meal suggestions pre-populated, calendar flagged if a meeting should move.

**Flow B — Meal Logging (under 15 seconds):** Camera opens directly to meal capture → AI segments plate, estimates macros → one-tap confirm or adjust portion sliders → auto-logged, glucose-response prediction shown, running daily totals update.

**Flow C — Workout Session:** Open today's auto-generated session → log sets via voice or tap → rest timer auto-starts → post-workout: RPE prompt → session auto-feeds into training-load and readiness models.

**Flow D — Symptom Investigation:** User logs "headache" → app cross-references sleep, hydration, screen time, barometric pressure, and menstrual phase from the last 72 hours → surfaces top 2–3 correlated factors → offers to log a note for the doctor.

**Flow E — Doctor Visit Prep:** User taps "Prepare for appointment" → AI drafts a one-page summary (new symptoms, medication changes, relevant trends) from the timeline → user edits/approves → exports as PDF or shares directly with clinic's portal.

**Flow F — AI Coach Conversation:** User asks "why do I feel exhausted this week?" → Vital pulls sleep debt, training load, cycle phase, and recent illness signals → gives a plain-language causal explanation → offers to lighten tomorrow's plan automatically.

---

## 4. Navigation Architecture

```
Home (Today) ── Readiness Score, AI Coach entry point, today's adjusted plan
├── Nutrition ── Log · Recipes · Meal Plan · Micronutrients · Glucose
├── Train ────── Today's Session · History · Exercise Library · PRs · Programs
├── Recover ──── Sleep · HRV/Readiness · Stress · Modalities
├── Mind ─────── Mood · Meditate · Breathe · Journal
├── Medical ──── Meds & Supplements · Labs · Symptoms · Records · Appointments
├── Cycle/Life ─ Period/Fertility/Pregnancy/Menopause (age/gender adaptive)
├── Body ─────── Weight · Composition · Photos · Measurements
├── Family ───── Shared Dashboard · Caregiver View
├── Community ── Challenges · Friends · Coach Sharing
└── Timeline ─── Infinite longitudinal log + Digital Medical Passport + Settings
```
A persistent floating "Vital" (AI coach) entry point is available from every screen — this is the connective tissue, not a separate module.

---

## 5. Data Model (Core Entities, Simplified)

```
User { id, demographics, goals, permissions, family_group_id }
BiometricSample { user_id, type[HR|HRV|SpO2|RespRate|SkinTemp|VO2Max...], value, timestamp, source_device }
SleepSession { user_id, start, end, stages[], efficiency, latency, environment_context }
Meal { user_id, timestamp, items[FoodItem], method[photo|barcode|voice|manual], estimated_macros, estimated_micros }
FoodItem { name, brand, macros, micros, source_db_id, confidence_score }
WorkoutSession { user_id, timestamp, type, exercises[SetLog], readiness_input, rpe, training_load }
SetLog { exercise_id, load, reps, tempo, rpe, rest_seconds }
ReadinessScore { user_id, date, composite_score, component_weights{}, explanation[] }
MoodEntry { user_id, timestamp, valence, arousal_optional, tags[], free_text }
MedicationSchedule { user_id, drug_name, dose, schedule, interactions_checked, adherence_log[] }
LabResult { user_id, panel, marker, value, unit, reference_range, date, source_doc }
SymptomLog { user_id, timestamp, symptom, severity, body_location, candidate_correlations[] }
CycleData { user_id, date, phase, flow, symptoms[], predicted_ovulation }
BodyComposition { user_id, date, weight, body_fat_pct, measurements{}, photo_ref }
Habit { user_id, name, cadence, streak, adherence_pattern_model }
TimelineEvent { user_id, timestamp, type, payload, linked_entities[] } // universal event spine
FamilyGroup { id, members[User], shared_permissions }
```
All entities key off `user_id` and feed into a single `TimelineEvent` stream — this is what makes cross-feature correlation possible instead of siloed tables.

---

## 6. AI-Powered Capabilities (Cross-Cutting Layer)

- **Personalized baseline modeling** — every metric is judged against *this user's* rolling distribution, not population norms.
- **Causal-pattern surfacing** — lightweight causal-inference techniques (not just correlation) to explain "why," with confidence levels shown honestly.
- **Generative planning** — meals, workouts, and schedules are generated, not just logged.
- **Computer vision** — meal recognition, form-checking, body composition estimation, lab-report OCR.
- **Conversational agent (Vital)** — full-context assistant with the ability to take actions (reschedule, adjust plans, draft summaries), not just answer questions.
- **Predictive alerts** — illness onset, injury risk, burnout, nutrient deficiency, overtraining — always framed as risk signals for the user (and optionally their clinician) to evaluate, never as diagnoses.
- **On-device-first processing** for sensitive computer-vision tasks (form checks, body photos) to minimize cloud exposure of biometric imagery.

---

## 7. Apple Health & Wearable Integrations

- **Apple Health / Google Health Connect:** two-way sync as the default aggregation layer for users who want to keep other apps too — Vitalis reads everything HealthKit exposes and writes back cleaned, unified data.
- **Wearables:** Apple Watch, Oura, WHOOP, Garmin, Fitbit, Polar, smart rings/rings-adjacent, smart scales (Withings, Renpho), CGMs (Dexcom, Abbott Libre, Levels), smart trainers/power meters, sleep-tracking mattresses (Eight Sleep).
- **Design principle:** Vitalis is *device-agnostic* — it never requires a proprietary wearable; it becomes more capable with better sensors but is fully functional with just a phone.

---

## 8. Third-Party Integrations

Pharmacy/prescription APIs, lab providers (Quest, LabCorp direct import), EHR interoperability (FHIR/SMART-on-FHIR for hospital record import), telehealth platforms, grocery delivery (Instacart/Amazon Fresh) for auto-cart generation, calendar (Google/Outlook/Apple), genetic testing providers (23andMe, Nebula), insurance wellness program APIs, air quality/pollen data providers, restaurant menu databases.

---

## 9. Premium Features & Monetization

- **Free tier:** core logging, basic readiness score, limited AI coach queries/day, standard integrations.
- **Vitalis+ (subscription):** full AI coach, unlimited generative meal/workout planning, biological age + longevity score, advanced lab-trend analysis, family plan, travel mode, priority CGM/genetic integration.
- **Vitalis Care (higher tier / B2B2C):** clinician-share portal, telehealth bundling, insurance-partnership discounts tied to verified activity.
- **Marketplace:** vetted coaches/dietitians/therapists offering paid programs inside the ecosystem (Vitalis takes a platform fee).
- **B2B:** employer wellness programs, insurer partnerships (premium discounts for verified healthy behavior, opt-in and privacy-first), research partnerships (opt-in anonymized data contribution with direct compensation to users).
- **Never:** selling raw personal health data to advertisers — this must be an explicit, marketed trust commitment, since it is the single biggest adoption barrier for a product this comprehensive.

---

## 10. Accessibility

Full VoiceOver/TalkBack support, voice-first logging for motor-impairment users, large-text and high-contrast modes, color-blind-safe data visualizations, multi-language support with locally-relevant food databases, cognitive-accessibility mode (simplified UI, fewer choices, larger touch targets) for elderly or cognitively-impaired users, caregiver-proxy mode for users who cannot self-log.

---

## 11. Privacy & Security

- End-to-end encryption for medical records and lab results; biometric data encrypted at rest and in transit.
- Granular, per-category sharing permissions (a user can share workout data with friends but keep labs completely private, by default).
- On-device processing for sensitive computer vision (progress photos, form checks) wherever feasible.
- Clear, auditable data-export and full-deletion rights (portability by design, not just compliance).
- Explicit opt-in (never default-on) for any research data sharing, insurance integration, or third-party data use.
- Regulatory posture: architected to meet HIPAA-adjacent standards even though a consumer wellness app may not be strictly required to, since medical-record storage and clinician-sharing features raise the bar.

---

## 12. Future Roadmap (5–10 Year Horizon)

- **Year 1–2:** Core unification (nutrition + training + recovery + sleep + mood) with best-in-class logging speed and the Readiness Engine as the product's spine.
- **Year 2–3:** AI Coach with action-taking capability, generative meal/workout planning, medical records + lab intelligence, cycle/life-stage depth.
- **Year 3–5:** Biological age/longevity score, genetic integration, environmental health layer, family constellation, injury-prevention and burnout-prediction engines maturing on larger longitudinal datasets.
- **Year 5–7:** Deeper clinical integration (EHR interoperability, insurer partnerships, telehealth-native visit prep), multi-omic integration (continuous biomarker sensing as at-home diagnostics mature).
- **Year 7–10:** Ambient sensing (bathroom/mirror-based vitals, continuous non-invasive glucose and blood-pressure sensing becoming mainstream), fully proactive health management where the app increasingly *prevents* problems it currently only detects, and a mature clinician-facing companion product that turns Vitalis into shared infrastructure between patients and care teams rather than a purely consumer app.

---

*This document is intentionally structured so any individual numbered section (1.1, 2, 5, 9, etc.) can be lifted independently as a prompt or brief for a designer, engineer, or investor conversation.*
