================================================================================
        					INSTRUCTIONS FOR USE 
================================================================================

AUTHORS: [Germán Fabian Escobar Fiesco / Surcolombiana University]
DATE: March 2026
VERSION: 1.0

================================================================================
TABLE OF CONTENTS
================================================================================

1.  PROJECT OVERVIEW
2.  REPOSITORY STRUCTURE
3.  EXECUTION WORKFLOW MATLAB CODE VILLAVICENCIO
4.  EXECUTION WORKFLOW RESULTS THREE CITIES
5.  OUTPUT FILES DESCRIPTION

================================================================================
1. PROJECT OVERVIEW
================================================================================

This repository contains MATLAB code for the paper: A Hybrid Framework Integrating an Optimal SEIR 
Control Model with Supervised Learning for Analyzing SARS-CoV-2 Coronavirus Data in Small Urban 
Settings 

================================================================================
2. REPOSITORY STRUCTURE
================================================================================

Repository/
│
├── Instructions.txt                           				# This file
│
├── Matlab_Code_Villavicencio/                			# Main code for Villavicencio
│   ├── Dataset_Villavicencio.m                			# Data preprocessing
│   ├── Control_SEIR_Villavicencio.m           		# SEIR control model estimation
│   ├── Analysis_Efficacy_Control_Villavicencio.m  	# Control efficacy analysis
│   ├── ML_Hybrid_SEIR_Villavicencio.m         		# Hybrid model training
│   ├── Analysis_Profit_Hybrid_Villavicencio.m    		# Hybrid model gain analysis
│   ├── LSTM_Advanced_Features.m               		# LSTM implementation
│   └── RawData_Villavicencio.xlsx             			# Raw epidemiological data
│
├── Results_Control_SEIR_Three_Cities/         		# SEIR control results
│   ├── Results_Control_SEIR_Neiva.mat
│   ├── Results_Control_SEIR_Monteria.mat
│   ├── Results_Control_SEIR_Villavicencio.mat
│   ├── Results_Efficacy_Control_Neiva.mat
│   ├── Results_Efficacy_Control_Monteria.mat
│   ├── Results_Efficacy_Control_Villavicencio.mat
│
├── Results_Hybrid_Three_Cities_60-40/         		# Hybrid results (60% train, 40% test)
│   ├── Results_Hybrid_Neiva.mat
│   ├── Results_Hybrid_Monteria.mat
│   ├── Results_Hybrid_Villavicencio.mat
│   ├── Results_Gain_Hybrid_Neiva.mat
│   ├── Results_Gain_Hybrid_Monteria.mat
│   └── Results_Gain_Hybrid_Villavicencio.mat
│
└── Results_Hybrid_Three_Cities_70-30/         		# Hybrid results (70% train, 30% test)
    ├── Results_Hybrid_Neiva.mat
    ├── Results_Hybrid_Monteria.mat
    ├── Results_Hybrid_Villavicencio.mat
    ├── Results_Gain_Hybrid_Neiva.mat
    ├── Results_Gain_Hybrid_Monteria.mat
    └── Results_Gain_Hybrid_Villavicencio.mat

================================================================================
3. EXECUTION WORKFLOW MATLAB CODE VILLAVICENCIO
================================================================================

3.1 Complete Pipeline Execution
-------------------------------
Execute the following scripts in order (from Matlab_Code_Villavicencio folder):

STEP 1: Data Processing
------------------------
>> Dataset_Villavicencio

Input File: RawData_Villavicencio.xlsx

This creates:
  • Results_Dataset_Villavicencio.mat
  • imputation_statistics_villavicencio.mat
  • imputation_report_villavicencio.txt
  • Two figures showing epidemic dynamics

STEP 2: SEIR Control Model Estimation
-------------------------------------
>> Control_SEIR_Villavicencio

Input File: Results_Dataset_Villavicencio.mat

This creates:
  • Results_Control_SEIR_Villavicencio.mat
  • Control_SEIR_Villavicencio.png

STEP 3: Control Efficacy Analysis
---------------------------------
>> Analysis_Efficacy_Control_Villavicencio

Input File: Results_Control_SEIR_Villavicencio.mat

This creates:
  • Results_Efficacy_Control_Villavicencio.mat
  • Efficacy_Analysis_Control_Villavicencio.png
  • Weight_Sensitivity.png

STEP 4: Hybrid Model Training
-----------------------------
>> ML_Hybrid_SEIR_Villavicencio

Input Files: Results_Efficacy_Control_Villavicencio.mat

This creates:
  • Results_Hybrid_Villavicencio.mat
  • Hybrid_Models_Comparison_Villavicencio.png
  • Hybrid_Error_Analysis_Villavicencio.png

STEP 5: Hybrid Model Gain Analysis
----------------------------------
>> Analysis_Gain_Hybrid_Villavicencio

Input File: 
  • Results_Hybrid_Villavicencio.mat
  • Results_Control_SEIR_Villavicencio.mat

This creates:
  • Results_Gain_Hybrid_Villavicencio.mat
  • Hybrid_Gain_Analysis_Villavicencio.png

================================================================================
4. EXECUTION WORKFLOW RESULTS THREE CITIES
================================================================================

4.1 Execution results
-------------------------------

CASE 1: Control and Efficacy
-------------------------------

Execute the following scripts (from Results_Control_Three_Cities folder):

>> load(‘Results_Control_SEIR_Neiva.mat')
>> load(‘Results_Control_SEIR_Monteria.mat')
>> load(‘Results_Control_SEIR_Villavicencio.mat')

>> load('Results_Efficacy_Control_Neiva.mat')
>> load('Results_Efficacy_Control_Monteria.mat')
>> load('Results_Efficacy_Control_Villavicencio.mat')

CASE 2: Hybrid Models and Gain Three Cities (Dataset 60-40%)
-------------------------------

Execute the following scripts (from Results_Hybrid_Three_Cities_60-40 folder):

>> load('Results_Hybrid_Neiva.mat')
>> load('Results_Hybrid_Monteria.mat')
>> load('Results_Hybrid_Villavicencio.mat')

>> load('Results_Gain_Hybrid_Neiva.mat')
>> load('Results_Gain_Hybrid_Monteria.mat')
>> load('Results_Gain_Hybrid_Villavicencio.mat')

CASE 3: Hybrid Models and Gain Three Cities (Dataset 70-30%)
-------------------------------

Execute the following scripts (from Results_Hybrid_Three_Cities_60-40 folder):

>> load('Results_Hybrid_Neiva.mat')
>> load('Results_Hybrid_Monteria.mat')
>> load('Results_Hybrid_Villavicencio.mat')

>> load('Results_Gain_Hybrid_Neiva.mat')
>> load('Results_Gain_Hybrid_Monteria.mat')
>> load('Results_Gain_Hybrid_Villavicencio.mat')

================================================================================
5. OUTPUT FILES DESCRIPTION
================================================================================

5.1 Data Processing Outputs
---------------------------
Results_Dataset_Villavicencio.mat
  • Structure containing processed epidemiological data:
    - fecha: Date vector
    - expuestos: Daily exposed cases
    - infectados: Daily infected cases
    - recuperados: Daily recovered cases
    - muertos: Daily deaths
    - infectados_activos: Active infected cases

imputation_statistics_villavicencio.mat
  • Statistics about imputed data:
    - n_original_cases: Total cases in raw data
    - n_imputed_recoveries: Number of imputed recovery dates
    - n_imputed_symptom_dates: Number of imputed symptom dates
    - total_infected, total_recovered, total_deaths

imputation_report_villavicencio.txt
  • Text report with detailed imputation summary

5.2 SEIR Control Outputs
------------------------
Results_Control_SEIR_Villavicencio.mat
  • Structure containing:
    - I_real: Observed incidence
    - I_seir: Model-predicted incidence
    - S_seir: Susceptible population
    - E_seir: Exposed population
    - u_opt: Optimal control intensity (daily)
    - beta_opt: Time-varying transmission rate
    - R0_opt: Effective reproduction number
    - metrics: RMSE, MAE, MAPE, R², correlation

Control_SEIR_Villavicencio.png
  • Two subplots:
    - Data vs model fit with R² value
    - Effective reproduction number over time

5.3 Efficacy Analysis Outputs
-----------------------------
Results_Efficacy_Control_Villavicencio.mat
  • Structure with efficacy metrics:
    - metrics.C: Total control load
    - metrics.eta: Control efficiency
    - metrics.percentage_R0_less_1: Time with R₀ < 1
    - metrics.u_max: Peak control
    - metrics.mean_inertia: Control inertia
    - metrics.J: Cost-benefit functional
    - I_real, I_model, u_opt, R0_t, eta_cum

Efficacy_Analysis_Control_Villavicencio.png
  • 9 subplots showing:
    - Infected comparison with peak reduction
    - Control effort over time
    - Instantaneous control efficiency
    - Effective reproduction number
    - Control inertia
    - Cost-benefit components
    - Control vs reduction relationship
    - Control distribution
    - Metrics summary

Weight_Sensitivity.png
  • 3D surface plot of J(w₁,w₂) sensitivity analysis

5.4 Hybrid Model Outputs
------------------------
Results_Hybrid_Villavicencio.mat
  • Structure containing:
    - t: Time vector
    - I_real: Real infected cases
    - y_train, y_test: Training/testing targets
    - pred_*_train, pred_*_test: Predictions for each model
    - metrics_*: Performance metrics for each model
    - feature_names: Names of features used
    - importance_rf, importance_xgb: Feature importance

Hybrid_Models_Comparison_Villavicencio.png
  • 4 subplots showing:
    - Complete series predictions
    - Feature importance
    - RMSE comparison
    - Prediction vs real scatter plot

Hybrid_Error_Analysis_Villavicencio.png
  • 2 subplots:
    - Absolute error over time
    - Error distribution

5.5 Gain Analysis Outputs
-------------------------
Results_Gain_Hybrid_Villavicencio.mat
  • Structure containing:
    - improvement_RMSE, improvement_MAE, improvement_R2
    - improvement_by_phase: Phase-specific improvements
    - robustness: Peak/quiet period performance
    - stability: Cross-validation error variance
    - phases: Growth, plateau, decline indices

Hybrid_Gain_Analysis_Villavicencio.png
  • 9 subplots showing:
    - Global improvement comparison
    - Phase gain for ensemble
    - Model robustness comparison
    - Stability comparison
    - Peak vs quiet errors
    - Temporal error evolution
    - Error distribution
    - Improvement matrix
    - Executive summary


================================================================================
CONTACT
================================================================================

For questions, issues, or suggestions:
  • GitHub Issues: [https://github.com/germanescobar-1/hybrid-modeling-framework]
  • Email: [german.escobar@usco.edu.co]

================================================================================
END OF INSTRUCTIONS
================================================================================
