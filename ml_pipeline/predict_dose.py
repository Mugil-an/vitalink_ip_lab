import argparse
import sys
from pathlib import Path

import joblib
import pandas as pd
import xgboost as xgb


BASE_DIR = Path(__file__).resolve().parent
MODEL_PATH = BASE_DIR / "models" / "warfarin_model.json"
PREPROCESSOR_PATH = BASE_DIR / "models" / "preprocessor.joblib"


def load_artifacts():
    """Load baseline model and preprocessor artifacts."""
    if not MODEL_PATH.exists() or not PREPROCESSOR_PATH.exists():
        print(
            "Error: Missing baseline artifacts. Run train_baseline.py first to generate "
            "models/warfarin_model.json and models/preprocessor.joblib."
        )
        sys.exit(1)

    model = xgb.XGBRegressor()
    model.load_model(MODEL_PATH)
    preprocessor = joblib.load(PREPROCESSOR_PATH)
    return model, preprocessor


def predict_warfarin_dose(patient_data: dict, model, preprocessor) -> float:
    """Predict weekly warfarin dose in mg/week."""
    frame = pd.DataFrame([patient_data])
    transformed = preprocessor.transform(frame)
    dose_mg_week = float(model.predict(transformed)[0])
    return max(dose_mg_week, 0.0)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Predict warfarin dose (mg/week) from patient features.")
    
    parser.add_argument('--age', type=float, required=True, help="Decade midpoint (e.g. 6.5 for 60-69)")
    parser.add_argument('--height', type=float, required=True, help="Height in cm")
    parser.add_argument('--weight', type=float, required=True, help="Weight in kg")
    parser.add_argument('--race', type=str, default="Unknown", help="White, Black, Asian, or Other")
    parser.add_argument('--amiodarone', type=float, default=0.0, help="1.0 if taking Amiodarone, else 0.0")
    parser.add_argument('--enzyme_inducer', type=float, default=0.0, help="1.0 if taking Carbamazepine/Phenytoin/Rifampin, else 0.0")
    parser.add_argument('--cyp2c9', type=str, default="Unknown", help="CYP2C9 genotype (e.g. *1/*1)")
    parser.add_argument('--vkorc1', type=str, default="Unknown", help="VKORC1 consensus (e.g. A/G)")
    
    args = parser.parse_args()
    
    patient = {
        'Age_Num': args.age,
        'Height (cm)': args.height,
        'Weight (kg)': args.weight,
        'Race_Group': args.race,
        'Amiodarone': args.amiodarone,
        'Enzyme_Inducer': args.enzyme_inducer,
        'CYP2C9': args.cyp2c9,
        'VKORC1': args.vkorc1
    }
    
    model, preprocessor = load_artifacts()

    print("\n--- Patient Profile ---")
    for k, v in patient.items():
        print(f"{k}: {v}")
        
    try:
        dose = predict_warfarin_dose(patient, model, preprocessor)
        print(f"\n=> Predicted Therapeutic Dose: {dose:.2f} mg/week")
    except Exception as e:
        print(f"\nError during prediction: {e}")

