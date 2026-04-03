# Acitrom (Acenocoumarol) Pipeline Plan

## 1) Goal and Scope

Build an Acitrom-specific dosing ML pipeline (not warfarin) with two outputs:

1. **Maintenance dose model**: predict stable weekly acenocoumarol dose (mg/week).
2. **Time-aware control model**: predict next-visit INR and time-to-stability using longitudinal INR+dose history.

This document is process-first. Coding starts after this plan is approved.

## 2) Why Acitrom Needs Its Own Pipeline

- Acenocoumarol and warfarin are related but not interchangeable; effect-size of predictors differs by drug and population.
- Literature shows acenocoumarol algorithms are often population-specific and should be locally recalibrated.
- Public calculators are limited and not consistently available; we should benchmark against published formulas and local baselines.

## 3) Data Build Strategy

### 3.1 Cohort Definition

- Include adults started on acenocoumarol with documented follow-up INR.
- Keep index date = first acenocoumarol prescription.
- Include major indications (AF, VTE, valve disease), but store indication explicitly for stratified analysis.
- Exclude records with impossible dose units, missing date order, or no INR trajectory.

### 3.2 Required Data Fields

**Patient/static features**
- age, sex, weight, height, BMI
- indication and target INR range
- renal and liver status where available
- concomitant interacting drugs (amiodarone, enzyme inducers/inhibitors)
- smoking/adherence proxies if available
- genotype fields when available: `CYP2C9`, `VKORC1`, `CYP4F2`, optional `APOE`

**Longitudinal features**
- timestamped dose administration (daily or weekly aggregation)
- timestamped INR values
- dose adjustment events
- visit intervals

**Derived features**
- lag INR (`INR_t-1`, `INR_t-2`), lag dose (`Dose_t-1`, `Dose_t-2`)
- delta INR, delta dose
- rolling TTR proxy window features
- days since initiation

### 3.3 Dataset Tables (recommended)

- `patients.csv`: one row per patient (static features).
- `visits.csv`: one row per INR visit (`patient_id`, date, INR, dose since last visit).
- `episodes.csv`: modeling windows with lag features and targets.

### 3.4 Primary Targets

1. `stable_weekly_dose_mg`
	- Definition: weekly dose at stable anticoagulation segment (protocolized definition needed, e.g., sustained INR in target for N visits).
2. `next_inr`
	- Next measured INR from current state.
3. `time_to_stable_days`
	- Days from initiation to first stable segment.

## 4) Baselines and Benchmarks

### 4.1 Internal Baselines

- Clinical linear model (no genotype).
- Pharmacogenetic linear model (clinical + genotype).
- Tree baselines: RandomForest, XGBoost, LightGBM.

### 4.2 External Comparators

- Re-implement published acenocoumarol equations from papers as deterministic benchmark functions.
- If a public calculator endpoint is available, treat it as optional comparator only.

Known public reference mentioned in literature:
- `http://www.dosisacenocumarol.com/en/index.php`

Note: direct automated retrieval may fail; availability is not guaranteed. Therefore, published equation re-implementation is mandatory for reproducible benchmarking.

## 5) Time-Aware Modeling Plan

### 5.1 Problem Framing

- Supervised sequence/regression from current state to `next_inr`.
- Survival/regression framing for `time_to_stable_days`.

### 5.2 Model Families

Phase 1 (fast, robust):
- Gradient boosting on engineered lag features.
- Regularized linear model on lag+clinical+genetic features.

Phase 2 (if data volume supports):
- Sequence model (GRU/LSTM/Temporal Convolution) on visit-level trajectories.

### 5.3 Validation Design

- Split by patient (never by row).
- Prefer temporal validation: older initiations train, newer initiations test.
- Report subgroup performance (low-dose/high-dose extremes, genotype strata, indication strata).

## 6) Metrics and Reporting

### 6.1 Maintenance Dose

- MAE (mg/week), RMSE, $R^2$
- percent within ±20% of observed stable dose
- low/intermediate/high dose group performance

### 6.2 Next INR / Time-to-Stability

- Next INR: MAE, RMSE, calibration-by-bin
- Time-to-stability: MAE (days), concordance index (if survival framing)

### 6.3 Explainability

- SHAP summary and top features for each model family
- partial dependence/ICE on major clinical covariates
- explicit checks that dose recommendations are monotonic where clinically expected

## 7) Safety and Clinical Guardrails (for Deployment)

- Hard cap on per-adjustment dose change (% and absolute mg/week).
- Alert thresholds for predicted INR risk zones.
- Mandatory clinician approval (no autonomous prescribing).
- Full audit log: input features, model version, recommendation, override reason.
- Silent-mode prospective validation before any active decision support.

## 8) Execution Phases

### Phase A — Data
1. Build extraction spec and field dictionary.
2. Create `patients/visits/episodes` datasets.
3. Run data quality checks and cohort report.

### Phase B — Modeling
1. Implement internal baselines.
2. Implement published-equation acenocoumarol comparators.
3. Train time-aware models.
4. Produce leaderboard and subgroup report.

### Phase C — Validation and Packaging
1. Add calibration + explainability reports.
2. Add guardrail simulation on historical cases.
3. Prepare inference contract and model cards.

## 9) Immediate Next Coding Tasks (after approval)

1. Create `acitrom_pipeline/data_schema.md` with exact column contract.
2. Add `build_acitrom_dataset.py` (cohort + longitudinal episodes).
3. Add `benchmarks_acitrom.py` (published formula implementations).
4. Add `train_acitrom_maintenance.py`.
5. Add `train_acitrom_timeaware.py`.
6. Add `evaluate_acitrom.py` + report exporters.

## 10) Evidence Anchors Used for This Plan

- Spanish acenocoumarol PGx algorithm paper (variables, endpoints, dose-group analysis):
  - https://pmc.ncbi.nlm.nih.gov/articles/PMC3401172/
- North Indian population-specific acenocoumarol algorithm (population transferability signal):
  - https://pubmed.ncbi.nlm.nih.gov/22629463/
- Additional acenocoumarol algorithm/trial lineage cited within the Spanish paper references (EU-PACT/IWPC context and related methods).
