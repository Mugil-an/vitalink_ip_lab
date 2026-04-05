from __future__ import annotations

import os

import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.impute import KNNImputer, SimpleImputer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler


def load_dataframe(path):
    ext = os.path.splitext(str(path))[1].lower()
    if ext in [".xls", ".xlsx"]:
        try:
            return pd.read_excel(path, sheet_name="Subject Data")
        except Exception:
            return pd.read_excel(path)
    if ext == ".csv":
        return pd.read_csv(path)
    raise ValueError(f"Unsupported file extension: {ext}")


def map_age(age_str):
    if pd.isna(age_str):
        return np.nan
    age_str = str(age_str).strip()
    mapping = {
        "10 - 19": 1.5,
        "20 - 29": 2.5,
        "30 - 39": 3.5,
        "40 - 49": 4.5,
        "50 - 59": 5.5,
        "60 - 69": 6.5,
        "70 - 79": 7.5,
        "80 - 89": 8.5,
        "90+": 9.5,
    }
    if age_str in mapping:
        return mapping[age_str]
    try:
        return float(age_str)
    except Exception:
        return np.nan


def map_race(race):
    if pd.isna(race):
        return "Unknown"
    race = str(race)
    if "White" in race:
        return "White"
    if "Black" in race or "African" in race:
        return "Black"
    if "Asian" in race:
        return "Asian"
    return "Other"


def create_preprocessor(num_features, cat_features):
    num_transformer = Pipeline(
        steps=[
            ("imputer", KNNImputer(n_neighbors=5)),
            ("scaler", StandardScaler()),
        ]
    )

    cat_transformer = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="constant", fill_value="Unknown")),
            ("onehot", OneHotEncoder(handle_unknown="ignore", sparse_output=False)),
        ]
    )

    return ColumnTransformer(
        transformers=[
            ("num", num_transformer, num_features),
            ("cat", cat_transformer, cat_features),
        ]
    )


def get_feature_names_from_preprocessor(preprocessor, num_features, cat_features):
    feature_names = []
    feature_names.extend(num_features)

    try:
        cat_transformer = preprocessor.named_transformers_["cat"]
        onehot = cat_transformer.named_steps["onehot"]
        cat_names = onehot.get_feature_names_out(cat_features)
        feature_names.extend(cat_names)
    except Exception:
        feature_names.extend([f"cat_{i}" for i in range(len(cat_features))])

    return feature_names


def prepare_iwpc_dose_dataset(df: pd.DataFrame) -> tuple[pd.DataFrame, pd.Series, list[str], list[str]]:
    work = df.dropna(subset=["Therapeutic Dose of Warfarin"]).copy()
    y = pd.to_numeric(work["Therapeutic Dose of Warfarin"], errors="coerce")

    race_col = "Race (Reported)" if "Race (Reported)" in work.columns else ("Race" if "Race" in work.columns else None)
    if race_col is None:
        raise ValueError("Could not find race column. Expected 'Race (Reported)' or 'Race'.")

    work["Age_Num"] = work["Age"].apply(map_age)
    work["Race_Group"] = work[race_col].apply(map_race)

    amiodarone_col = "Amiodarone (Cordarone)" if "Amiodarone (Cordarone)" in work.columns else ("Amiodarone" if "Amiodarone" in work.columns else None)
    if amiodarone_col is None:
        work["Amiodarone"] = 0.0
    else:
        work["Amiodarone"] = pd.to_numeric(work[amiodarone_col], errors="coerce").fillna(0.0)

    enzyme_cols = ["Carbamazepine (Tegretol)", "Phenytoin (Dilantin)", "Rifampin or Rifampicin"]
    existing_enzyme_cols = [col for col in enzyme_cols if col in work.columns]
    if existing_enzyme_cols:
        for col in existing_enzyme_cols:
            work[col] = pd.to_numeric(work[col], errors="coerce").fillna(0.0)
        work["Enzyme_Inducer"] = work[existing_enzyme_cols].max(axis=1)
    else:
        work["Enzyme_Inducer"] = 0.0

    work["CYP2C9"] = work["Cyp2C9 genotypes"].fillna("Unknown")
    common_cyp = ["*1/*1", "*1/*2", "*1/*3", "*2/*2", "*2/*3", "*3/*3"]
    work["CYP2C9"] = work["CYP2C9"].apply(lambda x: x if x in common_cyp else "Other/Unknown")

    work["VKORC1"] = work["VKORC1 -1639 consensus"].fillna("Unknown")

    num_features = ["Age_Num", "Height (cm)", "Weight (kg)", "Amiodarone", "Enzyme_Inducer"]
    cat_features = ["Race_Group", "CYP2C9", "VKORC1"]
    features = num_features + cat_features
    X = work[features]
    valid = y.notna()
    return X.loc[valid].reset_index(drop=True), y.loc[valid].reset_index(drop=True), num_features, cat_features


def prepare_warfarin_dose_dataset(
    df: pd.DataFrame,
) -> tuple[pd.DataFrame, pd.Series, list[str], list[str], list[str], bool]:
    if "Therapeutic Dose of Warfarin" in df.columns:
        X, y, num_features, cat_features = prepare_iwpc_dose_dataset(df)
        cat_features_clinical = ["Race_Group"]
        cat_features_genetic = ["CYP2C9", "VKORC1"]
        return X, y, num_features, cat_features_clinical, cat_features_genetic, True

    if "WarfarinDose" in df.columns:
        work = df.dropna(subset=["WarfarinDose"]).copy()
        y = pd.to_numeric(work["WarfarinDose"], errors="coerce")

        for col in ["Age", "Height", "Weight", "Target_INR", "Renal_Function"]:
            work[col] = pd.to_numeric(work[col], errors="coerce")

        for col in ["Gender", "Amiodarone", "Aspirin", "Smoker", "CYP2C9", "VKORC1", "CYP4F2"]:
            if col not in work.columns:
                work[col] = "Unknown"
            work[col] = work[col].astype(str).fillna("Unknown")

        num_features = ["Age", "Height", "Weight", "Target_INR", "Renal_Function"]
        cat_features_clinical = ["Gender", "Amiodarone", "Aspirin", "Smoker"]
        cat_features_genetic = ["CYP2C9", "VKORC1", "CYP4F2"]

        features = num_features + cat_features_clinical + cat_features_genetic
        X = work[features]
        valid = y.notna()
        return (
            X.loc[valid].reset_index(drop=True),
            y.loc[valid].reset_index(drop=True),
            num_features,
            cat_features_clinical,
            cat_features_genetic,
            False,
        )

    raise ValueError(
        "Unsupported dataset schema. Expected either IWPC columns with 'Therapeutic Dose of Warfarin' "
        "or synthetic columns with 'WarfarinDose'."
    )
