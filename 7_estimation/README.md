# Preference Estimation Framework

This folder contains the estimation framework for analyzing preferences over joint allocations in the siblings school choice project.

## Overview

The estimation uses survey data on preferences over joint allocations to estimate structural parameters using an exploded logit model. Each pair (i,j) is assumed to have an idiosyncratic preference shock following a Type-1 extreme value distribution.

## Folder Structure

```
7_estimation/
├── data/                    # Processed data files
├── results/                 # Parameter estimates and output files
├── figures/                 # Generated plots and visualizations
├── 1_load_data.py          # Data loading and preprocessing
├── 2_likelihood.py         # Likelihood function implementation
├── 3_estimation.py         # Maximum likelihood estimation
├── 4_results_table.py      # Parameter presentation
├── 5_simulation.py         # Simulation and visualization
├── requirements.txt        # Python dependencies
├── Makefile               # Automated execution pipeline
└── README.md              # This file
```

## Scripts Description

### 1. `1_load_data.py`
Loads and formats survey response data for preference estimation. Processes the survey data from the questionnaires folder and creates a clean dataset for likelihood evaluation.

### 2. `2_likelihood.py`
Implements the exploded logit likelihood function for preferences over joint allocations, assuming Type-1 extreme value idiosyncratic preference shocks.

### 3. `3_estimation.py`
Performs maximum likelihood estimation by optimizing the joint log-likelihood function and saves parameter estimates.

### 4. `4_results_table.py`
Reads estimated parameters and formats them into publication-ready tables.

### 5. `5_simulation.py`
Uses estimated parameters and data covariates to simulate preference distributions and creates summary visualizations.

## Usage

### Quick Start
Run the entire estimation pipeline:
```bash
make all
```

### Individual Scripts
Run scripts individually:
```bash
python 1_load_data.py
python 2_likelihood.py
python 3_estimation.py
python 4_results_table.py
python 5_simulation.py
```

## Dependencies

Install required Python packages:
```bash
pip install -r requirements.txt
```

## Data Requirements

The estimation requires survey data on preferences over joint allocations. If original data is not available, the scripts will generate synthetic data for testing purposes.

## Output Files

- `results/parameter_estimates.csv` - Estimated parameters
- `results/estimation_summary.txt` - Estimation summary statistics
- `results/parameter_table.tex` - LaTeX formatted parameter table
- `figures/preference_distribution.png` - Simulated preference distributions
- `figures/covariate_effects.png` - Covariate effect visualizations