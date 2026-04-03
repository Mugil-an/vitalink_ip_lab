import base64
import html
import json
from pathlib import Path

import pandas as pd

BASE_DIR = Path(__file__).resolve().parent
OUTPUT_DIR = BASE_DIR / "output"
DOCS_DIR = BASE_DIR / "docs"

METRICS_PATH = OUTPUT_DIR / "iwpc_model_metrics.csv"
SHAP_PATH = OUTPUT_DIR / "iwpc_shap_top_features.csv"
SUMMARY_PATH = OUTPUT_DIR / "iwpc_comparison_summary.json"
HTML_PATH = DOCS_DIR / "iwpc_model_comparison_slides.html"

COMPARISON_IMG = OUTPUT_DIR / "iwpc_model_comparison.png"
SCATTER_IMG = OUTPUT_DIR / "iwpc_prediction_scatter.png"
SHAP_BAR_IMG = OUTPUT_DIR / "iwpc_shap_bar.png"
SHAP_BEESWARM_IMG = OUTPUT_DIR / "iwpc_shap_beeswarm.png"


def img_to_data_uri(path: Path) -> str:
    encoded = base64.b64encode(path.read_bytes()).decode("ascii")
    suffix = path.suffix.lower().lstrip(".")
    mime = "png" if suffix == "png" else suffix
    return f"data:image/{mime};base64,{encoded}"


def render_metric_cards(metrics: pd.DataFrame) -> str:
    cards = []
    medal = {1: "01", 2: "02", 3: "03"}
    for row in metrics.head(3).itertuples(index=False):
        cards.append(
            f"""
            <div class="metric-card">
              <div class="metric-rank">{medal.get(int(row.rank), str(row.rank).zfill(2))}</div>
              <h3>{html.escape(str(row.model))}</h3>
              <div class="metric-grid">
                <div><span>RMSE</span><strong>{row.rmse:.2f}</strong></div>
                <div><span>MAE</span><strong>{row.mae:.2f}</strong></div>
                <div><span>R²</span><strong>{row.r2:.3f}</strong></div>
                <div><span>Within 20%</span><strong>{row.within_20_pct:.1f}%</strong></div>
              </div>
            </div>
            """
        )
    return "\n".join(cards)


def render_table(metrics: pd.DataFrame) -> str:
    header = """
    <tr>
      <th>Rank</th>
      <th>Model</th>
      <th>RMSE</th>
      <th>MAE</th>
      <th>R²</th>
      <th>Within 20%</th>
    </tr>
    """
    rows = []
    for row in metrics.itertuples(index=False):
        rows.append(
            f"""
            <tr>
              <td>{int(row.rank)}</td>
              <td>{html.escape(str(row.model))}</td>
              <td>{row.rmse:.4f}</td>
              <td>{row.mae:.4f}</td>
              <td>{row.r2:.4f}</td>
              <td>{row.within_20_pct:.4f}</td>
            </tr>
            """
        )
    return f"<table>{header}{''.join(rows)}</table>"


def render_shap_list(shap_df: pd.DataFrame) -> str:
    items = []
    for row in shap_df.head(8).itertuples(index=False):
        items.append(
            f"""
            <div class="shap-item">
              <span>{html.escape(str(row.feature).replace('_', ' '))}</span>
              <strong>{row.mean_abs_shap:.3f}</strong>
            </div>
            """
        )
    return "\n".join(items)


def build_html(metrics: pd.DataFrame, shap_df: pd.DataFrame, summary: dict) -> str:
    best = metrics.iloc[0]
    iwpc = metrics.loc[metrics["model"] == "IWPC Pharmacogenetic Calculator"].iloc[0]
    clinical = metrics.loc[metrics["model"] == "IWPC Clinical Formula"].iloc[0]
    rmse_gain = iwpc["rmse"] - best["rmse"]
    within_gain = best["within_20_pct"] - iwpc["within_20_pct"]

    comparison_uri = img_to_data_uri(COMPARISON_IMG)
    scatter_uri = img_to_data_uri(SCATTER_IMG)
    shap_bar_uri = img_to_data_uri(SHAP_BAR_IMG)
    shap_beeswarm_uri = img_to_data_uri(SHAP_BEESWARM_IMG)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Warfarin Model Comparison Presentation</title>
  <style>
    :root {{
      --paper: #f5efe3;
      --ink: #1d1b16;
      --rust: #a64624;
      --olive: #4d5b36;
      --gold: #b58a2b;
      --slate: #3f4a52;
      --card: rgba(255,255,255,0.76);
      --line: rgba(29,27,22,0.18);
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      font-family: Georgia, "Times New Roman", serif;
      color: var(--ink);
      background:
        radial-gradient(circle at top left, rgba(182,138,43,0.14), transparent 32%),
        radial-gradient(circle at 85% 14%, rgba(166,70,36,0.12), transparent 26%),
        linear-gradient(180deg, #f4efe6, #eee5d4 42%, #ece1cf 100%);
    }}
    .deck {{
      width: 100%;
    }}
    .slide {{
      position: relative;
      min-height: 100vh;
      padding: 42px 52px;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      page-break-after: always;
      overflow: hidden;
    }}
    .slide::before {{
      content: "";
      position: absolute;
      inset: 18px;
      border: 1px solid var(--line);
      pointer-events: none;
    }}
    .slide::after {{
      content: "";
      position: absolute;
      right: 30px;
      bottom: 28px;
      width: 120px;
      height: 120px;
      background: radial-gradient(circle, rgba(166,70,36,0.12), transparent 70%);
      filter: blur(6px);
      pointer-events: none;
    }}
    .eyebrow {{
      display: inline-block;
      font-size: 12px;
      letter-spacing: 0.28em;
      text-transform: uppercase;
      color: var(--rust);
      margin-bottom: 14px;
    }}
    h1, h2, h3, p {{ margin: 0; }}
    h1 {{
      font-size: 54px;
      line-height: 0.96;
      max-width: 860px;
      font-weight: 700;
    }}
    h2 {{
      font-size: 34px;
      margin-bottom: 22px;
      line-height: 1.05;
      max-width: 720px;
    }}
    p.lead {{
      max-width: 720px;
      font-size: 18px;
      line-height: 1.6;
      margin-top: 22px;
    }}
    .hero-grid {{
      display: grid;
      grid-template-columns: 1.4fr 0.9fr;
      gap: 22px;
      align-items: end;
      margin-top: 26px;
    }}
    .hero-panel, .note-panel, .metric-card, .viz-card {{
      background: var(--card);
      border: 1px solid rgba(29,27,22,0.12);
      backdrop-filter: blur(6px);
      box-shadow: 0 16px 34px rgba(56, 40, 20, 0.08);
    }}
    .hero-panel {{
      padding: 28px;
      border-left: 6px solid var(--gold);
    }}
    .hero-panel strong {{
      display: block;
      font-size: 74px;
      line-height: 0.95;
      color: var(--olive);
      margin-bottom: 14px;
    }}
    .hero-panel span {{
      display: block;
      font-size: 15px;
      text-transform: uppercase;
      letter-spacing: 0.15em;
      color: var(--slate);
      margin-bottom: 10px;
    }}
    .note-panel {{
      padding: 24px;
      align-self: stretch;
      display: flex;
      flex-direction: column;
      justify-content: center;
      gap: 10px;
    }}
    .note-panel p {{
      font-size: 16px;
      line-height: 1.55;
    }}
    .top-grid {{
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 18px;
    }}
    .metric-card {{
      padding: 22px;
      min-height: 240px;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
    }}
    .metric-rank {{
      font-size: 14px;
      letter-spacing: 0.25em;
      color: var(--rust);
      margin-bottom: 18px;
    }}
    .metric-card h3 {{
      font-size: 24px;
      line-height: 1.1;
      min-height: 56px;
    }}
    .metric-grid {{
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 14px;
      margin-top: 20px;
    }}
    .metric-grid div {{
      border-top: 1px solid var(--line);
      padding-top: 10px;
    }}
    .metric-grid span {{
      display: block;
      font-size: 12px;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      color: var(--slate);
    }}
    .metric-grid strong {{
      display: block;
      margin-top: 6px;
      font-size: 28px;
      color: var(--olive);
    }}
    .viz-wrap {{
      display: grid;
      grid-template-columns: 1.2fr 0.8fr;
      gap: 18px;
      align-items: start;
    }}
    .viz-card {{
      padding: 16px;
    }}
    .viz-card img {{
      width: 100%;
      display: block;
      border: 1px solid rgba(29,27,22,0.08);
    }}
    .insight-list {{
      display: grid;
      gap: 12px;
    }}
    .insight {{
      padding: 16px 18px;
      background: rgba(77,91,54,0.08);
      border-left: 4px solid var(--olive);
      font-size: 16px;
      line-height: 1.5;
    }}
    .bottom-grid {{
      display: grid;
      grid-template-columns: 1.05fr 0.95fr;
      gap: 18px;
      align-items: start;
    }}
    table {{
      width: 100%;
      border-collapse: collapse;
      font-size: 15px;
      background: rgba(255,255,255,0.82);
    }}
    th, td {{
      padding: 10px 12px;
      border-bottom: 1px solid var(--line);
      text-align: left;
    }}
    th {{
      text-transform: uppercase;
      letter-spacing: 0.08em;
      font-size: 11px;
      color: var(--slate);
    }}
    .shap-grid {{
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 18px;
    }}
    .shap-item {{
      display: flex;
      justify-content: space-between;
      gap: 14px;
      padding: 12px 0;
      border-bottom: 1px solid var(--line);
      font-size: 16px;
    }}
    .footer {{
      display: flex;
      justify-content: space-between;
      align-items: flex-end;
      margin-top: 20px;
      font-size: 12px;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      color: rgba(29,27,22,0.55);
    }}
    @media print {{
      body {{
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
      }}
      .slide {{
        height: 100vh;
      }}
    }}
  </style>
</head>
<body>
  <div class="deck">
    <section class="slide">
      <div>
        <span class="eyebrow">Warfarin Dose Modeling Study</span>
        <h1>IWPC calculator benchmarking with machine-learning baselines and explainability</h1>
        <p class="lead">
          Shared 20% holdout evaluation on the IWPC cohort. Models compared: IWPC clinical formula, IWPC pharmacogenetic calculator,
          linear regression, random forest, XGBoost, neural network, and the tuned LightGBM repository model.
        </p>
        <div class="hero-grid">
          <div class="hero-panel">
            <span>Best model</span>
            <strong>{html.escape(str(best["model"]))}</strong>
            <p>RMSE improved by <strong style="font-size:34px; display:inline; color:var(--rust);">{rmse_gain:.02f}</strong> mg/week over the IWPC pharmacogenetic calculator, with a modest <strong style="font-size:34px; display:inline; color:var(--rust);">{within_gain:.1f}</strong> point gain in within-20% accuracy.</p>
          </div>
          <div class="note-panel">
            <p><strong>Best RMSE:</strong> {best["rmse"]:.2f} mg/week</p>
            <p><strong>Best MAE:</strong> {best["mae"]:.2f} mg/week</p>
            <p><strong>Best R²:</strong> {best["r2"]:.3f}</p>
            <p><strong>Clinical-only IWPC:</strong> RMSE {clinical["rmse"]:.2f}, MAE {clinical["mae"]:.2f}</p>
          </div>
        </div>
      </div>
      <div class="footer">
        <span>Source cohort: IWPC Subject Data</span>
        <span>Slide 01</span>
      </div>
    </section>

    <section class="slide">
      <div>
        <span class="eyebrow">Leaderboard</span>
        <h2>Top three models are effectively clustered, but the repository model lands first on the primary metric</h2>
        <div class="top-grid">
          {render_metric_cards(metrics)}
        </div>
      </div>
      <div class="footer">
        <span>Metric priority: RMSE, then MAE</span>
        <span>Slide 02</span>
      </div>
    </section>

    <section class="slide">
      <div>
        <span class="eyebrow">Visual Comparison</span>
        <h2>Aggregate metrics and patient-level fit show a narrow edge over the IWPC pharmacogenetic calculator</h2>
        <div class="viz-wrap">
          <div class="viz-card">
            <img src="{comparison_uri}" alt="Model comparison dashboard" />
          </div>
          <div class="insight-list">
            <div class="insight">The tuned LightGBM model is first by RMSE and R², but the IWPC pharmacogenetic formula remains highly competitive.</div>
            <div class="insight">Linear regression nearly matches the top two, suggesting the signal is still dominated by strong structured clinical-genetic effects.</div>
            <div class="insight">Random forest underperforms on this cohort and should not be positioned as a preferred baseline here.</div>
            <div class="insight">The clinical-only IWPC formula shows a clear step down, which justifies retaining genotype-aware modeling in the pipeline.</div>
          </div>
        </div>
      </div>
      <div class="footer">
        <span>Images generated from repository outputs</span>
        <span>Slide 03</span>
      </div>
    </section>

    <section class="slide">
      <div>
        <span class="eyebrow">Fit Diagnostics</span>
        <h2>Patient-level scatter plots show similar calibration bands for the top genotype-aware approaches</h2>
        <div class="viz-card">
          <img src="{scatter_uri}" alt="Prediction scatter comparison" />
        </div>
      </div>
      <div class="footer">
        <span>Shared holdout split: random_state 42</span>
        <span>Slide 04</span>
      </div>
    </section>

    <section class="slide">
      <div>
        <span class="eyebrow">Explainability</span>
        <h2>SHAP confirms the learned model still tracks clinically credible genetic and anthropometric drivers</h2>
        <div class="shap-grid">
          <div class="viz-card">
            <img src="{shap_bar_uri}" alt="SHAP bar chart" />
          </div>
          <div class="viz-card">
            <div class="insight-list">
              <div class="insight">Global feature influence is led by <strong>VKORC1</strong>, then <strong>weight</strong>, <strong>age</strong>, and <strong>CYP2C9</strong>.</div>
              <div class="insight">The strongest SHAP features align with known warfarin dose biology rather than opaque proxy variables.</div>
              <div class="insight">This makes the best model easier to defend clinically than a purely black-box ranking would suggest.</div>
            </div>
            <div style="margin-top:18px;">
              {render_shap_list(shap_df)}
            </div>
          </div>
        </div>
      </div>
      <div class="footer">
        <span>Best model: {html.escape(str(summary["best_model"]))}</span>
        <span>Slide 05</span>
      </div>
    </section>

    <section class="slide">
      <div>
        <span class="eyebrow">Appendix</span>
        <h2>Presentation-ready result table and SHAP distribution view</h2>
        <div class="bottom-grid">
          <div class="viz-card" style="padding:20px;">
            {render_table(metrics)}
          </div>
          <div class="viz-card">
            <img src="{shap_beeswarm_uri}" alt="SHAP beeswarm chart" />
          </div>
        </div>
      </div>
      <div class="footer">
        <span>Generated from {html.escape(str(METRICS_PATH.name))} and {html.escape(str(SHAP_PATH.name))}</span>
        <span>Slide 06</span>
      </div>
    </section>
  </div>
</body>
</html>
"""


def main():
    metrics = pd.read_csv(METRICS_PATH)
    shap_df = pd.read_csv(SHAP_PATH)
    summary = json.loads(SUMMARY_PATH.read_text())
    DOCS_DIR.mkdir(parents=True, exist_ok=True)
    HTML_PATH.write_text(build_html(metrics, shap_df, summary), encoding="utf-8")
    print(f"Wrote {HTML_PATH}")


if __name__ == "__main__":
    main()
