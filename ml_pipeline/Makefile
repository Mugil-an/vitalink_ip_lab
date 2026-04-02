PYTHON ?= python
PIP ?= pip

.PHONY: help install generate-data train-baseline train-models tune retrain train-time visualize predict clean

help:
	@echo "Available targets:"
	@echo "  install         Install Python dependencies"
	@echo "  generate-data   Generate synthetic warfarin cohort"
	@echo "  train-baseline  Train baseline XGBoost model"
	@echo "  train-models    Train comparison models"
	@echo "  tune            Run model tuning"
	@echo "  retrain         Incrementally retrain baseline model"
	@echo "  train-time      Train time-to-stability model"
	@echo "  visualize       Generate model performance plots"
	@echo "  predict         Run a sample prediction"
	@echo "  clean           Remove generated artifacts"

install:
	$(PIP) install -r requirements.txt

generate-data:
	$(PYTHON) data_generator.py

train-baseline:
	$(PYTHON) train_baseline.py

train-models:
	$(PYTHON) train_warfarin_models.py

tune:
	$(PYTHON) tune_warfarin_models.py

retrain:
	$(PYTHON) retrain.py

train-time:
	$(PYTHON) time_to_stability_model.py

visualize:
	$(PYTHON) visualize.py

predict:
	$(PYTHON) predict_dose.py --age 6.5 --height 170 --weight 75 --race White --amiodarone 0 --enzyme_inducer 0 --cyp2c9 "*1/*1" --vkorc1 "GG"

clean:
	rm -rf output/*.png
	rm -f data/y_test_baseline.npy data/y_pred_baseline.npy data/feature_importances.csv
	rm -f models/warfarin_model.json models/warfarin_model_v2.json models/preprocessor.joblib models/time_to_stable_model.json models/time_to_stable_preprocessor.joblib
