import os
import pandas as pd
import numpy as np
import xgboost as xgb
import joblib
import optuna
from sklearn.model_selection import train_test_split
from sklearn.metrics import r2_score, mean_squared_error, mean_absolute_error
from preprocess import get_preprocessor, get_feature_names

def train_xgboost_baseline(data_path="data/warfarin_cohort.csv"):
    df = pd.read_csv(data_path)
    print(f"Loaded {len(df)} patients for baseline training.")
    
    X = df.drop(columns=['WarfarinDose', 'Days_To_Stable'], errors='ignore')
    y = df['WarfarinDose']
    
    # 80/20 train/test split like the R code
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=123)
    
    # Preprocessing
    preprocessor, num_f, cat_f = get_preprocessor()
    X_train_processed = preprocessor.fit_transform(X_train)
    X_test_processed = preprocessor.transform(X_test)
    
    feature_names = get_feature_names(preprocessor, num_f, cat_f)
    print(f"Training on {X_train_processed.shape[0]} samples, {X_train_processed.shape[1]} features.")
    
    def objective(trial):
        # We split current train set internally for optuna validation to prevent data leakage from test set
        X_t, X_v, y_t, y_v = train_test_split(X_train_processed, y_train, test_size=0.2, random_state=42)
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
        
        # Don't use early stopping in optuna internally for speed unless epochs are huge
        m = xgb.XGBRegressor(**params)
        m.fit(X_t, y_t, eval_set=[(X_v, y_v)], verbose=False)
        return np.sqrt(mean_squared_error(y_v, m.predict(X_v)))

    print("Running Optuna study for max 30 trials...")
    optuna.logging.set_verbosity(optuna.logging.WARNING)
    study = optuna.create_study(direction='minimize', sampler=optuna.samplers.TPESampler(seed=123))
    study.optimize(objective, n_trials=30)
    
    best_params = study.best_params
    best_params['objective'] = 'reg:squarederror'
    best_params['random_state'] = 123
    best_params['n_jobs'] = -1
    
    print("Found best hyperparameters!")
    for k, v in best_params.items():
        if k not in ['objective', 'random_state', 'n_jobs']:
            print(f"  {k}: {v}")
    
    print("\nTraining final XGBoost model with best params...")
    model = xgb.XGBRegressor(**best_params)
    
    model.fit(
        X_train_processed, y_train,
        eval_set=[(X_train_processed, y_train), (X_test_processed, y_test)],
        verbose=False
    )
    
    # Predict and evaluate
    predictions = model.predict(X_test_processed)
    
    r2 = r2_score(y_test, predictions)
    rmse = np.sqrt(mean_squared_error(y_test, predictions))
    mae = mean_absolute_error(y_test, predictions)
    within_20pct = np.mean(np.abs(y_test - predictions) <= 0.2 * y_test) * 100
    
    print("-" * 50)
    print("EVALUATION METRICS")
    print("-" * 50)
    print(f"R2:\t\t{r2:.4f}")
    print(f"RMSE:\t\t{rmse:.2f} mg/week")
    print(f"MAE:\t\t{mae:.2f} mg/week")
    print(f"Within 20%:\t{within_20pct:.1f}%")
    
    # Save model and preprocessor for future streaming inferences or retrains
    os.makedirs("models", exist_ok=True)
    # XGBoost prefers saving using its own method for continuous training (saving booster state in JSON)
    model.get_booster().save_model("models/warfarin_model.json")
    joblib.dump(preprocessor, "models/preprocessor.joblib")
    
    # Save the test data for visualizations
    np.save("data/y_test_baseline.npy", y_test)
    np.save("data/y_pred_baseline.npy", predictions)
    
    # Calculate feature importances based on Gain
    feature_importances = model.feature_importances_
    # Ensure feature_names matches length
    if len(feature_names) == len(feature_importances):
        importance_df = pd.DataFrame({
            'Feature': feature_names,
            'Gain': feature_importances
        }).sort_values('Gain', ascending=False)
        importance_df.to_csv("data/feature_importances.csv", index=False)
    
    print("\nSaved model files to models/ directory.")
    print("Saved test predictions and importances to data/ directory.")
    
    return model, r2, rmse, mae, within_20pct

if __name__ == "__main__":
    train_xgboost_baseline()
