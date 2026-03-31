import os
import pandas as pd
import numpy as np
import xgboost as xgb
import joblib
from sklearn.metrics import r2_score, mean_squared_error, mean_absolute_error
from data_generator import generate_warfarin_data

def continuous_retrain(new_patients=500, model_path="models/warfarin_model.json", preprocessor_path="models/preprocessor.joblib"):
    print(f"Acquiring new batch of {new_patients} patients for incremental training...")
    df_new = generate_warfarin_data(new_patients, random_seed=456) # different seed for new data
    
    if not os.path.exists(model_path) or not os.path.exists(preprocessor_path):
        print("Existing model or preprocessor not found! Run train_baseline.py first.")
        return
        
    X_new = df_new.drop(columns=['WarfarinDose', 'Days_To_Stable'], errors='ignore')
    y_new = df_new['WarfarinDose']
    
    preprocessor = joblib.load(preprocessor_path)
    # We MUST use transform, not fit_transform, to keep feature alignment identical to baseline
    X_new_processed = preprocessor.transform(X_new)
    
    print("\n--- Pre-retraining Performance on New Data ---")
    # Load old model to check its performance before training
    old_model = xgb.XGBRegressor()
    old_model.load_model(model_path)
    
    preds_before = old_model.predict(X_new_processed)
    r2_before = r2_score(y_new, preds_before)
    rmse_before = np.sqrt(mean_squared_error(y_new, preds_before))
    print(f"Old Model R2 on new data: {r2_before:.4f}")
    
    print("\n--- Retraining Model Incrementally ---")
    # To retrain an sklearn API XGBoost model incrementally:
    # 1. Initialize a new architecture
    # 2. fit() with xgb_model=model_path
    incremental_model = xgb.XGBRegressor(
        objective="reg:squarederror",
        max_depth=7,
        learning_rate=0.05, # Can lower learning rate for fine-tuning
        n_estimators=50, # Just add 50 more trees
        n_jobs=-1
    )
    
    incremental_model.fit(
        X_new_processed, y_new,
        xgb_model=model_path,
        verbose=False
    )
    
    print("\n--- Post-retraining Performance on New Data ---")
    preds_after = incremental_model.predict(X_new_processed)
    r2_after = r2_score(y_new, preds_after)
    rmse_after = np.sqrt(mean_squared_error(y_new, preds_after))
    
    print(f"Retrained Model R2 on new data:   {r2_after:.4f}")
    print(f"R2 Improved by:                   {(r2_after - r2_before):.4f}")
    
    # Save the updated model
    incremental_model.get_booster().save_model("models/warfarin_model_v2.json")
    print("\nUpdated model saved to models/warfarin_model_v2.json")

if __name__ == "__main__":
    continuous_retrain()
