# Warfarin Dose Modeling Report

## Executive Summary
This repository predicts weekly warfarin dose from clinical and pharmacogenetic features derived from the IWPC dataset. The original comparison pipeline evaluated linear, tree-based, and neural-network regressors with mostly fixed hyperparameters. The tuning workflow has now been upgraded to use Optuna for guided hyperparameter search on XGBoost and LightGBM, with the final comparison written back into repository docs and artifacts.

The practical outcome is simple:

- The earlier tuning path based on `RandomizedSearchCV` has been replaced by Optuna.
- Optuna found a materially better LightGBM configuration.
- The tuned LightGBM model is now the best model on the held-out test set, narrowly outperforming the Ridge pharmacogenetic baseline.

## Data and Features
The tuning pipeline uses `ml_pipeline/data/iwpc_warfarin.xls` and predicts `Therapeutic Dose of Warfarin`.

Features used in the pharmacogenetic models:

- Numeric: `Age_Num`, `Height (cm)`, `Weight (kg)`, `Amiodarone`, `Enzyme_Inducer`
- Categorical/genetic: `Race_Group`, `CYP2C9`, `VKORC1`

Preprocessing steps:

- Age bands are converted to numeric decade midpoints.
- Race labels are normalized into `White`, `Black`, `Asian`, and `Other/Unknown`.
- Medication indicators are coerced to numeric and missing values default to `0.0`.
- Enzyme inducers are collapsed into a single binary-like maximum feature.
- Rare CYP2C9 variants are grouped into `Other/Unknown`.
- Numeric features use `KNNImputer` plus `StandardScaler`.
- Categorical features use constant imputation plus `OneHotEncoder`.

## Training and Evaluation Setup
All numbers below come from the current Optuna tuning script:

- Script: `ml_pipeline/tune_warfarin_models.py`
- Train/test split: 80/20
- Split seed: `42`
- Tuning method: Optuna TPE sampler
- Trials: `25` per model
- Tuning objective: 3-fold cross-validated RMSE

Evaluation metrics:

- `R2`
- `RMSE`
- `MAE`
- Percentage of patients predicted within 20% of the actual dose

## Before and After Improvement
The repository now has a direct before/after comparison for the tree-based models.

| Model | Stage | R2 | RMSE | MAE | Within 20% |
| --- | --- | ---: | ---: | ---: | ---: |
| Ridge pharmacogenetic baseline | Existing baseline | 0.4190 | 11.92 | 8.74 | 41.41% |
| XGBoost | Default parameters | 0.3827 | 12.29 | 8.87 | 42.13% |
| XGBoost | Optuna tuned | 0.3831 | 12.29 | 8.86 | 41.05% |
| LightGBM | Default parameters | 0.4016 | 12.10 | 8.84 | 41.68% |
| LightGBM | Optuna tuned | 0.4208 | 11.90 | 8.71 | 42.13% |

## What Improved
### LightGBM
Optuna improved LightGBM from:

- `R2`: `0.4016` to `0.4208`
- `RMSE`: `12.10` to `11.90`
- `MAE`: `8.84` to `8.71`
- `Within 20%`: `41.68%` to `42.13%`

This is the clearest gain from the tuning upgrade. The tuned LightGBM now edges out the Ridge baseline on all primary error metrics except that both remain very close in overall behavior.

### XGBoost
Optuna changed XGBoost only marginally:

- `R2`: `0.3827` to `0.3831`
- `RMSE`: `12.29` to `12.29`
- `MAE`: `8.87` to `8.86`
- `Within 20%`: `42.13%` to `41.05%`

The conclusion here is important: Optuna was worth applying, but not every model benefits equally. For this feature set and dataset size, XGBoost appears relatively insensitive to the explored hyperparameter range.

## Why Optuna Is Better Than the Previous Tuning Approach
The earlier script used `RandomizedSearchCV` over a fixed parameter grid. That approach works, but it wastes trials on less promising regions and treats every trial independently.

The new Optuna workflow improves that in three ways:

1. It uses adaptive search through the TPE sampler, so later trials are informed by earlier results.
2. It optimizes against cross-validated RMSE instead of a single arbitrary train/validation split inside the tuner.
3. It persists a machine-readable summary and a markdown report, making the improvement auditable.

## Current Best Model
The best model currently produced by the repository is:

- `Optuna-tuned LightGBM`
- `R2 = 0.4208`
- `RMSE = 11.90 mg/week`
- `MAE = 8.71 mg/week`
- `42.13%` of patients predicted within 20% of actual dose

This tuned model is saved to `ml_pipeline/models/best_warfarin_model.joblib`.

## Artifacts Added by the Improvement
The Optuna workflow now produces:

- `ml_pipeline/docs/optuna_tuning_report.md`
- `ml_pipeline/output/optuna_tuning_summary.json`
- Updated `ml_pipeline/models/best_warfarin_model.joblib`

## Recommended Next Steps
- If prediction serving should use the tuned best model, update any inference path that still assumes the old baseline XGBoost artifact pair (`warfarin_model.json` plus `preprocessor.joblib`).
- If you want more stable leaderboard comparisons, add repeated cross-validation or nested cross-validation for the final report.
- If clinical interpretability is the main goal, keep Ridge as a deployment candidate even though LightGBM is now slightly better numerically.
