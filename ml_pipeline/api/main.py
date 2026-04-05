from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

from flask import Flask, jsonify, request


BASE_DIR = Path(__file__).resolve().parent
ML_PIPELINE_DIR = BASE_DIR.parent
if str(ML_PIPELINE_DIR) not in sys.path:
	sys.path.insert(0, str(ML_PIPELINE_DIR))

from warfarin_pipeline.predict_dose import load_artifacts, predict_warfarin_dose
from acitrom_pipeline.predict_acitrom_cold_start import ColdStartInput, predict_acitrom_cold_start


app = Flask(__name__)

WARFARIN_IWPC_FIELDS = [
	"age_decades",
	"height_cm",
	"weight_kg",
	"race_group",
	"amiodarone",
	"enzyme_inducer",
	"cyp2c9",
	"vkorc1",
]

WARFARIN_SYNTHETIC_FIELDS = [
	"age",
	"height",
	"weight",
	"target_inr",
	"renal_function",
	"gender",
	"amiodarone",
	"aspirin",
	"smoker",
	"cyp2c9",
	"vkorc1",
	"cyp4f2",
]

ACITROM_REQUIRED_FIELDS = [
	"age",
	"sex",
	"weight_kg",
	"height_cm",
]


def _ensure_json() -> tuple[dict[str, Any] | None, Any | None]:
	payload = request.get_json(silent=True)
	if not isinstance(payload, dict):
		return None, (jsonify({"error": "Request body must be a JSON object."}), 400)
	return payload, None


def _missing_fields(payload: dict[str, Any], required: list[str]) -> list[str]:
	return [field for field in required if field not in payload]


def _to_bool(value: Any, default: bool = False) -> bool:
	if isinstance(value, bool):
		return value
	if value is None:
		return default
	if isinstance(value, (int, float)):
		return bool(value)
	text = str(value).strip().lower()
	if text in {"1", "true", "yes", "y"}:
		return True
	if text in {"0", "false", "no", "n"}:
		return False
	return default


def _to_float(value: Any, name: str) -> float:
	try:
		return float(value)
	except (TypeError, ValueError):
		raise ValueError(f"Field '{name}' must be numeric.")


def _build_warfarin_candidates(payload: dict[str, Any]) -> tuple[dict[str, Any], dict[str, Any], str]:
	input_mode = "iwpc"
	if all(field in payload for field in WARFARIN_SYNTHETIC_FIELDS):
		input_mode = "synthetic"

	if input_mode == "synthetic":
		synthetic_patient = {
			"Age": _to_float(payload.get("age"), "age"),
			"Height": _to_float(payload.get("height"), "height"),
			"Weight": _to_float(payload.get("weight"), "weight"),
			"Target_INR": _to_float(payload.get("target_inr"), "target_inr"),
			"Renal_Function": _to_float(payload.get("renal_function"), "renal_function"),
			"Gender": str(payload.get("gender", "Unknown")),
			"Amiodarone": str(payload.get("amiodarone", "No")),
			"Aspirin": str(payload.get("aspirin", "No")),
			"Smoker": str(payload.get("smoker", "No")),
			"CYP2C9": str(payload.get("cyp2c9", "Unknown")),
			"VKORC1": str(payload.get("vkorc1", "Unknown")),
			"CYP4F2": str(payload.get("cyp4f2", "Unknown")),
		}
		iwpc_patient = {
			"Age_Num": max(_to_float(payload.get("age"), "age") / 10.0, 0.0),
			"Height (cm)": _to_float(payload.get("height"), "height"),
			"Weight (kg)": _to_float(payload.get("weight"), "weight"),
			"Race_Group": str(payload.get("race_group", "Unknown")),
			"Amiodarone": 1.0 if _to_bool(payload.get("amiodarone"), False) else 0.0,
			"Enzyme_Inducer": _to_float(payload.get("enzyme_inducer", 0.0), "enzyme_inducer"),
			"CYP2C9": str(payload.get("cyp2c9", "Unknown")),
			"VKORC1": str(payload.get("vkorc1", "Unknown")),
		}
		return synthetic_patient, iwpc_patient, input_mode

	missing = _missing_fields(payload, WARFARIN_IWPC_FIELDS)
	if missing:
		raise ValueError(
			"Missing required fields. Provide either IWPC fields "
			f"{WARFARIN_IWPC_FIELDS} or synthetic fields {WARFARIN_SYNTHETIC_FIELDS}."
		)

	age_decades = _to_float(payload.get("age_decades"), "age_decades")
	height_cm = _to_float(payload.get("height_cm"), "height_cm")
	weight_kg = _to_float(payload.get("weight_kg"), "weight_kg")

	iwpc_patient = {
		"Age_Num": age_decades,
		"Height (cm)": height_cm,
		"Weight (kg)": weight_kg,
		"Race_Group": str(payload.get("race_group", "Unknown")),
		"Amiodarone": _to_float(payload.get("amiodarone"), "amiodarone"),
		"Enzyme_Inducer": _to_float(payload.get("enzyme_inducer"), "enzyme_inducer"),
		"CYP2C9": str(payload.get("cyp2c9", "Unknown")),
		"VKORC1": str(payload.get("vkorc1", "Unknown")),
	}
	synthetic_patient = {
		"Age": max(age_decades * 10.0, 0.0),
		"Height": height_cm,
		"Weight": weight_kg,
		"Target_INR": _to_float(payload.get("target_inr", 2.5), "target_inr"),
		"Renal_Function": _to_float(payload.get("renal_function", 85.0), "renal_function"),
		"Gender": str(payload.get("gender", "Unknown")),
		"Amiodarone": "Yes" if _to_bool(payload.get("amiodarone", False)) else "No",
		"Aspirin": "Yes" if _to_bool(payload.get("aspirin", False)) else "No",
		"Smoker": "Yes" if _to_bool(payload.get("smoker", False)) else "No",
		"CYP2C9": str(payload.get("cyp2c9", "Unknown")),
		"VKORC1": str(payload.get("vkorc1", "Unknown")),
		"CYP4F2": str(payload.get("cyp4f2", "CC")),
	}
	return synthetic_patient, iwpc_patient, input_mode


@app.get("/health")
def health() -> Any:
	return jsonify({"status": "ok", "service": "vitalink-ml-api"})


@app.post("/predict/warfarin")
def predict_warfarin() -> Any:
	payload, error = _ensure_json()
	if error:
		return error

	try:
		synthetic_patient, iwpc_patient, input_mode = _build_warfarin_candidates(payload)
		model, preprocessor = load_artifacts()

		prediction_errors: list[str] = []
		for candidate_name, candidate in [
			("synthetic", synthetic_patient),
			("iwpc", iwpc_patient),
		]:
			try:
				dose_mg_week = predict_warfarin_dose(candidate, model, preprocessor)
				return jsonify(
					{
						"model": "warfarin",
						"predicted_weekly_dose_mg": round(float(dose_mg_week), 4),
						"input_mode": input_mode,
						"prediction_schema_used": candidate_name,
						"input": payload,
					}
				)
			except Exception as inner_exc:
				prediction_errors.append(f"{candidate_name}: {inner_exc}")

		return jsonify({"error": "Prediction failed for available schemas.", "details": prediction_errors}), 400
	except ValueError as exc:
		return jsonify({"error": str(exc)}), 400
	except Exception as exc:
		return jsonify({"error": f"Prediction failed: {exc}"}), 500


@app.post("/predict/acitrom")
def predict_acitrom() -> Any:
	payload, error = _ensure_json()
	if error:
		return error

	missing = _missing_fields(payload, ACITROM_REQUIRED_FIELDS)
	if missing:
		return jsonify({"error": "Missing required fields.", "missing": missing}), 400

	try:
		cold_start_input = ColdStartInput(
			age=_to_float(payload.get("age"), "age"),
			sex=str(payload.get("sex")),
			weight_kg=_to_float(payload.get("weight_kg"), "weight_kg"),
			height_cm=_to_float(payload.get("height_cm"), "height_cm"),
			smoker=_to_bool(payload.get("smoker", False)),
			indication=str(payload.get("indication", "OTHER")),
			amiodarone=_to_bool(payload.get("amiodarone", False)),
			target_inr_min=float(payload.get("target_inr_min", 2.0)),
			target_inr_max=float(payload.get("target_inr_max", 3.0)),
			current_inr=float(payload["current_inr"]) if payload.get("current_inr") is not None else None,
			current_daily_dose_mg=float(payload["current_daily_dose_mg"])
			if payload.get("current_daily_dose_mg") is not None
			else None,
			vkorc1=str(payload.get("vkorc1", "UNKNOWN")),
			cyp2c9=str(payload.get("cyp2c9", "UNKNOWN")),
			cyp4f2=str(payload.get("cyp4f2", "UNKNOWN")),
			ggcx=str(payload.get("ggcx", "UNKNOWN")),
		)

		result = predict_acitrom_cold_start(cold_start_input)
	except ValueError as exc:
		return jsonify({"error": str(exc)}), 400
	except Exception as exc:
		return jsonify({"error": f"Prediction failed: {exc}"}), 500

	return jsonify({"model": "acitrom", "result": result, "input": payload})


if __name__ == "__main__":
	app.run(host="0.0.0.0", port=8000, debug=True)
