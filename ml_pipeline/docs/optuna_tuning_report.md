# Optuna Hyperparameter Tuning Report

## Overview
This report compares the tree-based warfarin dose models before and after switching to Optuna-based hyperparameter optimization. All metrics below were computed on the same held-out 20% test split using the IWPC dataset.

## Experimental Setup
- Dataset: `iwpc_warfarin.xls`
- Test split: 20% with `random_state=42`
- Cross-validation during tuning: 3-fold KFold with shuffling
- Optimization engine: Optuna TPE sampler, 25 trials per model
- Optimization target: cross-validated RMSE
- Common preprocessing: KNN imputation + scaling for numeric fields, constant imputation + one-hot encoding for categorical/genetic fields

## Before vs After

| Model | Stage | R2 | RMSE | MAE | Within 20% |
| --- | --- | ---: | ---: | ---: | ---: |
| Ridge pharmacogenetic baseline | Existing baseline | 0.4190 | 11.92 | 8.74 | 41.41% |
| XGBoost | Default parameters | 0.3827 | 12.29 | 8.87 | 42.13% |
| XGBoost | Optuna tuned | 0.3831 | 12.29 | 8.86 | 41.05% |
| LightGBM | Default parameters | 0.4016 | 12.10 | 8.84 | 41.68% |
| LightGBM | Optuna tuned | 0.4208 | 11.90 | 8.71 | 42.13% |

## Improvement Summary
- XGBoost improvement: Delta R2 = +0.0004, Delta RMSE = -0.00, Delta MAE = -0.01, Delta Within 20% = -1.08 points
- LightGBM improvement: Delta R2 = +0.0192, Delta RMSE = -0.20, Delta MAE = -0.13, Delta Within 20% = +0.45 points
- Best overall model on the held-out test set: **Optuna-tuned LightGBM** with R2=0.4208, RMSE=11.90, MAE=8.71, Within20=42.13%

## Best Optuna Parameters

### XGBoost
```json
{
  "colsample_bytree": 0.6997735240645564,
  "gamma": 4.266370741608514e-06,
  "learning_rate": 0.030228166354651025,
  "max_depth": 3,
  "min_child_weight": 3,
  "n_estimators": 391,
  "reg_alpha": 1.1291217680012138e-08,
  "reg_lambda": 0.2203752223673274,
  "subsample": 0.8975129119153289
}
```

### LightGBM
```json
{
  "colsample_bytree": 0.6528296744060249,
  "learning_rate": 0.018218827946353038,
  "max_depth": 3,
  "min_child_samples": 20,
  "n_estimators": 445,
  "num_leaves": 38,
  "reg_alpha": 0.005545639941752229,
  "reg_lambda": 0.07097419523880641,
  "subsample": 0.8425019015541142
}
```

## Interpretation
- Optuna replaced the earlier random search with sequential model-based optimization, which searches promising regions of the hyperparameter space more efficiently.
- The tuning objective focused on cross-validated RMSE instead of a single validation draw, which reduces the chance of selecting a brittle parameter set.
- The final winner should still be interpreted in the context of clinical safety and model simplicity. If the Ridge baseline remains competitive or better, that is a meaningful result rather than a failure of tuning.

## Output Artifacts
- Tuned summary JSON: `output/optuna_tuning_summary.json`
- Best persisted model: `models/best_warfarin_model.joblib`
