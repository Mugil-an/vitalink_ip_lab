import argparse
import json
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional

import pandas as pd


def _as_oid(value: Any) -> str:
    if isinstance(value, dict) and "$oid" in value:
        return str(value["$oid"])
    return str(value)


def _as_datetime(value: Any) -> pd.Timestamp:
    if isinstance(value, dict) and "$date" in value:
        inner = value["$date"]
        if isinstance(inner, dict) and "$numberLong" in inner:
            return pd.to_datetime(int(inner["$numberLong"]), unit="ms", errors="coerce")
        return pd.to_datetime(inner, errors="coerce")
    return pd.to_datetime(value, errors="coerce")


def _load_json_records(path: Path) -> List[dict]:
    text = path.read_text(encoding="utf-8").strip()
    if not text:
        return []

    if text.startswith("["):
        data = json.loads(text)
        return data if isinstance(data, list) else []

    records = []
    for line in text.splitlines():
        line = line.strip()
        if line:
            records.append(json.loads(line))
    return records


def _safe_get(dic: dict, *keys: str, default=None):
    cur = dic
    for key in keys:
        if not isinstance(cur, dict) or key not in cur:
            return default
        cur = cur[key]
    return cur


def _weekly_total_mg(weekly_dosage: Optional[dict]) -> float:
    if not isinstance(weekly_dosage, dict):
        return 0.0
    keys = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
    return float(sum(float(weekly_dosage.get(day, 0) or 0) for day in keys))


def _extract_patients(records: Iterable[dict]) -> pd.DataFrame:
    rows: List[Dict[str, Any]] = []
    for rec in records:
        patient_id = _as_oid(rec.get("_id"))
        demographics = rec.get("demographics", {}) or {}
        medical_config = rec.get("medical_config", {}) or {}

        age = demographics.get("age")
        weight = _safe_get(rec, "medical_config", "weight")
        height = _safe_get(rec, "medical_config", "height")

        bmi = None
        if weight and height:
            try:
                bmi = float(weight) / ((float(height) / 100.0) ** 2)
            except Exception:
                bmi = None

        weekly_total = _weekly_total_mg(rec.get("weekly_dosage"))
        therapy_start = _as_datetime(medical_config.get("therapy_start_date"))

        rows.append(
            {
                "patient_id": patient_id,
                "name": demographics.get("name"),
                "age": age,
                "sex": demographics.get("gender"),
                "weight_kg": weight,
                "height_cm": height,
                "bmi": bmi,
                "indication": medical_config.get("diagnosis"),
                "therapy_drug": medical_config.get("therapy_drug"),
                "target_inr_min": _safe_get(medical_config, "target_inr", "min", default=2.0),
                "target_inr_max": _safe_get(medical_config, "target_inr", "max", default=3.0),
                "therapy_start_date": therapy_start,
                "assigned_doctor_id": _as_oid(rec.get("assigned_doctor_id")) if rec.get("assigned_doctor_id") else None,
                "account_status": rec.get("account_status"),
                "stable_weekly_dose_mg": weekly_total if weekly_total > 0 else None,
                "created_at": _as_datetime(rec.get("createdAt")),
            }
        )

    df = pd.DataFrame(rows)
    if not df.empty:
        df["therapy_start_date"] = pd.to_datetime(df["therapy_start_date"], errors="coerce")
        df["created_at"] = pd.to_datetime(df["created_at"], errors="coerce")
    return df


def _extract_visits(records: Iterable[dict], patients_df: pd.DataFrame) -> pd.DataFrame:
    weekly_lookup = {}
    target_lookup = {}
    therapy_start_lookup = {}
    for _, row in patients_df.iterrows():
        pid = row["patient_id"]
        weekly_lookup[pid] = row.get("stable_weekly_dose_mg")
        target_lookup[pid] = (row.get("target_inr_min", 2.0), row.get("target_inr_max", 3.0))
        therapy_start_lookup[pid] = row.get("therapy_start_date")

    rows: List[Dict[str, Any]] = []
    for rec in records:
        patient_id = _as_oid(rec.get("_id"))
        inr_history = rec.get("inr_history", []) or []

        default_weekly = weekly_lookup.get(patient_id)
        default_daily = float(default_weekly) / 7.0 if default_weekly else None
        target_min, target_max = target_lookup.get(patient_id, (2.0, 3.0))

        for idx, inr in enumerate(inr_history):
            inr_date = _as_datetime(inr.get("test_date"))
            inr_value = pd.to_numeric(inr.get("inr_value"), errors="coerce")
            notes = str(inr.get("notes") or "")

            dose_changed = int(any(token in notes.lower() for token in ["dose", "adjust", "change"]))

            rows.append(
                {
                    "patient_id": patient_id,
                    "visit_index": idx,
                    "visit_date": inr_date,
                    "inr_value": inr_value,
                    "is_critical": int(bool(inr.get("is_critical", False))),
                    "dose_since_last_visit_mg_day": default_daily,
                    "dose_adjustment_event": dose_changed,
                    "target_inr_min": target_min,
                    "target_inr_max": target_max,
                    "notes": notes,
                    "therapy_start_date": therapy_start_lookup.get(patient_id),
                }
            )

    visits = pd.DataFrame(rows)
    if visits.empty:
        return visits

    visits["visit_date"] = pd.to_datetime(visits["visit_date"], errors="coerce")
    visits["therapy_start_date"] = pd.to_datetime(visits["therapy_start_date"], errors="coerce")
    visits = visits.sort_values(["patient_id", "visit_date"]).reset_index(drop=True)
    visits["visit_interval_days"] = (
        visits.groupby("patient_id")["visit_date"].diff().dt.days
    )
    visits["visit_interval_days"] = visits["visit_interval_days"].fillna(0).astype(float)
    return visits


def _rolling_ttr(window_inr: pd.Series, min_target: pd.Series, max_target: pd.Series) -> float:
    ok = (window_inr >= min_target) & (window_inr <= max_target)
    if len(ok) == 0:
        return 0.0
    return float(ok.mean())


def _build_episodes(visits_df: pd.DataFrame, patients_df: pd.DataFrame) -> pd.DataFrame:
    if visits_df.empty:
        return pd.DataFrame()

    stable_lookup = dict(zip(patients_df["patient_id"], patients_df["stable_weekly_dose_mg"]))
    rows: List[Dict[str, Any]] = []

    for patient_id, grp in visits_df.groupby("patient_id", sort=False):
        grp = grp.sort_values("visit_date").reset_index(drop=True)
        if len(grp) < 3:
            continue

        in_target = (grp["inr_value"] >= grp["target_inr_min"]) & (grp["inr_value"] <= grp["target_inr_max"])
        stable_day = None
        for i in range(1, len(grp)):
            if bool(in_target.iloc[i - 1]) and bool(in_target.iloc[i]):
                stable_day = grp.loc[i, "visit_date"]
                break

        therapy_start = grp.loc[0, "therapy_start_date"]
        if pd.isna(therapy_start):
            therapy_start = grp.loc[0, "visit_date"]

        for i in range(2, len(grp) - 1):
            current = grp.loc[i]
            prev1 = grp.loc[i - 1]
            prev2 = grp.loc[i - 2]
            nxt = grp.loc[i + 1]

            # Design choice: episodes are prediction windows at visit t for target t+1.
            rolling_slice = grp.iloc[max(0, i - 2): i + 1]
            rolling_ttr_3 = _rolling_ttr(
                rolling_slice["inr_value"],
                rolling_slice["target_inr_min"],
                rolling_slice["target_inr_max"],
            )

            days_since_start = (current["visit_date"] - therapy_start).days if not pd.isna(current["visit_date"]) else None
            time_to_stable = None
            if stable_day is not None and not pd.isna(current["visit_date"]):
                time_to_stable = max((stable_day - current["visit_date"]).days, 0)

            rows.append(
                {
                    "patient_id": patient_id,
                    "episode_date": current["visit_date"],
                    "lag_inr_1": prev1["inr_value"],
                    "lag_inr_2": prev2["inr_value"],
                    "lag_dose_1": prev1["dose_since_last_visit_mg_day"],
                    "lag_dose_2": prev2["dose_since_last_visit_mg_day"],
                    "delta_inr": current["inr_value"] - prev1["inr_value"],
                    "delta_dose": (current["dose_since_last_visit_mg_day"] or 0) - (prev1["dose_since_last_visit_mg_day"] or 0),
                    "rolling_ttr_3": rolling_ttr_3,
                    "days_since_initiation": days_since_start,
                    "next_inr": nxt["inr_value"],
                    "time_to_stable_days": time_to_stable,
                    "stable_weekly_dose_mg": stable_lookup.get(patient_id),
                    "target_inr_min": current["target_inr_min"],
                    "target_inr_max": current["target_inr_max"],
                }
            )

    episodes = pd.DataFrame(rows)
    if not episodes.empty:
        episodes = episodes.sort_values(["patient_id", "episode_date"]).reset_index(drop=True)
    return episodes


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Build Acitrom patients/visits/episodes datasets from exported PatientProfile documents"
    )
    parser.add_argument(
        "--patient-profiles-json",
        type=Path,
        required=True,
        help="Path to JSON array or NDJSON export of PatientProfile documents",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=Path(__file__).resolve().parent / "data",
        help="Output directory for CSV files",
    )
    args = parser.parse_args()

    records = _load_json_records(args.patient_profiles_json)
    patients_df = _extract_patients(records)
    visits_df = _extract_visits(records, patients_df)
    episodes_df = _build_episodes(visits_df, patients_df)

    args.out_dir.mkdir(parents=True, exist_ok=True)
    patients_path = args.out_dir / "patients.csv"
    visits_path = args.out_dir / "visits.csv"
    episodes_path = args.out_dir / "episodes.csv"

    patients_df.to_csv(patients_path, index=False)
    visits_df.to_csv(visits_path, index=False)
    episodes_df.to_csv(episodes_path, index=False)

    print("\n--- Acitrom dataset build complete ---")
    print(f"patients.csv rows: {len(patients_df)} -> {patients_path}")
    print(f"visits.csv rows:   {len(visits_df)} -> {visits_path}")
    print(f"episodes.csv rows: {len(episodes_df)} -> {episodes_path}")
    print("notice: episodes are derived from visit history; they are not directly collected in app tables.")


if __name__ == "__main__":
    main()
