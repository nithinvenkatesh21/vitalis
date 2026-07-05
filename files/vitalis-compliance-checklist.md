# Vitalis — Compliance & App Store Review Checklist
### Companion to the ECC Master Build Prompt

> This is a practical checklist, not legal advice. Anything marked "confirm with counsel" should genuinely go to a lawyer before launch — health apps sit in a higher-scrutiny category with Apple and with regulators, and this document cannot substitute for real legal review.

---

## 1. Apple App Store Review — Health App Requirements

- [ ] App does not gate core, non-health functionality behind a HealthKit permission grant (Apple explicitly reviews for this).
- [ ] HealthKit usage strings (`NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`) clearly and specifically explain why each data type is requested — generic boilerplate text is a common rejection reason.
- [ ] App does not use HealthKit data for advertising or marketing purposes (explicitly prohibited by Apple's HealthKit terms).
- [ ] Any AI-generated health content (Vital's responses, deficiency predictions, risk scores) includes a visible, non-dismissible-on-first-view disclaimer that it is not medical advice.
- [ ] No feature claims to "diagnose," "treat," "cure," or "prevent" a specific disease — this both risks App Store rejection and crosses into regulated medical-device territory (FDA, in the US).
- [ ] If any feature could be construed as a Software as a Medical Device (SaMD) — e.g., ECG interpretation, risk scoring — confirm with counsel whether FDA clearance pathways (e.g., 510(k) or De Novo) apply before shipping that specific feature to production, even if built on top of Apple's own already-cleared ECG data.
- [ ] Privacy Nutrition Label (App Store Connect) accurately reflects every data type collected, including third-party SDKs (analytics, crash reporting) — this is checked in review and is a frequent source of rejection when it drifts from actual behavior.
- [ ] In-app purchase/subscription terms clearly disclosed before purchase (standard StoreKit review requirement, elevated scrutiny for health-adjacent subscriptions).
- [ ] If offering any insurance-linked discount or B2B wellness-program integration, clearly disclose what data is shared with that third party and require separate explicit opt-in (Apple review + regulatory risk both apply here).

## 2. HealthKit-Specific Requirements

- [ ] Read and write access requested separately per data type, only at the point of feature need (progressive permissioning — also referenced in ECC Master Prompt §15).
- [ ] App handles a user later revoking HealthKit access from iOS Settings without crashing or showing stale data as current.
- [ ] Any HealthKit data written back by Vitalis (workouts, water, mindful minutes) is accurately typed and attributed, since other apps and Apple Health itself will display it.
- [ ] Clinical Health Records (FHIR) data, if used, is handled with the same or greater care as self-reported lab data — this is sourced from real medical institutions and carries higher sensitivity.

## 3. Data Privacy & Regulatory (Confirm With Counsel Before Launch)

- [ ] **HIPAA:** Vitalis as a direct-to-consumer app is likely not a "covered entity," but any B2B/clinician-sharing or insurance-integration feature may create Business Associate obligations — confirm with counsel before launching the Care/clinician tier described in the Product Spec §9.
- [ ] **State health-data privacy laws** (e.g., Washington's My Health My Data Act, and similar emerging state laws) may apply regardless of HIPAA status and often have private right-of-action risk — confirm scope with counsel, especially around consent language and "geofencing"-style restrictions on sensitive location data (e.g., reproductive health).
- [ ] **GDPR/UK GDPR** (if launching in EU/UK): health data is a "special category" requiring explicit consent, a documented lawful basis, and full data-subject rights (access, deletion, portability) — the "explicit opt-in for research/third-party sharing" and full data-export/deletion features in the ECC Master Prompt §23 are necessary but should be reviewed against the specific jurisdiction's requirements before launch.
- [ ] **COPPA** (if any family/child profile under 13 is supported): additional parental-consent and data-minimization requirements apply — confirm scope with counsel before enabling child profiles.
- [ ] **Genetic data** (23andMe/Nebula integration): several US states have specific genetic-privacy statutes with their own consent and deletion requirements, separate from general health-data rules — confirm before shipping this integration.
- [ ] **Reproductive health data** (cycle/fertility/pregnancy tracking): treat as maximally sensitive by default — on-device-first storage where feasible, no default sharing with anyone (including Family group) without separate explicit consent, and be aware of state-level legal exposure in this specific category post-*Dobbs* in the US — confirm current state with counsel given this is an evolving area.

## 4. Third-Party Data Sources & Licensing

- [ ] Food/nutrition database (whatever provider is chosen) — confirm licensing terms permit the intended commercial use and confirm accuracy/liability terms.
- [ ] Drug interaction database — confirm the source is a licensed, maintained clinical database (e.g., a recognized drug-interaction API), not a scraped or unmaintained dataset, given the safety stakes of getting this wrong.
- [ ] Any AI model provider (LLM API, CoreML model sources) — confirm data-handling terms, especially whether user health data sent to a third-party model provider is used for that provider's own model training (should be contractually excluded).

## 5. Marketing & In-App Language

- [ ] No use of words like "diagnose," "cure," "treatment" in marketing copy or in-app microcopy.
- [ ] Longevity Score / Biological Age feature explicitly labeled as an estimate for engagement/motivation purposes, not a clinical biomarker — avoid language implying clinical validation unless it has actually been clinically validated.
- [ ] Any health-risk prediction feature uses hedged, pattern-level language ("your data shows a pattern associated with X — discuss with a clinician") never definitive claims.

## 6. Crisis & Sensitive-Content Handling (applies to Vital + Mind module)

- [ ] Self-harm/suicidal-ideation input triggers a supportive response plus crisis resources (e.g., 988 in the US), never a dismissal or an attempt to solve it via a feature/tool call.
- [ ] Disordered-eating signals (extreme restriction patterns, compensatory behavior logged in Nutrition/Symptom modules) do not trigger precise calorie/macro guidance from Vital or from the meal-planning AI — this is a specific safety rule, not just a general caution, and should be implemented as a hard rule in the Coach Service, not left to model judgment alone.
- [ ] No diagnostic labeling of the user's mental state anywhere in the app's copy or AI responses, even conversationally.

## 7. Pre-Launch Sign-Off

- [ ] Legal review completed for Sections 3–4 above, specific to launch jurisdictions.
- [ ] Security audit / penetration test completed on backend API and data-export/deletion flows.
- [ ] App Store Connect Privacy Nutrition Label reviewed against actual final data collection (re-check after any late feature changes — this is a common last-mile rejection cause).
- [ ] Medical/clinical advisor (if available) has reviewed all disease-risk, deficiency-prediction, and lab-interpretation copy for appropriate hedging language.
