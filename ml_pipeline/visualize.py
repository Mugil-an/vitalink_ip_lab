import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import r2_score, mean_squared_error

def create_performance_plot(actual, predicted, r2, rmse, within_20pct):
    plt.figure(figsize=(10, 8))
    plt.scatter(actual, predicted, alpha=0.6, color="#3498DB", s=30)
    plt.plot([actual.min(), actual.max()], [actual.min(), actual.max()], 'r--', lw=2)
    sns.regplot(x=actual, y=predicted, scatter=False, color="#E74C3C", scatter_kws={'alpha': 0.2})
    
    textstr = f"R² = {r2:.3f}\nRMSE = {rmse:.2f} mg/week\nWithin 20% = {within_20pct:.1f}%"
    plt.text(0.05, 0.95, textstr, transform=plt.gca().transAxes, fontsize=12,
             verticalalignment='top', bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))
             
    plt.title("Warfarin Dose Prediction Performance", fontweight="bold", fontsize=14)
    plt.xlabel("Actual Dose (mg/week)")
    plt.ylabel("Predicted Dose (mg/week)")
    plt.grid(True, alpha=0.3)
    
    os.makedirs("output", exist_ok=True)
    plt.savefig("output/figure1_performance.png", dpi=300, bbox_inches='tight')
    plt.close()
    
def create_feature_importance_plot(importance_df):
    if importance_df is None or len(importance_df) == 0:
        return
        
    top_n = min(10, len(importance_df))
    plot_df = importance_df.head(top_n)
    
    plt.figure(figsize=(10, 8))
    sns.barplot(x="Gain", y="Feature", data=plot_df, color="#27AE60", alpha=0.8)
    
    plt.title("Top Feature Importance", fontweight="bold", fontsize=14)
    plt.grid(axis='x', alpha=0.3)
    
    os.makedirs("output", exist_ok=True)
    plt.savefig("output/figure2_feature_importance.png", dpi=300, bbox_inches='tight')
    plt.close()

def create_residual_plot(actual, predicted):
    residuals = actual - predicted
    
    plt.figure(figsize=(10, 8))
    plt.scatter(predicted, residuals, alpha=0.6, color="#3498DB", s=30)
    plt.axhline(0, color='r', linestyle='--', lw=2)
    
    import warnings
    # regplot can sometimes throw warnings depending on numpy versions
    with warnings.catch_warnings():
        warnings.simplefilter('ignore')
        sns.regplot(x=predicted, y=residuals, scatter=False, color="#E74C3C")
    
    plt.title("Residual Analysis", fontweight="bold", fontsize=14)
    plt.xlabel("Predicted Dose (mg/week)")
    plt.ylabel("Residuals (Actual - Predicted)")
    plt.grid(True, alpha=0.3)
    
    os.makedirs("output", exist_ok=True)
    plt.savefig("output/figure3_residuals.png", dpi=300, bbox_inches='tight')
    plt.close()

if __name__ == "__main__":
    if not os.path.exists("data/y_test_baseline.npy"):
        print("Please run train_baseline.py first to generate predictions.")
    else:
        y_test = np.load("data/y_test_baseline.npy")
        y_pred = np.load("data/y_pred_baseline.npy")
        
        r2 = r2_score(y_test, y_pred)
        rmse = np.sqrt(mean_squared_error(y_test, y_pred))
        within_20 = np.mean(np.abs(y_test - y_pred) <= 0.2 * y_test) * 100
        
        print("Creating plots...")
        create_performance_plot(y_test, y_pred, r2, rmse, within_20)
        create_residual_plot(y_test, y_pred)
        
        if os.path.exists("data/feature_importances.csv"):
            imp_df = pd.read_csv("data/feature_importances.csv")
            create_feature_importance_plot(imp_df)
            
        print("Done. Check output/ directory for PNG figures.")
