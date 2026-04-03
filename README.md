# Instructions for Use

**Authors:** Germán Fabian Escobar Fiesco / Surcolombiana University  
**Date:** March 2026  
**Version:** 1.0

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Repository Structure](#2-repository-structure)
3. [Execution Workflow: MATLAB Code Villavicencio](#3-execution-workflow-matlab-code-villavicencio)
4. [Article Results](#4-execution-workflow-results-three-cities)
5. [Contact](#6-contact)

---

## 1. Project Overview

This repository contains MATLAB code for the paper:  
**A Hybrid Framework Integrating an Optimal SEIR Control Model with Supervised Learning for Analyzing SARS-CoV-2 Coronavirus Data in Small Urban Settings**

---

## 2. Repository Structure

| Folder | File |
|---------|----------|
| **Matlab_Code_Villavicencio/** | `Dataset_Villavicencio.m`<br>`Control_SEIR_Villavicencio.m`<br>`Analysis_Efficacy_Control_Villavicencio.m`<br>`ML_Hybrid_SEIR_Villavicencio.m`<br>`Analysis_Profit_Hybrid_Villavicencio.m`<br>`LSTM_Advanced_Features.m`<br>`RawData_Villavicencio.xlsx` |
| **Results_Control_Cities/** | `Results_Control_SEIR_Neiva_Data.csv`<br>`Results_Control_SEIR_Neiva_Metrics.csv`<br>`Results_Control_SEIR_Monteria_Data.csv`<br>`Results_Control_SEIR_Monteria_Data.Metrics`<br>`Results_Control_SEIR_Villavicencio_Data.csv`<br>`Results_Control_SEIR_Villavicencio_Metrics.csv`<br>`Results_Efficacy_Control_Neiva_Data.csv`<br>`Results_Efficacy_Control_Neiva_Metrics.csv`<br>`Results_Efficacy_Control_Monteria_Data.csv`<br>`Results_Efficacy_Control_Monteria_Data.Metrics`<br>`Results_Efficacy_Control_Villavicencio_Data.csv`<br>`Results_Efficacy_Control_Villavicencio_Metrics.csv` |
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

### Running scripts in Matlab:
**Step 1: Data processing** 
  - Command Window: `>> Dataset_Villavicencio` 
  - Inputs: `RawData_Villavicencio.xlsx`
  - Outputs: `Results_Dataset_Villavicencio.mat`, `imputation_statistics_villavicencio.mat`, `imputation_report_villavicencio.txt`, `two figures`

**Step 2: SEIR control model estimation**
  - Command Window: `>> Control_SEIR_Villavicencio`
  - Inputs: `Results_Dataset_Villavicencio.mat`
  - Outputs: `Results_Control_SEIR_Villavicencio.mat`, `Control_SEIR_Villavicencio.png`

**Step 3: Efficacy analysis of the control** 
  - Command Window: `>> Analysis_Efficacy_Control_Villavicencio`
  - Inputs: `Results_Control_SEIR_Villavicencio.mat`
  - Outputs: `Results_Efficacy_Control_Villavicencio.mat`, `Efficacy_Analysis_Control_Villavicencio.png`, `Weight_Sensitivity.png`
    
**Step 4: Hybrid models**
  - Command Window:`>> ML_Hybrid_SEIR_Villavicencio`
  - Function: `LSTM_Advanced_Features`
  - Input: `Results_Efficacy_Control_Villavicencio.mat`
  - Outputs: `Results_Hybrid_Villavicencio.mat`, `Hybrid_Models_Comparison_Villavicencio.png`, `Hybrid_Error_Analysis_Villavicencio.png`
    
**Step 5: Gain analysis of the hybrid models**
  - Command Window:`>> Analysis_Gain_Hybrid_Villavicencio`
  - Inputs: `Results_Hybrid_Villavicencio.mat`, `Results_Control_SEIR_Villavicencio.mat`
  - Outputs: `Results_Gain_Hybrid_Villavicencio.mat`, `Hybrid_Gain_Analysis_Villavicencio.png`

---

## 4. Article Results
CSV format of article results for three cities:

**Results Control:**
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

**Results Hybrid Models Dataset 60-40% :**
- `Results_Hybrid_Monteria_Features.csv`
- `Results_Hybrid_Monteria_Metrics.csv`
- `Results_Hybrid_Monteria_Train.csv`
- `Results_Hybrid_Monteria_Test.csv`
- `Results_Hybrid_Neiva_Features.csv`
- `Results_Hybrid_Neiva_Metrics.csv`
- `Results_Hybrid_Neiva_Train.csv`
- `Results_Hybrid_Neiva_Test.csv`
- `Results_Hybrid_Villavicencio_Features.csv`
- `Results_Hybrid_Villavicencio_Metrics.csv`
- `Results_Hybrid_Villavicencio_Train.csv`
- `Results_Hybrid_Villavicencio_Test.csv`

**Results Hybrid Models Dataset 70-30% :**
- `Results_Hybrid_Monteria_Features.csv`
- `Results_Hybrid_Monteria_Metrics.csv`
- `Results_Hybrid_Monteria_Train.csv`
- `Results_Hybrid_Monteria_Test.csv`
- `Results_Hybrid_Neiva_Features.csv`
- `Results_Hybrid_Neiva_Metrics.csv`
- `Results_Hybrid_Neiva_Train.csv`
- `Results_Hybrid_Neiva_Test.csv`
- `Results_Hybrid_Villavicencio_Features.csv`
- `Results_Hybrid_Villavicencio_Metrics.csv`
- `Results_Hybrid_Villavicencio_Train.csv`
- `Results_Hybrid_Villavicencio_Test.csv`
---

## 5. Contact

For questions, issues, or suggestions:

- **GitHub Issues:** [https://github.com/germanescobar-1/hybrid-modeling-framework](https://github.com/germanescobar-1/hybrid-modeling-framework)
- **Email:** [german.escobar@usco.edu.co](mailto:german.escobar@usco.edu.co)
