# Continual Update Evaluation Report

## Scope
This report evaluates a continual-update workflow in which dose and time-to-stability models are repeatedly retrained as new shifted patient batches arrive.

## Experimental Design
- Historical starting dataset: `/home/karthick_js/Documents/programs/vitalink_ip_lab/ml_pipeline/warfarin_pipeline/data/warfarin_cohort.csv`
- Incoming data: three shifted synthetic batches of 300 patients each
- Future evaluation cohort: one fixed shifted synthetic batch of 600 patients
- Update strategy: cumulative batch retraining from scratch after each incoming batch
- Model family: XGBoost with the repository preprocessing stack

## Round-by-Round Metrics

| round | train_size | dose_rmse | dose_mae | dose_r2 | dose_within_20_pct | stability_rmse | stability_mae | stability_r2 | stability_within_7_days_pct |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Initial | 2500 | 12.0849 | 9.7378 | 0.2389 | 32.1667 | 7.6047 | 6.1413 | -0.4777 | 61.6667 |
| Update 1 | 2800 | 12.2372 | 9.8028 | 0.2196 | 30.6667 | 5.8745 | 4.7051 | 0.1182 | 77.8333 |
| Update 2 | 3100 | 12.9769 | 10.4062 | 0.1224 | 32.8333 | 5.9608 | 4.7556 | 0.0921 | 76.0000 |
| Update 3 | 3400 | 12.7637 | 10.2223 | 0.1510 | 32.8333 | 5.9044 | 4.7114 | 0.1092 | 76.5000 |

## Main Findings
- Dose model RMSE improved from `12.08` to `12.76` mg/week, while within-20% accuracy moved from `32.2%` to `32.8%`.
- Stability model RMSE improved from `7.60` to `5.90` days, while within-7-days accuracy moved from `61.7%` to `76.5%`.
- The experiment uses simulated covariate shift, so the interpretation is: continual retraining helps models adapt when the arriving patient mix differs from the original training cohort.

## Artifacts
- Metrics CSV: `/home/karthick_js/Documents/programs/vitalink_ip_lab/ml_pipeline/warfarin_pipeline/evaluation/output/continual_update_metrics.csv`
- Summary JSON: `/home/karthick_js/Documents/programs/vitalink_ip_lab/ml_pipeline/warfarin_pipeline/evaluation/output/continual_update_summary.json`
- Performance plot: `/home/karthick_js/Documents/programs/vitalink_ip_lab/ml_pipeline/warfarin_pipeline/evaluation/output/continual_update_performance.png`
- Shift plot: `/home/karthick_js/Documents/programs/vitalink_ip_lab/ml_pipeline/warfarin_pipeline/evaluation/output/continual_update_shift.png`
- Scatter plot: `/home/karthick_js/Documents/programs/vitalink_ip_lab/ml_pipeline/warfarin_pipeline/evaluation/output/continual_update_scatter.png`
- Final dose model: `/home/karthick_js/Documents/programs/vitalink_ip_lab/ml_pipeline/warfarin_pipeline/evaluation/models/continual_dose_model_final.joblib`
- Final stability model: `/home/karthick_js/Documents/programs/vitalink_ip_lab/ml_pipeline/warfarin_pipeline/evaluation/models/continual_stability_model_final.joblib`
