# CB-Siblings: Chilean School Assignment System Analysis

Research project analyzing the Chilean school assignment system (SAE) with focus on sibling priorities in joint applications. This project examines how sibling priority policies affect family application strategies and student allocations in Chile's centralized school choice system.

## Project Overview

This repository contains code and analysis for studying joint sibling applications in the Chilean Centralized Assignment System (Sistema de Admisión Escolar - SAE). The project uses administrative data, surveys, and simulations to understand the impact of sibling priority policies on family decision-making and school allocations.

## Repository Structure

### Root Level Folders

#### **`code/`** - All Analysis Code
Contains all Stata, Python, and R scripts organized by analysis stage (see below for subfolders).

#### **`data/`** - Processed Data
Contains cleaned and processed datasets used in analysis. Raw administrative data is stored separately in Dropbox due to confidentiality.

#### **`paper/`** - Paper Documents
LaTeX files, figures, and model documentation for the academic paper:
- **`documents/`** - LaTeX source files and paper drafts
- **`model/`** - Model documentation and slides

#### **`results/`** - Analysis Outputs
Generated results, tables, and figures from analysis scripts.

### Code Organization (`code/` folder)

All code is organized in numbered folders representing the analysis pipeline:

#### **`code/0_main.do`** (if exists) or path configuration
Main Stata configuration file that sets up global paths and graph styles. This is the entry point for running Stata scripts.

#### **`code/1_feedback/`** - Feedback and Probability Analysis
Scripts for calculating assignment probabilities and analyzing feedback provided to families during the application process.

#### **`code/2_surveys/`** - Survey Data Processing
Processes survey responses from families about their preferences over joint allocations. This data is used to understand family preferences and validate model assumptions.
- **`questionaries/`** - Survey instruments (PDF)

#### **`code/3_analysis/`** - Main Analysis
Primary analysis folder containing:
- **`1_regular_period/`** - Analysis of the regular application period
- **`2_complementary_period/`** - Analysis of the complementary application period

Each period includes data cleaning, descriptive analysis, and counterfactual simulations using deferred acceptance algorithms.

#### **`code/4_reports/`** - Generated Reports
Output reports and presentations for different audiences:
- **`diagnostic/`** - Diagnostic reports and exploratory analysis
- **`mineduc/`** - Reports for Chilean Ministry of Education
- **`preliminar/`** - Preliminary findings
- **`surveys/`** - Survey-specific reports
- **`yale/`** - Academic presentations

#### **`code/5_paper/`** - Academic Paper Production
Scripts for producing the academic paper:
- **`1_clean/`** - Data cleaning specific to paper analysis
- **`2_analysis/`** - Final analysis code for paper results
- **`3_simulations/`** - Simulation code for paper counterfactuals

#### **`code/6_model/`** - Model Documentation
Documentation of the theoretical model and presentations explaining the allocation mechanism and policy counterfactuals.

#### **`code/7_estimation/`** - Preference Estimation
Framework for estimating structural preference parameters using survey data. Implements exploded logit models to estimate preferences over joint sibling allocations. See `code/7_estimation/README.md` for detailed documentation.

## Workflow

1. **Setup**: Run `0_main.do` to configure paths and settings
2. **Data Processing**: Process feedback data (`1_feedback/`) and survey responses (`2_surveys/`)
3. **Analysis**: Run period-specific analysis in `3_analysis/`
4. **Estimation**: Estimate preference parameters in `7_estimation/`
5. **Paper Production**: Generate final results in `5_paper/`
6. **Reporting**: Create audience-specific reports in `4_reports/`

## Technologies

- **Stata**: Primary tool for data processing and econometric analysis
- **Python**: Used for simulations, probability calculations, and preference estimation
- **Jupyter Notebooks**: Interactive analysis and exploration
- **LaTeX**: Academic paper and table production

## Key Methods

- **Deferred Acceptance Algorithms**: Simulating school assignment mechanisms
- **Causal Inference**: Identifying effects of sibling priority policies
- **Structural Estimation**: Estimating family preferences from survey data
- **Counterfactual Simulations**: Analyzing alternative policy scenarios

## Data

This project uses confidential administrative data from the Chilean Ministry of Education. Data files are not included in this repository.

## Research Team

- **Javiera Gazmuri** (@javieragazmuri)
- **Tomas Larroucau** (@tlarroucau)
- **Ignacio Rios** (@iriosu)
- **Chris Neilson** (@christopherneilson)
 

ConsiliumBots - Educational Policy Research
