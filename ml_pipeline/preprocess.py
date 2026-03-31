import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.pipeline import Pipeline
import joblib
import os

def get_preprocessor():
    """
    Returns a scikit-learn ColumnTransformer for preprocessing the Warfarin cohort data.
    """
    numeric_features = ['Age', 'Weight', 'Height', 'BMI', 'Target_INR', 'Renal_Function']
    categorical_features = ['Gender', 'CYP2C9', 'VKORC1', 'CYP4F2', 'Amiodarone', 'Aspirin', 'Smoker']
    
    numeric_transformer = Pipeline(steps=[
        ('scaler', StandardScaler())
    ])
    
    categorical_transformer = Pipeline(steps=[
        ('onehot', OneHotEncoder(handle_unknown='ignore')) # Keep all categories explicitly for XGB
    ])
    
    preprocessor = ColumnTransformer(
        transformers=[
            ('num', numeric_transformer, numeric_features),
            ('cat', categorical_transformer, categorical_features)
        ],
        remainder='drop' # Drop anything not strictly specified
    )
    
    return preprocessor, numeric_features, categorical_features

def get_feature_names(preprocessor, numeric_features, categorical_features):
    cat_names = preprocessor.named_transformers_['cat']['onehot'].get_feature_names_out(categorical_features)
    return numeric_features + list(cat_names)

if __name__ == "__main__":
    print("Testing Preprocessor...")
    # Generate dummy data to test
    from data_generator import generate_warfarin_data
    df = generate_warfarin_data(50)
    
    preprocessor, num_f, cat_f = get_preprocessor()
    X = df.drop(columns=['WarfarinDose', 'Days_To_Stable'], errors='ignore')
    
    X_processed = preprocessor.fit_transform(X)
    feature_names = get_feature_names(preprocessor, num_f, cat_f)
    
    print(f"Original shape: {X.shape}")
    print(f"Processed shape: {X_processed.shape}")
    print(f"Features ({len(feature_names)}): {feature_names}")
    
    os.makedirs("models", exist_ok=True)
    joblib.dump(preprocessor, "models/preprocessor.joblib")
    print("Pre-processor saved as models/preprocessor.joblib")
