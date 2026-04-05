# Warfarin Model Comparison Report

## Scope
This report compares the repository model against the requested baseline machine-learning regressors and the IWPC dosing baselines derived from the official IWPC Excel calculator workbook.

## Data and Evaluation Setup
- Dataset: `/home/karthick_js/Documents/programs/vitalink_ip_lab/ml_pipeline/warfarin_pipeline/data/iwpc_warfarin.xls` (`Subject Data` sheet)
- IWPC calculator workbook referenced: `/home/karthick_js/Documents/programs/vitalink_ip_lab/ml_pipeline/warfarin_pipeline/data/iwpc_warfarin.xls`
- Test split: 20% holdout with `random_state=42`
- Shared features: age in decades, height, weight, race, amiodarone, enzyme inducer, CYP2C9, VKORC1
- Numeric missing values for the closed-form IWPC formulas were imputed from training-set medians; categorical missingness was mapped to the calculator's `Unknown` categories
- Metrics: RMSE, MAE, R², and percentage of patients predicted within 20% of the true weekly dose

## IWPC Formula Sources
- Pharmacogenetic dosing algorithm: IWPC supplementary appendix section S1e
- Clinical dosing algorithm: IWPC supplementary appendix section S1f
- Reference PDF: https://stanford.edu/class/gene210/files/readings/IWPC_NEJM_Supplement.pdf

## Result Table

| rank | model | rmse | mae | r2 | within_20_pct |
| --- | --- | --- | --- | --- | --- |
| 1 | LightGBM | 11.8967 | 8.7220 | 0.4216 | 41.9530 |
| 2 | Linear Regression | 11.9207 | 8.7386 | 0.4193 | 42.3146 |
| 3 | IWPC Pharmacogenetic Calculator | 12.0332 | 8.6777 | 0.4082 | 41.8626 |
| 4 | XGBoost | 12.2965 | 8.8763 | 0.3821 | 41.4105 |
| 5 | Random Forest | 13.0880 | 9.5646 | 0.2999 | 40.3255 |
| 6 | IWPC Clinical Formula | 13.8728 | 10.3894 | 0.2135 | 33.6347 |

## Main Findings
- Best overall model on this split: **LightGBM** with RMSE `11.90` mg/week, MAE `8.72` mg/week, R² `0.422`, and `42.0%` within 20% of actual dose.
- Against the **IWPC Pharmacogenetic Calculator**, the best model reduced RMSE by `0.14` mg/week, trailed on MAE by `0.04` mg/week, and gained `0.1` points on within-20% accuracy.
- The **IWPC Clinical Formula** scored RMSE `13.87` mg/week and MAE `10.39` mg/week, showing the expected gap between a clinical-only rule and the stronger genotype-aware models.

## Visual Artifacts
- Model comparison dashboard: `/home/karthick_js/Documents/programs/vitalink_ip_lab/ml_pipeline/warfarin_pipeline/evaluation/output/iwpc_model_comparison.png`
- Prediction scatter comparison: `/home/karthick_js/Documents/programs/vitalink_ip_lab/ml_pipeline/warfarin_pipeline/evaluation/output/iwpc_prediction_scatter.png`
- SHAP summary bar chart: `/home/karthick_js/Documents/programs/vitalink_ip_lab/ml_pipeline/warfarin_pipeline/evaluation/output/iwpc_shap_bar.png`
- SHAP beeswarm chart: `/home/karthick_js/Documents/programs/vitalink_ip_lab/ml_pipeline/warfarin_pipeline/evaluation/output/iwpc_shap_beeswarm.png`

## SHAP Explainability Highlights
Top global drivers for the best model:

| feature | mean_abs_shap |
| --- | --- |
| VKORC1_A/A | 4.2794 |
| VKORC1_G/G | 3.1458 |
| Weight (kg) | 3.0719 |
| Age_Num | 2.9143 |
| CYP2C9_*1/*1 | 1.8390 |
| Height (cm) | 0.9990 |
| Amiodarone | 0.5904 |
| CYP2C9_*1/*3 | 0.3032 |
| VKORC1_Unknown | 0.2731 |
| Race_Group_White | 0.2505 |

## Generated Files
- Metrics CSV: `/home/karthick_js/Documents/programs/vitalink_ip_lab/ml_pipeline/warfarin_pipeline/evaluation/output/iwpc_model_metrics.csv`
- Summary JSON: `/home/karthick_js/Documents/programs/vitalink_ip_lab/ml_pipeline/warfarin_pipeline/evaluation/output/iwpc_comparison_summary.json`
- SHAP importance CSV: `/home/karthick_js/Documents/programs/vitalink_ip_lab/ml_pipeline/warfarin_pipeline/evaluation/output/iwpc_shap_top_features.csv`
- Best comparison model artifact: `/home/karthick_js/Documents/programs/vitalink_ip_lab/ml_pipeline/warfarin_pipeline/evaluation/models/iwpc_best_comparison_model.joblib`
