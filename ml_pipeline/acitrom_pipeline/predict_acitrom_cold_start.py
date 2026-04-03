import argparse
import math
from dataclasses import dataclass
from typing import Optional


def _safe_float(value: Optional[float], default: float = 0.0) -> float:
    try:
        if value is None:
            return default
        return float(value)
    except (TypeError, ValueError):
        return default


def _normalize_text(value: Optional[str]) -> str:
    return str(value or "").strip().upper().replace(" ", "")


def _bsa_mosteller(height_cm: float, weight_kg: float) -> float:
    height_cm = max(height_cm, 1.0)
    weight_kg = max(weight_kg, 1.0)
    return math.sqrt((height_cm * weight_kg) / 3600.0)


@dataclass
class ColdStartInput:
    age: float
    sex: str
    weight_kg: float
    height_cm: float
    smoker: bool = False
    indication: str = "OTHER"
    amiodarone: bool = False
    target_inr_min: float = 2.0
    target_inr_max: float = 3.0
    current_inr: Optional[float] = None
    current_daily_dose_mg: Optional[float] = None
    vkorc1: str = "UNKNOWN"
    cyp2c9: str = "UNKNOWN"
    cyp4f2: str = "UNKNOWN"
    ggcx: str = "UNKNOWN"


def _north_indian_multiple_regression(inp: ColdStartInput) -> float:
    age = _safe_float(inp.age)
    height = _safe_float(inp.height_cm)
    weight = _safe_float(inp.weight_kg)
    bsa = _bsa_mosteller(height, weight)

    is_male = 1 if _normalize_text(inp.sex) in {"M", "MALE"} else 0
    smoker = 1 if inp.smoker else 0

    indication = _normalize_text(inp.indication)
    indication_term = 0.0
    if indication == "DVR":
        indication_term = 0.327
    elif indication == "AVR":
        indication_term = -0.092

    vkorc1 = _normalize_text(inp.vkorc1)
    cyp2c9 = _normalize_text(inp.cyp2c9)
    cyp4f2 = _normalize_text(inp.cyp4f2)
    ggcx = _normalize_text(inp.ggcx)

    vkorc1_ga = 1 if vkorc1 in {"GA", "AG"} else 0
    vkorc1_aa = 1 if vkorc1 == "AA" else 0

    cyp2c9_2_ct = 1 if "*1/*2" in cyp2c9 or "*2/*1" in cyp2c9 or cyp2c9 == "CT" else 0
    cyp2c9_3_ac = 1 if "*1/*3" in cyp2c9 or "*3/*1" in cyp2c9 or cyp2c9 == "AC" else 0

    cyp4f2_ga = 1 if cyp4f2 in {"GA", "AG", "CT", "TC"} else 0
    cyp4f2_aa = 1 if cyp4f2 in {"AA", "TT"} else 0

    ggcx_cg = 1 if ggcx in {"CG", "GC"} else 0
    ggcx_gg = 1 if ggcx == "GG" else 0

    dose_mg_day = (
        3.082
        - 0.013 * smoker
        - 0.433 * is_male
        - 0.004 * age
        + indication_term
        + 0.026 * height
        + 0.151 * weight
        - 7.660 * bsa
        - 0.862 * vkorc1_ga
        - 2.257 * vkorc1_aa
        - 0.049 * cyp2c9_2_ct
        - 0.456 * cyp2c9_3_ac
        + 0.449 * cyp4f2_ga
        + 0.230 * cyp4f2_aa
        + 0.245 * ggcx_cg
        + 1.055 * ggcx_gg
    )
    return max(dose_mg_day, 0.5)


def _clinical_start_rule(inp: ColdStartInput) -> float:
    age = _safe_float(inp.age)
    weight = _safe_float(inp.weight_kg)
    target_mid = (inp.target_inr_min + inp.target_inr_max) / 2.0

    dose = 2.0
    if age >= 75:
        dose = 1.0

    if weight >= 85:
        dose += 0.5
    elif weight < 50:
        dose -= 0.5

    if inp.amiodarone:
        dose -= 0.5

    if target_mid > 3.0:
        dose += 0.25

    return min(max(dose, 0.5), 4.0)


def _inr_followup_adjustment(inp: ColdStartInput) -> Optional[float]:
    if inp.current_inr is None or inp.current_daily_dose_mg is None:
        return None

    current_inr = _safe_float(inp.current_inr)
    current_dose = _safe_float(inp.current_daily_dose_mg)
    if current_inr <= 0 or current_dose <= 0:
        return None

    target_mid = (inp.target_inr_min + inp.target_inr_max) / 2.0
    naive = current_dose * (target_mid / current_inr)

    # Safety design: limit each step change to ±20%.
    lower = current_dose * 0.80
    upper = current_dose * 1.20
    capped = min(max(naive, lower), upper)
    return min(max(capped, 0.5), 6.0)


def _simple_ags_score(inp: ColdStartInput) -> Optional[float]:
    # AGS-like score from published CYP2C9/VKORC1 concept, normalized on available markers.
    scores = []

    cyp2c9 = _normalize_text(inp.cyp2c9)
    if cyp2c9:
        if "*1/*1" in cyp2c9:
            scores.append(2)
        elif "*1/*2" in cyp2c9 or "*1/*3" in cyp2c9:
            scores.append(1)
        elif "*2/*2" in cyp2c9 or "*2/*3" in cyp2c9 or "*3/*3" in cyp2c9:
            scores.append(0)

    vkorc1 = _normalize_text(inp.vkorc1)
    if vkorc1:
        if vkorc1 == "GG":
            scores.append(2)
        elif vkorc1 in {"GA", "AG"}:
            scores.append(1)
        elif vkorc1 == "AA":
            scores.append(0)

    if not scores:
        return None

    return (sum(scores) / (2 * len(scores))) * 100.0


def predict_acitrom_cold_start(inp: ColdStartInput) -> dict:
    rule_daily = _clinical_start_rule(inp)
    formula_daily = _north_indian_multiple_regression(inp)

    # Design choice: blend paper formula with conservative rule baseline.
    blended_daily = 0.60 * formula_daily + 0.40 * rule_daily

    followup_daily = _inr_followup_adjustment(inp)
    if followup_daily is not None:
        final_daily = followup_daily
        strategy = "inr_followup_adjustment"
    else:
        final_daily = blended_daily
        strategy = "cold_start_rule_plus_formula"

    ags = _simple_ags_score(inp)
    risk_band = "INTERMEDIATE"
    if ags is not None:
        if ags <= 60:
            risk_band = "LOW_DOSE_TENDENCY"
        elif ags > 70:
            risk_band = "HIGH_DOSE_TENDENCY"

    weekly = final_daily * 7.0
    min_daily = final_daily * 0.9
    max_daily = final_daily * 1.1

    return {
        "strategy": strategy,
        "daily_dose_mg": round(final_daily, 3),
        "weekly_dose_mg": round(weekly, 3),
        "recommended_range_daily_mg": [round(min_daily, 3), round(max_daily, 3)],
        "rule_baseline_daily_mg": round(rule_daily, 3),
        "paper_formula_daily_mg": round(formula_daily, 3),
        "ags_like_score": None if ags is None else round(ags, 2),
        "dose_tendency": risk_band,
        "notice": "Decision support only. Clinician review is mandatory before prescribing.",
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Rule-based cold-start Acitrom predictor")
    parser.add_argument("--age", type=float, required=True)
    parser.add_argument("--sex", type=str, default="Female")
    parser.add_argument("--weight", type=float, required=True, help="Weight in kg")
    parser.add_argument("--height", type=float, required=True, help="Height in cm")
    parser.add_argument("--smoker", action="store_true")
    parser.add_argument("--amiodarone", action="store_true")
    parser.add_argument("--indication", type=str, default="OTHER", help="DVR, AVR, or OTHER")
    parser.add_argument("--target-inr-min", type=float, default=2.0)
    parser.add_argument("--target-inr-max", type=float, default=3.0)
    parser.add_argument("--current-inr", type=float)
    parser.add_argument("--current-daily-dose", type=float, help="Current daily dose in mg")
    parser.add_argument("--vkorc1", type=str, default="UNKNOWN")
    parser.add_argument("--cyp2c9", type=str, default="UNKNOWN")
    parser.add_argument("--cyp4f2", type=str, default="UNKNOWN")
    parser.add_argument("--ggcx", type=str, default="UNKNOWN")
    return parser


def main() -> None:
    args = build_parser().parse_args()
    inp = ColdStartInput(
        age=args.age,
        sex=args.sex,
        weight_kg=args.weight,
        height_cm=args.height,
        smoker=args.smoker,
        indication=args.indication,
        amiodarone=args.amiodarone,
        target_inr_min=args.target_inr_min,
        target_inr_max=args.target_inr_max,
        current_inr=args.current_inr,
        current_daily_dose_mg=args.current_daily_dose,
        vkorc1=args.vkorc1,
        cyp2c9=args.cyp2c9,
        cyp4f2=args.cyp4f2,
        ggcx=args.ggcx,
    )

    result = predict_acitrom_cold_start(inp)
    print("\n--- Acitrom Cold-Start Prediction ---")
    for key, value in result.items():
        print(f"{key}: {value}")


if __name__ == "__main__":
    main()
