# Makefile for Preference Estimation Pipeline
# 
# This Makefile automates the entire preference estimation process
# from data loading through simulation and visualization.

# Python interpreter
PYTHON = python3

# Directories
DATA_DIR = data
RESULTS_DIR = results  
FIGURES_DIR = figures

# Main targets
.PHONY: all clean help install test data estimation results simulation

# Default target - run complete pipeline
all: install data estimation results simulation
	@echo "=========================================="
	@echo "Complete estimation pipeline finished!"
	@echo "=========================================="
	@echo "Check the following directories for outputs:"
	@echo "  - $(DATA_DIR)/     : Processed data files"
	@echo "  - $(RESULTS_DIR)/  : Parameter estimates and tables"
	@echo "  - $(FIGURES_DIR)/  : Plots and visualizations"

# Install Python dependencies
install:
	@echo "Installing Python dependencies..."
	pip install -r requirements.txt
	@echo "Dependencies installed successfully!"

# Step 1: Load and process data
data: $(DATA_DIR)/survey_responses.csv

$(DATA_DIR)/survey_responses.csv:
	@echo "=========================================="
	@echo "Step 1: Loading and processing data..."
	@echo "=========================================="
	$(PYTHON) 1_load_data.py

# Step 2: Run maximum likelihood estimation  
estimation: $(RESULTS_DIR)/parameter_estimates.csv

$(RESULTS_DIR)/parameter_estimates.csv: $(DATA_DIR)/survey_responses.csv
	@echo "=========================================="
	@echo "Step 2: Running maximum likelihood estimation..."
	@echo "=========================================="
	$(PYTHON) 3_estimation.py

# Step 3: Generate results tables
results: $(RESULTS_DIR)/parameter_table.tex

$(RESULTS_DIR)/parameter_table.tex: $(RESULTS_DIR)/parameter_estimates.csv
	@echo "=========================================="
	@echo "Step 3: Generating results tables..." 
	@echo "=========================================="
	$(PYTHON) 4_results_table.py

# Step 4: Run simulations and create visualizations
simulation: $(FIGURES_DIR)/preference_distribution.png

$(FIGURES_DIR)/preference_distribution.png: $(RESULTS_DIR)/parameter_estimates.csv
	@echo "=========================================="
	@echo "Step 4: Running simulations and creating visualizations..."
	@echo "=========================================="
	$(PYTHON) 5_simulation.py

# Test individual components
test-data:
	@echo "Testing data loading module..."
	$(PYTHON) 1_load_data.py

test-likelihood:
	@echo "Testing likelihood function..."
	$(PYTHON) 2_likelihood.py

test-estimation: data
	@echo "Testing estimation (quick run)..."
	$(PYTHON) 3_estimation.py

test-results: estimation
	@echo "Testing results table generation..."
	$(PYTHON) 4_results_table.py

test-simulation: results
	@echo "Testing simulation and visualization..."
	$(PYTHON) 5_simulation.py

# Quick test of entire pipeline with minimal iterations
test: install
	@echo "Running quick test of entire pipeline..."
	$(PYTHON) 1_load_data.py
	$(PYTHON) 2_likelihood.py  
	$(PYTHON) 3_estimation.py
	$(PYTHON) 4_results_table.py
	$(PYTHON) 5_simulation.py
	@echo "Quick test completed successfully!"

# Individual steps (can be run independently)
step1: data
step2: estimation  
step3: results
step4: simulation

# Clean all generated files
clean:
	@echo "Cleaning generated files..."
	rm -rf $(DATA_DIR)/*.csv
	rm -rf $(RESULTS_DIR)/*
	rm -rf $(FIGURES_DIR)/*.png
	rm -rf __pycache__/
	rm -rf *.pyc
	@echo "Clean completed!"

# Clean only results but keep data
clean-results:
	@echo "Cleaning results and figures..."
	rm -rf $(RESULTS_DIR)/*
	rm -rf $(FIGURES_DIR)/*.png
	@echo "Results cleaned!"

# Help target
help:
	@echo "Preference Estimation Pipeline"
	@echo "=============================="
	@echo ""
	@echo "Available targets:"
	@echo "  all          - Run complete estimation pipeline"
	@echo "  install      - Install Python dependencies"
	@echo "  data         - Load and process survey data (Step 1)"
	@echo "  estimation   - Run maximum likelihood estimation (Step 2)"
	@echo "  results      - Generate results tables (Step 3)"  
	@echo "  simulation   - Run simulations and create plots (Step 4)"
	@echo ""
	@echo "Individual steps:"
	@echo "  step1        - Same as 'data'"
	@echo "  step2        - Same as 'estimation'"
	@echo "  step3        - Same as 'results'"
	@echo "  step4        - Same as 'simulation'"
	@echo ""
	@echo "Testing:"
	@echo "  test         - Quick test of entire pipeline"
	@echo "  test-data    - Test data loading only"
	@echo "  test-likelihood - Test likelihood function only"
	@echo "  test-estimation - Test estimation only"  
	@echo "  test-results - Test results generation only"
	@echo "  test-simulation - Test simulation only"
	@echo ""
	@echo "Maintenance:"
	@echo "  clean        - Remove all generated files"
	@echo "  clean-results- Remove results but keep data"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "Example usage:"
	@echo "  make all              # Run complete pipeline"
	@echo "  make step1 step2      # Run first two steps only"
	@echo "  make clean && make test # Clean and run quick test"

# Create necessary directories
$(DATA_DIR) $(RESULTS_DIR) $(FIGURES_DIR):
	mkdir -p $@

# Ensure directories exist before running scripts
$(DATA_DIR)/survey_responses.csv: | $(DATA_DIR)
$(RESULTS_DIR)/parameter_estimates.csv: | $(RESULTS_DIR)
$(RESULTS_DIR)/parameter_table.tex: | $(RESULTS_DIR) 
$(FIGURES_DIR)/preference_distribution.png: | $(FIGURES_DIR)