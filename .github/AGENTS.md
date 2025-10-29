# CB-Siblings: Chilean School Assignment System Analysis

**ALWAYS reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.**

Research project analyzing Chilean school assignment system (SAE) with focus on sibling priorities in joint applications. Uses Stata for data processing, Python for simulations, and Jupyter notebooks for analysis.

## Core Development Rules

### Team Member Mentions
When tagging or assigning GitHub issues to team members, ALWAYS use these handles:
- **Javiera Gazmuri** (@javieragazmuri)
- **Tomas Larroucau** (@tlarroucau)
- **Ignacio Rios** (@iriosu)
- **Chris Neilson** (@christopherneilson)

### Data Handling: NEVER Hard-Code Data
**CRITICAL RULE:** Do not hard-code data directly in tables, scripts, or code files.

**Required Approach:**
- ALL data must be loaded from external source files (CSV, Excel, Stata .dta files, etc.)
- Tables, figures, and analyses must dynamically pull data from source files
- Use path variables defined in `0_main.do` (e.g., `${pathData}`, `${pathData_survey}`)
- If creating test data, save it to a file first, then load it

**Examples:**

❌ **WRONG** (Hard-coded data):
```python
# Never do this
data = {
    'school_id': [1, 2, 3],
    'capacity': [100, 150, 200]
}
df = pd.DataFrame(data)
```

✅ **CORRECT** (Source-based):
```python
# Always do this
import pandas as pd
df = pd.read_csv(f"{path_data}/school_capacity.csv")
```

❌ **WRONG** (Hard-coded in Stata):
```stata
* Never do this
input school_id capacity
1 100
2 150
end
```

✅ **CORRECT** (Source-based in Stata):
```stata
* Always do this
use "${pathData}/school_capacity.dta", clear
```

❌ **WRONG** (Hard-coded LaTeX table):
```latex
\begin{tabular}{cc}
School & Capacity \\
1 & 100 \\
2 & 150 \\
\end{tabular}
```

✅ **CORRECT** (Generated from data):
```python
# Generate table from data
df = pd.read_csv("schools.csv")
df.to_latex("output_table.tex", index=False)
```

**Why this matters:**
- Data updates automatically when source files change
- Reproducibility and transparency
- Reduces errors from manual data entry
- Easier to audit and verify results

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
0_main.do           # Stata configuration and paths (ENTRY POINT - sets all ${pathData} globals)
1_feedback/         # Probability calculations and feedback analysis  
2_surveys/          # Survey data processing
3_analysis/         # Main analysis (regular and complementary periods)
  ├── 1_regular_period/      # Regular admission cycle analysis
  └── 2_complementary_period/ # Complementary admission cycle analysis
4_reports/          # Generated reports for different audiences
  ├── diagnostic/   # Exploratory and diagnostic reports
  ├── mineduc/      # Reports for Chilean Ministry of Education
  ├── preliminar/   # Early-stage findings
  ├── surveys/      # Survey-specific reports
  └── yale/         # Academic presentations
5_paper/            # Academic paper production
  ├── 1_clean/      # Data cleaning for paper
  ├── 2_analysis/   # Final analysis for paper results
  └── 3_simulations/ # Counterfactual simulations
6_model/            # Model documentation and presentations
7_estimation/       # Structural preference parameter estimation (Python)
```

### Code Quality Standards
- Write clean, well-documented code with explanatory comments
- Follow the numbered folder structure for sequential analysis
- Use descriptive variable names that match domain concepts
- Include error handling for missing data files
- Document expected input file locations and formats
- Test scripts incrementally rather than running entire pipelines

### Running Analysis
- **Entry Point:** Start with `0_main.do` - sets global paths (${pathData}, ${pathData_survey}, etc.) and graph styles
- **Workflow:** Numbered directories (0-7) represent sequential analysis stages
- **Path Variables:** Always use globals from `0_main.do` - never hard-code file paths
- **Key Stata Files:**
  - Data cleaning: `1_feedback/preliminar/1_cleaning_for_probabilities.do`
  - Analysis: `3_analysis/1_regular_period/1_preliminar_analysis.do`
  - Paper results: `5_paper/2_analysis/*.do`
- **Key Python Files:**
  - Probability calculations: `1_feedback/preliminar/2_probabilities.ipynb`
  - Simulations: `3_analysis/1_regular_period/2_simulations/3_simulations.py`
  - Preference estimation: `7_estimation/3_estimation.py`

### Data Access Patterns
**Always load data from source files:**
```stata
* Stata pattern
use "${pathData}/applications_2023.dta", clear
import delimited "${pathData_survey}/responses.csv", clear
```

```python
# Python pattern
import pandas as pd
import os

# Use path variables
path_data = "/path/to/data"  # Should come from config or environment
df = pd.read_csv(f"{path_data}/applications.csv")

# Or for Jupyter notebooks in this project
df = pd.read_csv("../../data/applications.csv")  # Relative paths OK if documented
```

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
global pathData "$main_siblings/data"

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
- **Domain:** Chilean school assignment system (Sistema de Admisión Escolar - SAE)
- **Focus:** Impact of sibling priority policies on family application strategies and student allocations
- **Data:** Administrative records from Chilean school applications (confidential, not in repository)
- **Methods:** 
  - Causal inference and econometric analysis
  - Deferred acceptance algorithm simulations
  - Structural estimation of family preferences
  - Counterfactual policy analysis
- **Output:** 
  - Academic paper for publication
  - Policy reports for Chilean Ministry of Education (MINEDUC)
  - Presentations for academic and policy audiences

## Best Practices for AI Agents

### When Creating New Scripts
1. **Always include data loading section** with clear file path expectations
2. **Document required input files** at top of script
3. **Use path variables** defined in `0_main.do` or pass as arguments
4. **Include error handling** for missing files
5. **Save outputs to files** rather than printing to console (for reproducibility)

### When Modifying Existing Code
1. **Check current data sourcing patterns** before making changes
2. **Maintain consistency** with existing path variable usage
3. **Preserve comments** explaining data structure and business logic
4. **Test imports** before complex transformations

### When Creating Tables or Figures
1. **Source data from files** - never hard-code values
2. **Save outputs to files** (CSV for tables, PNG/PDF for figures)
3. **Document data sources** in figure/table captions or comments
4. **Use consistent naming** (e.g., `table_1_descriptives.tex`, `figure_2_allocations.png`)

### When Reviewing Code
1. **Flag hard-coded data** as violations of project standards
2. **Suggest data file sources** for any manual values
3. **Check path variable usage** matches `0_main.do` definitions
4. **Verify reproducibility** - could another researcher run this?

## Troubleshooting
- **FileNotFoundError:** Expected due to missing proprietary data - suggest creating mock data file
- **ImportError cb_da:** Expected due to custom package not in PyPI - document this limitation
- **Stata errors:** Stata not available in this environment - review code structure instead
- **Path errors:** Hardcoded paths for original researcher's environment - use path variables from `0_main.do`
- **Hard-coded data found:** Flag as violation - suggest loading from CSV/DTA file instead

### Creating Mock Data for Testing
When actual data is unavailable, create realistic mock data files:

```python
# Example: Create mock school capacity data
import pandas as pd

mock_data = pd.DataFrame({
    'school_id': range(1, 101),
    'capacity': np.random.randint(50, 300, 100),
    'sibling_priority': np.random.choice([True, False], 100)
})

# Save to file (don't use directly in code!)
mock_data.to_csv('data/mock_school_capacity.csv', index=False)

# Then load it properly
df = pd.read_csv('data/mock_school_capacity.csv')
```

Always validate that basic Python data manipulation works before attempting complex analysis. Focus on code structure and logic rather than execution results when core dependencies are missing.

## Quick Reference: Common Violations

### ❌ What NOT to Do
```python
# Hard-coded data
df = pd.DataFrame({'col': [1, 2, 3]})

# Hard-coded paths
df = pd.read_csv('/Users/javieragazmuri/Dropbox/data.csv')

# Hard-coded parameters in tables
print(f"Total schools: 150")  # Should come from data
```

### ✅ What TO Do
```python
# Load from source
df = pd.read_csv(f"{data_path}/source_data.csv")

# Use path variables
df = pd.read_csv(f"${pathData}/applications.csv")

# Calculate from data
total_schools = len(df['school_id'].unique())
print(f"Total schools: {total_schools}")
```

## GitHub Issue Management
- Tag @javieragazmuri for questions about Chilean education system, policy context, or data interpretation
- Tag @hadiazt for questions about algorithms, structural estimation, or theoretical modeling
- Always provide context: folder location, file names, specific error messages
- Reference this AGENTS.md file when suggesting code changes to ensure compliance