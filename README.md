# Instructions for Use

**Authors:** Germán Fabian Escobar Fiesco / Surcolombiana University  
**Date:** March 2026  
**Version:** 1.0

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Repository Structure](#2-repository-structure)
3. [Execution Workflow: MATLAB Code Villavicencio](#3-execution-workflow-matlab-code-villavicencio)
4. [Results: Cities Article](#4-execution-workflow-results-three-cities)
5. [Output Files Description](#5-output-files-description)
6. [Contact](#6-contact)

---

## 1. Project Overview

This repository contains MATLAB code for the paper:  
**A Hybrid Framework Integrating an Optimal SEIR Control Model with Supervised Learning for Analyzing SARS-CoV-2 Coronavirus Data in Small Urban Settings**

---

## 2. Repository Structure

| Folder | File |
|---------|----------|
| **Matlab_Code_Villavicencio/** | `Dataset_Villavicencio.m`<br>`Control_SEIR_Villavicencio.m`<br>`Analysis_Efficacy_Control_Villavicencio.m`<br>`ML_Hybrid_SEIR_Villavicencio.m`<br>`Analysis_Profit_Hybrid_Villavicencio.m`<br>`LSTM_Advanced_Features.m`<br>`RawData_Villavicencio.xlsx` |
| **Results_Control_SEIR_Three_Cities/** | `Results_Control_SEIR_Neiva_Data.csv`<br>`Results_Control_SEIR_Neiva_Metrics.csv`<br>`Results_Control_SEIR_Monteria_Data.csv`<br>`Results_Control_SEIR_Monteria_Data.Metrics`<br>`Results_Control_SEIR_Villavicencio_Data.csv`<br>`Results_Control_SEIR_Villavicencio_Metrics.csv`<br>`Results_Efficacy_Control_Neiva_Data.csv`<br>`Results_Efficacy_Control_Neiva_Metrics.csv`<br>`Results_Efficacy_Control_Monteria_Data.csv`<br>`Results_Efficacy_Control_Monteria_Data.Metrics`<br>`Results_Efficacy_Control_Villavicencio_Data.csv`<br>`Results_Efficacy_Control_Villavicencio_Metrics.csv` |
| **Results_Hybrid_Three_Cities_60-40/** | `Results_Hybrid_Neiva.mat`<br>`Results_Hybrid_Monteria.mat`<br>`Results_Hybrid_Villavicencio.mat`<br>`Results_Gain_Hybrid_Neiva.mat`<br>`Results_Gain_Hybrid_Monteria.mat`<br>`Results_Gain_Hybrid_Villavicencio.mat` |
| **Results_Hybrid_Three_Cities_70-30/** | `Results_Hybrid_Neiva.mat`<br>`Results_Hybrid_Monteria.mat`<br>`Results_Hybrid_Villavicencio.mat`<br>`Results_Gain_Hybrid_Neiva.mat`<br>`Results_Gain_Hybrid_Monteria.mat`<br>`Results_Gain_Hybrid_Villavicencio.mat` |

---

## 3. Execution Workflow: MATLAB Code Villavicencio

### List of Matlab scripts
**Execute the following scripts in order from the `Matlab_Code_Villavicencio` folder:**
  - `Dataset_Villavicencio.m`
  - `Control_SEIR_Villavicencio.m`
  - `Analysis_Efficacy_Control_Villavicencio.m`
  - `ML_Hybrid_SEIR_Villavicencio.m`
  - `Analysis_Gain_Hybrid_Villavicencio.m`
  - `LSTM_Advanced_Features.m`

### Execution algorithms
**Step 1: Data Processing** 
  - Command Window Matlab: `>> Dataset_Villavicencio` 
  - Inputs: `RawData_Villavicencio.xlsx`
  - Outputs: `Results_Dataset_Villavicencio.mat`, `imputation_statistics_villavicencio.mat`, `imputation_report_villavicencio.txt`, `two figures`

**Step 2: SEIR Control Model Estimation**
  - Command Window Matlab: `Control_SEIR_Villavicencio`
  - Inputs: `Results_Dataset_Villavicencio.mat`
  - Outputs: `Results_Control_SEIR_Villavicencio.mat`, `Control_SEIR_Villavicencio.png`

**Step 3:** 
  - Command Window Matlab: `Analysis_Efficacy_Control_Villavicencio`
  - Inputs: `Results_Control_SEIR_Villavicencio.mat`
  - Outputs: `Results_Efficacy_Control_Villavicencio.mat`, `Efficacy_Analysis_Control_Villavicencio.png`, `Weight_Sensitivity.png`
    
**Step 4:**
  - Command Window Matlab:`ML_Hybrid_SEIR_Villavicencio`
  - Input: `Results_Efficacy_Control_Villavicencio.mat`
  - Outputs: `Results_Hybrid_Villavicencio.mat`, `Hybrid_Models_Comparison_Villavicencio.png`, `Hybrid_Error_Analysis_Villavicencio.png`
    
**Step 5:**
  - Command Window Matlab:`Analysis_Gain_Hybrid_Villavicencio`
  - Inputs: `Results_Hybrid_Villavicencio.mat`, `Results_Control_SEIR_Villavicencio.mat`
  - Outputs: `Results_Gain_Hybrid_Villavicencio.mat`, `Hybrid_Gain_Analysis_Villavicencio.png`
  
**Step 6:**
  - Command Window Matlab:`LSTM_Advanced_Features`
  - Input: `Results_Dataset_Villavicencio.mat`
  - Outputs: `Results_LSTM_Villavicencio.mat`, `LSTM_Predictions_Villavicencio.png`, `LSTM_Comparison_Villavicencio.png`


## 4. Results: Cities Article

Results for the three cities in CSV format

**Results Control Cities:**
- `Results_Control_SEIR_Neiva_Data.csv`
- `Results_Control_SEIR_Neiva_Metrics.csv`
- `Results_Control_SEIR_Monteria_Data.csv`
- `Results_Control_SEIR_Monteria_Data.Metrics`
- `Results_Control_SEIR_Villavicencio_Data.csv`
- `Results_Control_SEIR_Villavicencio_Metrics.csv`
- `Results_Efficacy_Control_Neiva_Data.csv`
- `Results_Efficacy_Control_Neiva_Metrics.csv`
- `Results_Efficacy_Control_Monteria_Data.csv`
- `Results_Efficacy_Control_Monteria_Data.Metrics`
- `Results_Efficacy_Control_Villavicencio_Data.csv`
- `Results_Efficacy_Control_Villavicencio_Metrics.csv` 

---

## 5. Output Files Description

**Data Processing Outputs:**
- `Results_Dataset_Villavicencio.mat` → Processed epidemiological data: `fecha`, `expuestos`, `infectados`, `recuperados`, `muertos`, `infectados_activos`
- `imputation_statistics_villavicencio.mat` → Statistics: `n_original_cases`, `n_imputed_recoveries`, `n_imputed_symptom_dates`, `total_infected`, `total_recovered`, `total_deaths`
- `imputation_report_villavicencio.txt` → Text report with detailed imputation summary

**SEIR Control Outputs:**
- `Results_Control_SEIR_Villavicencio.mat` → `I_real`, `I_seir`, `S_seir`, `E_seir`, `u_opt`, `beta_opt`, `R0_opt`, `metrics` (RMSE, MAE, MAPE, R², correlation)
- `Control_SEIR_Villavicencio.png` → Two subplots: Data vs model fit with R² value, effective reproduction number over time

**Efficacy Analysis Outputs:**
- `Results_Efficacy_Control_Villavicencio.mat` → `C`, `eta`, `percentage_R0_less_1`, `u_max`, `mean_inertia`, `J`, `I_real`, `I_model`, `u_opt`, `R0_t`, `eta_cum`
- `Efficacy_Analysis_Control_Villavicencio.png` → 9 subplots: Infected comparison, control effort, efficiency, R₀, inertia, cost-benefit, control vs reduction, distribution, metrics summary
- `Weight_Sensitivity.png` → 3D surface plot of J(w₁,w₂) sensitivity analysis

**Hybrid Model Outputs:**
- `Results_Hybrid_Villavicencio.mat` → `t`, `I_real`, `y_train`, `y_test`, `pred_*_train`, `pred_*_test`, `metrics_*`, `feature_names`, `importance_rf`, `importance_xgb`
- `Hybrid_Models_Comparison_Villavicencio.png` → 4 subplots: Complete series predictions, feature importance, RMSE comparison, prediction vs real scatter
- `Hybrid_Error_Analysis_Villavicencio.png` → 2 subplots: Absolute error over time, error distribution

**Gain Analysis Outputs:**
- `Results_Gain_Hybrid_Villavicencio.mat` → `improvement_RMSE`, `improvement_MAE`, `improvement_R2`, `improvement_by_phase`, `robustness`, `stability`, `phases`
- `Hybrid_Gain_Analysis_Villavicencio.png` → 9 subplots: Global improvement, phase gain, robustness, stability, peak vs quiet errors, temporal error evolution, error distribution, improvement matrix, executive summary

**LSTM Outputs:**
- `Results_LSTM_Villavicencio.mat` → `predictions`, `actual_values`, `rmse`, `mae`, `mape`, `r2`, `network_architecture`, `training_options`
- `LSTM_Predictions_Villavicencio.png` → Time series plot showing actual vs predicted values with confidence intervals
- `LSTM_Comparison_Villavicencio.png` → Comparative visualization between LSTM predictions and hybrid model results

---

## 6. Contact

For questions, issues, or suggestions:

- **GitHub Issues:** [https://github.com/germanescobar-1/hybrid-modeling-framework](https://github.com/germanescobar-1/hybrid-modeling-framework)
- **Email:** [german.escobar@usco.edu.co](mailto:german.escobar@usco.edu.co)
