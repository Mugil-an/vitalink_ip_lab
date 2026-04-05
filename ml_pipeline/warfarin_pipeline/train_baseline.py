import os
import pandas as pd
import numpy as np
import xgboost as xgb
import joblib
import optuna
from sklearn.model_selection import train_test_split
from sklearn.metrics import r2_score, mean_squared_error, mean_absolute_error
from sklearn.base import clone
import warnings

from preprocessing import (
    create_preprocessor,
    get_feature_names_from_preprocessor,
    load_dataframe,
    prepare_warfarin_dose_dataset,
)

warnings.filterwarnings('ignore')

def preprocess_data(df):
    """Preprocess dataframe using shared schema-aware preprocessing."""
    print("2. Preprocessing Data...")

    X, y, num_features, cat_features_clinical, cat_features_genetic, _ = prepare_warfarin_dose_dataset(df)
    cat_features = cat_features_clinical + cat_features_genetic
    preprocessor = create_preprocessor(num_features, cat_features)

    return X, y, preprocessor, num_features, cat_features

def train_xgboost_baseline(data_path="warfarin_pipeline/data/warfarin_cohort.csv"):
    df = load_dataframe(data_path)
    print(f"Loaded {len(df)} patients for baseline training.")
    
    X, y, preprocessor, num_features, cat_features = preprocess_data(df)
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=123)

    preprocessor = preprocessor.fit(X_train)
    X_train_processed = preprocessor.transform(X_train)
    X_test_processed = preprocessor.transform(X_test)

    feature_names = get_feature_names_from_preprocessor(preprocessor, num_features, cat_features)
    print(f"Training on {X_train_processed.shape[0]} samples, {X_train_processed.shape[1]} features.")
    
    def objective(trial):
        X_t, X_v, y_t, y_v = train_test_split(X_train, y_train, test_size=0.2, random_state=42)
        fold_preprocessor = clone(preprocessor)
        X_t_processed = fold_preprocessor.fit_transform(X_t)
        X_v_processed = fold_preprocessor.transform(X_v)

        params = {
            'objective': 'reg:squarederror',
            'max_depth': trial.suggest_int('max_depth', 3, 10),
            'learning_rate': trial.suggest_float('learning_rate', 0.01, 0.2, log=True),
            'n_estimators': trial.suggest_int('n_estimators', 50, 400),
            'min_child_weight': trial.suggest_int('min_child_weight', 1, 10),
            'gamma': trial.suggest_float('gamma', 1e-8, 1.0, log=True),
            'subsample': trial.suggest_float('subsample', 0.5, 1.0),
            'colsample_bytree': trial.suggest_float('colsample_bytree', 0.5, 1.0),
            'random_state': 123,
            'n_jobs': -1
        }
        
        m = xgb.XGBRegressor(**params)
        m.fit(X_t_processed, y_t, eval_set=[(X_v_processed, y_v)], verbose=False)
        return np.sqrt(mean_squared_error(y_v, m.predict(X_v_processed)))

    print("\n3. Running Optuna hyperparameter tuning (30 trials)...")
    optuna.logging.set_verbosity(optuna.logging.WARNING)
    study = optuna.create_study(direction='minimize', sampler=optuna.samplers.TPESampler(seed=123))
    study.optimize(objective, n_trials=30)
    
    best_params = study.best_params
    best_params['objective'] = 'reg:squarederror'
    best_params['random_state'] = 123
    best_params['n_jobs'] = -1
    
    print("\n✓ Found best hyperparameters!")
    for k, v in best_params.items():
        if k not in ['objective', 'random_state', 'n_jobs']:
            print(f"  {k}: {v}")
    
    print("\n4. Training final XGBoost baseline model...")
    model = xgb.XGBRegressor(**best_params)
    
    model.fit(
        X_train_processed, y_train,
        eval_set=[(X_train_processed, y_train), (X_test_processed, y_test)],
        verbose=False
    )
    
    predictions = model.predict(X_test_processed)
    
    r2 = r2_score(y_test, predictions)
    rmse = np.sqrt(mean_squared_error(y_test, predictions))
    mae = mean_absolute_error(y_test, predictions)
    within_20pct = np.mean(np.abs(y_test - predictions) <= 0.2 * y_test) * 100
    
    print("\n" + "="*50)
    print("EVALUATION METRICS (Clinical Baseline)")
    print("="*50)
    print(f"R² Score:              {r2:.4f}")
    print(f"RMSE:                  {rmse:.2f} mg/week")
    print(f"MAE:                   {mae:.2f} mg/week")
    print(f"Patients within 20%:   {within_20pct:.1f}%")
    print("="*50)
    
    os.makedirs("warfarin_pipeline/models", exist_ok=True)
    os.makedirs("warfarin_pipeline/data", exist_ok=True)
    
    model.get_booster().save_model("warfarin_pipeline/models/warfarin_model.json")
    joblib.dump(preprocessor, "warfarin_pipeline/models/preprocessor.joblib")
    
    np.save("warfarin_pipeline/data/y_test_baseline.npy", y_test.values)
    np.save("warfarin_pipeline/data/y_pred_baseline.npy", predictions)
    
    feature_importances = model.feature_importances_
    if len(feature_names) == len(feature_importances):
        importance_df = pd.DataFrame({
            'Feature': feature_names,
            'Gain': feature_importances
        }).sort_values('Gain', ascending=False)
        importance_df.to_csv("warfarin_pipeline/data/feature_importances.csv", index=False)
        print("\nTop 10 Most Important Features:")
        print(importance_df.head(10).to_string(index=False))
    
    print("\n✓ Saved model to: models/warfarin_model.json")
    print("✓ Saved preprocessor to: models/preprocessor.joblib")
    print("✓ Saved predictions to: data/y_test_baseline.npy, data/y_pred_baseline.npy")
    print("✓ Saved feature importances to: data/feature_importances.csv")
    
    return model, r2, rmse, mae, within_20pct

if __name__ == "__main__":
    train_xgboost_baseline()
