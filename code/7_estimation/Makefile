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
all: install estimation results
	@echo "=========================================="
	@echo "Complete estimation pipeline finished!"
	@echo "=========================================="
	@echo "Check the following directory for outputs:"
	@echo "  - $(RESULTS_DIR)/  : Parameter estimates and tables"

# Install Python dependencies
install:
	@echo "Installing Python dependencies..."
	pip install -r requirements.txt
	@echo "Dependencies installed successfully!"

# Step 1: Run maximum likelihood estimation  
estimation: $(RESULTS_DIR)/parameter_estimates.csv

$(RESULTS_DIR)/parameter_estimates.csv:
	@echo "=========================================="
	@echo "Step 1: Running maximum likelihood estimation..."
	@echo "=========================================="
	$(PYTHON) 3_estimation.py

# Step 2: Generate results tables
results: $(RESULTS_DIR)/parameter_table.tex

$(RESULTS_DIR)/parameter_table.tex: $(RESULTS_DIR)/parameter_estimates.csv
	@echo "=========================================="
	@echo "Step 2: Generating results tables..." 
	@echo "=========================================="
	$(PYTHON) 4_results_table.py

# Test individual components
test-likelihood:
	@echo "Testing likelihood function..."
	$(PYTHON) 2_likelihood.py

test-estimation:
	@echo "Testing estimation (quick run)..."
	$(PYTHON) 3_estimation.py

test-results: estimation
	@echo "Testing results table generation..."
	$(PYTHON) 4_results_table.py

# Quick test of entire pipeline with minimal iterations
test: install
	@echo "Running quick test of entire pipeline..."
	$(PYTHON) 3_estimation.py
	$(PYTHON) 4_results_table.py
	@echo "Quick test completed successfully!"

# Individual steps (can be run independently)
step1: estimation  
step2: results

# Clean all generated files
clean:
	@echo "Cleaning generated files..."
	rm -rf $(RESULTS_DIR)/*
	rm -rf __pycache__/
	rm -rf *.pyc
	@echo "Clean completed!"

# Clean only results
clean-results:
	@echo "Cleaning results..."
	rm -rf $(RESULTS_DIR)/*
	@echo "Results cleaned!"

# Help target
help:
	@echo "Preference Estimation Pipeline"
	@echo "=============================="
	@echo ""
	@echo "Available targets:"
	@echo "  all          - Run complete estimation pipeline"
	@echo "  install      - Install Python dependencies"
	@echo "  estimation   - Run maximum likelihood estimation (Step 1)"
	@echo "  results      - Generate results tables (Step 2)"
	@echo ""
	@echo "Individual steps:"
	@echo "  step1        - Same as 'estimation'"
	@echo "  step2        - Same as 'results'"
	@echo ""
	@echo "Testing:"
	@echo "  test         - Quick test of entire pipeline"
	@echo "  test-likelihood - Test likelihood function only"
	@echo "  test-estimation - Test estimation only"  
	@echo "  test-results - Test results generation only"
	@echo ""
	@echo "Maintenance:"
	@echo "  clean        - Remove all generated files"
	@echo "  clean-results- Remove results"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "Example usage:"
	@echo "  make all              # Run complete pipeline"
	@echo "  make step1 step2      # Run both steps"
	@echo "  make clean && make test # Clean and run quick test"
	@echo ""
	@echo "Note: Data files (survey_responses.csv, marginal_applications_*.csv)"
	@echo "      should already exist in ../../data/ directory"

# Create necessary directories
$(RESULTS_DIR):
	mkdir -p $@

# Ensure directories exist before running scripts
$(RESULTS_DIR)/parameter_estimates.csv: | $(RESULTS_DIR)
$(RESULTS_DIR)/parameter_table.tex: | $(RESULTS_DIR)