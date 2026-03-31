import os
import pandas as pd
import numpy as np
import xgboost as xgb
import joblib
import optuna
from sklearn.model_selection import train_test_split
from sklearn.metrics import r2_score, mean_squared_error, mean_absolute_error
from preprocess import get_preprocessor

def train_time_to_stability(data_path="data/warfarin_cohort.csv"):
    df = pd.read_csv(data_path)
    print("--- Time-to-Stability Prediction Framework ---")
    print("WARNING: This model currently trains on dummy 'Days_To_Stable' target data.")
    print("Wait for real patient tracking data before relying on it.")
    
    X = df.drop(columns=['WarfarinDose', 'Days_To_Stable'], errors='ignore')
    y_time = df['Days_To_Stable']
    
    X_train, X_test, y_train, y_test = train_test_split(X, y_time, test_size=0.2, random_state=42)
    
    preprocessor, num_f, cat_f = get_preprocessor()
    X_train_processed = preprocessor.fit_transform(X_train)
    X_test_processed = preprocessor.transform(X_test)
    
    def objective(trial):
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
            'random_state': 42,
            'n_jobs': -1
        }
        
        m = xgb.XGBRegressor(**params)
        m.fit(X_t, y_t, eval_set=[(X_v, y_v)], verbose=False)
        return np.sqrt(mean_squared_error(y_v, m.predict(X_v)))

    print("Running Optuna study for max 30 trials on Time-to-Stability...")
    optuna.logging.set_verbosity(optuna.logging.WARNING)
    study = optuna.create_study(direction='minimize', sampler=optuna.samplers.TPESampler(seed=42))
    study.optimize(objective, n_trials=30)
    
    best_params = study.best_params
    best_params['objective'] = 'reg:squarederror'
    best_params['random_state'] = 42
    best_params['n_jobs'] = -1
    
    print("Found best hyperparameters!")
    for k, v in best_params.items():
        if k not in ['objective', 'random_state', 'n_jobs']:
            print(f"  {k}: {v}")
            
    print("\nTraining final XGBoost model with best params...")
    time_model = xgb.XGBRegressor(**best_params)
    
    time_model.fit(
        X_train_processed, y_train,
        eval_set=[(X_train_processed, y_train), (X_test_processed, y_test)],
        verbose=False
    )
    
    preds = time_model.predict(X_test_processed)
    
    r2 = r2_score(y_test, preds)
    rmse = np.sqrt(mean_squared_error(y_test, preds))
    mae = mean_absolute_error(y_test, preds)
    
    print("\n--- Model Performance (Dummy Data) ---")
    print(f"R2:\t\t{r2:.4f}")
    print(f"RMSE:\t\t{rmse:.2f} days")
    print(f"MAE:\t\t{mae:.2f} days")
    
    within_7days = np.mean(np.abs(y_test - preds) <= 7) * 100
    print(f"Accuracy (Within 1 week):\t{within_7days:.1f}%")
    
    os.makedirs("models", exist_ok=True)
    time_model.get_booster().save_model("models/time_to_stable_model.json")
    print("Saved placeholder model to models/time_to_stable_model.json")

if __name__ == "__main__":
    if not os.path.exists("data/warfarin_cohort.csv"):
        print("Run data_generator.py first.")
    else:
        train_time_to_stability()
