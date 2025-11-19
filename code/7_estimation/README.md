# Preference Estimation Framework

This folder contains the estimation framework for analyzing preferences over joint allocations in the siblings school choice project.

## Overview

The estimation uses survey data on preferences over joint allocations to estimate structural parameters using an exploded logit model. Each pair (i,j) is assumed to have an idiosyncratic preference shock following a Type-1 extreme value distribution.

## Folder Structure

```
7_estimation/
├── results/                 # Parameter estimates and output files
├── 2_likelihood.py         # Likelihood function implementation
├── 3_estimation.py         # Maximum likelihood estimation
├── 4_results_table.py      # Parameter presentation
├── requirements.txt        # Python dependencies
├── Makefile               # Automated execution pipeline
└── README.md              # This file
```

**Note:** Data files (`survey_responses.csv`, `marginal_applications_older.csv`, `marginal_applications_younger.csv`) should be located in `../../data/` directory.

## Scripts Description

### 1. `2_likelihood.py`
Implements the exploded logit likelihood function for preferences over joint allocations, assuming Type-1 extreme value idiosyncratic preference shocks.

### 2. `3_estimation.py`
Performs maximum likelihood estimation by optimizing the joint log-likelihood function and saves parameter estimates.

### 3. `4_results_table.py`
Reads estimated parameters and formats them into publication-ready tables.

## Usage

### Quick Start
Run the entire estimation pipeline:
```bash
make all
```

### Individual Scripts
Run scripts individually:
```bash
python 3_estimation.py
python 4_results_table.py
```

## Dependencies

Install required Python packages:
```bash
pip install -r requirements.txt
```

## Data Requirements

The estimation requires the following data files in `../../data/`:
- `survey_responses.csv` - Joint allocation scenarios with covariates
- `marginal_applications_older.csv` - Complete application list for older siblings
- `marginal_applications_younger.csv` - Complete application list for younger siblings

See `../../data/survey_responses_CODEBOOK.md` for variable documentation.

## Output Files

- `results/parameter_estimates.csv` - Estimated parameters
- `results/estimation_summary.txt` - Estimation summary statistics
- `results/parameter_table.tex` - LaTeX formatted parameter table