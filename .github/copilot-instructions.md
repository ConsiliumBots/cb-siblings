# CB-Siblings: Chilean School Assignment System Analysis

**ALWAYS reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.**

Research project analyzing Chilean school assignment system (SAE) with focus on sibling priorities in joint applications. Uses Stata for data processing, Python for simulations, and Jupyter notebooks for analysis.

## Working Effectively

### Environment Setup
- **Python Setup (takes 3 minutes):**
  - `pip install pandas numpy matplotlib jupyter` -- takes ~3 minutes. NEVER CANCEL.
  - Additional packages available: `pip install plotly seaborn scikit-learn`
  - Test installation: `python3 -c "import pandas, numpy, matplotlib, jupyter; print('All packages working')"`
- **Missing Dependencies:**
  - `cb_da` and `schoolchoice_da` packages are NOT available on PyPI
  - These are custom ConsiliumBots packages for deferred acceptance algorithms
  - Simulation scripts will fail without these packages - this is expected
  - Alternative: create mock implementations for testing workflow

### Project Structure
```
0_main.do           # Stata configuration and paths (entry point)
1_feedback/         # Probability calculations and feedback analysis  
2_surveys/          # Survey data processing
3_analysis/         # Main analysis (regular and complementary periods)
4_reports/          # Generated reports for different audiences
5_paper/            # Academic paper production
6_model/            # Model documentation
```

### Running Analysis
- **Entry Point:** Start with `0_main.do` - sets global paths and graph styles
- **Workflow:** Numbered directories represent sequential analysis stages
- **Key Stata Files:**
  - Data cleaning: `1_feedback/preliminar/1_cleaning_for_probabilities.do`
  - Analysis: `3_analysis/1_regular_period/1_preliminar_analysis.do`
- **Key Python Files:**
  - Probability calculations: `1_feedback/preliminar/2_probabilities.ipynb`
  - Simulations: `3_analysis/1_regular_period/2_simulations/3_simulations.py`

### Testing and Validation
- **Jupyter Testing:**
  - `jupyter --version` to verify installation
  - `jupyter notebook --no-browser --allow-root --port=8888` -- starts in 5 seconds
  - Convert notebooks to Python: `jupyter nbconvert --to script file.ipynb`
- **Python Testing:**
  - Basic functionality works: pandas, numpy, matplotlib
  - Path issues expected: hardcoded paths to `/Users/javieragazmuri/ConsiliumBots Dropbox/`
  - Data files not included in repository - expect FileNotFoundError
- **Stata Testing:**  
  - Stata is NOT available in this environment - commercial software
  - `.do` files cannot be executed directly
  - Use for code review and understanding workflow only

## Limitations

### What DOES NOT Work
- **Stata execution:** Commercial software not available
- **Data access:** Hardcoded paths to proprietary research data not in repository
- **Custom simulations:** `cb_da`/`schoolchoice_da` packages not publicly available
- **Full workflow execution:** Missing data and dependencies prevent complete runs

### What WORKS for Development
- **Code review:** All Stata and Python code can be examined
- **Structure analysis:** Complete project organization can be understood
- **Python environment:** pandas, numpy, matplotlib, jupyter fully functional
- **Jupyter notebooks:** Can be converted to Python scripts and analyzed
- **Basic Python testing:** Import statements, syntax checking, mock implementations

## Common Tasks

### Examining Code
```bash
# View Stata main configuration
cat 0_main.do

# Find all analysis files
find . -name "*.do" | head -10
find . -name "*.py" | head -10  
find . -name "*.ipynb" | head -5

# Convert Jupyter notebook to Python
jupyter nbconvert --to script 1_feedback/preliminar/2_probabilities.ipynb
```

### Project Navigation
```bash
# Repository structure
ls -la
# 0_main.do  1_feedback  2_surveys  3_analysis  4_reports  5_paper  6_model

# Analysis workflow
ls 3_analysis/1_regular_period/
# 1_preliminar_analysis.do  2_simulations/

# Reports and outputs  
ls 4_reports/
# diagnostic  mineduc  preliminar  surveys  yale
```

### Understanding Dependencies
- **Stata packages:** Standard econometric analysis capabilities expected
- **Python custom packages:**
  - `cb_da.da()` - Deferred acceptance algorithm implementation
  - Input format: vacancies, applicants, applications, priority_profiles, etc.
  - Used in files: `3_simulations.py`, `2_simulations.py`

## File Contents Reference

### Repository Root
```
ls -a
.git  .DS_Store  0_main.do  README.md  1_feedback  2_surveys  3_analysis  4_reports  5_paper  6_model
```

### Key Configuration (0_main.do)
```stata
// Sets paths based on username (hardcoded for specific researcher)
global main_silings =  "/Users/javieragazmuri/ConsiliumBots Dropbox/..."
global pathData "$main_silings/data"

// Graph styling configuration
grstyle init
grstyle color background white
```

### Sample Python Analysis Pattern
```python
# Standard imports that work
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Custom import that will fail
from cb_da import da  # Not available

# Expected data structure
vacancies = pd.read_csv('vacancies.csv')
applications = pd.read_csv('applications.csv')
# etc.
```

## Research Context
- **Domain:** Chilean school assignment system (Sistema de Admisión Escolar)
- **Focus:** Impact of sibling priority policies on family applications  
- **Data:** Administrative records from school applications
- **Methods:** Causal inference, simulation of counterfactual policies
- **Output:** Academic paper and policy reports for Chilean Ministry of Education

## Troubleshooting
- **FileNotFoundError:** Expected due to missing proprietary data
- **ImportError cb_da:** Expected due to custom package not in PyPI  
- **Stata errors:** Stata not available in this environment
- **Path errors:** Hardcoded paths for original researcher's environment

Always validate that basic Python data manipulation works before attempting complex analysis. Focus on code structure and logic rather than execution results when core dependencies are missing.