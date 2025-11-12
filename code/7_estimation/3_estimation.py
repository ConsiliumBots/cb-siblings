"""
Maximum Likelihood Estimation Script

This script performs maximum likelihood estimation of the preference parameters
for the simplified sibling choice model with only together_bonus parameter.

Author: Javiera Gazmuri
Date: Oct 2025
"""

import numpy as np
import pandas as pd
from scipy import optimize
import json
import time
import os
from typing import Dict, Tuple, Any, List

import sys
sys.path.append(os.path.dirname(__file__))
from likelihood_functions import ExplodedSiblingLogit, ExtendedSiblingLogit

class PreferenceEstimator:
    def __init__(self, data, marginal_older=None, marginal_younger=None, use_marginals=True):
        """
        Initialize estimator with joint and optional marginal data.
        
        Args:
            data: Survey response data (joint vs split scenarios)
            marginal_older: Marginal applications for older sibling (optional)
            marginal_younger: Marginal applications for younger sibling (optional)
            use_marginals: If True and marginal data provided, use ExtendedSiblingLogit
        """
        if use_marginals and marginal_older is not None and marginal_younger is not None:
            self.likelihood = ExtendedSiblingLogit(data, marginal_older, marginal_younger)
            self.model_type = "Extended (with marginals)"
        else:
            self.likelihood = ExplodedSiblingLogit(data)
            self.model_type = "Basic (joint vs split only)"
        # New parameterization: [beta_y_q, beta_y_d, beta_o_q, beta_o_d, omega_y, gamma]
        self.param_names = [
            "beta_y_q", "beta_y_d", "beta_o_q", "beta_o_d", "omega_y", "gamma"
        ]
        # Compute complete-case N matching test_likelihood_function (qualities==0 treated as missing)
        self.complete_n = self._compute_complete_n()
        # Overwrite likelihood.n_obs for reporting to match complete-case count
        try:
            self.likelihood.n_obs = int(self.complete_n)
        except Exception:
            pass
        self.results = None

    def _compute_complete_n(self) -> int:
        """Compute number of observations with non-missing covariates used in utilities.

        Mirrors the logic in test_likelihood_function: treats quality==0 as missing and
        selects joint covariates depending on `cant_common_rbd`.
        """
        df = self.likelihood.data.copy()
        # Required covariate columns (same as in likelihood_functions test)
        required = [
            'qual_bos_young', 'dist_km_bos_young', 'qual_bos_old', 'dist_km_bos_old',
            'qual_wj_young', 'dist_km_wj_young', 'qual_wj_old', 'dist_km_wj_old',
            'qual_bj_young', 'dist_km_bj_young', 'qual_bj_old', 'dist_km_bj_old',
        ]
        missing_cols = [c for c in required if c not in df.columns]
        if missing_cols:
            print(f"Warning: missing covariate columns, complete-case N set to 0: {missing_cols}")
            return 0

        # Normalize empty strings to NaN
        df = df.replace('', np.nan)
        multi_mask = df['cant_common_rbd'] > 1

        # Select joint covariates per-row
        qual_joint_y = pd.Series(np.where(multi_mask, df['qual_wj_young'], df['qual_bj_young']), index=df.index)
        dist_joint_y = pd.Series(np.where(multi_mask, df['dist_km_wj_young'], df['dist_km_bj_young']), index=df.index)
        qual_joint_o = pd.Series(np.where(multi_mask, df['qual_wj_old'], df['qual_bj_old']), index=df.index)
        dist_joint_o = pd.Series(np.where(multi_mask, df['dist_km_wj_old'], df['dist_km_bj_old']), index=df.index)

        qual_y_split = df['qual_bos_young']
        dist_y_split = df['dist_km_bos_young']
        qual_o_split = df['qual_bos_old']
        dist_o_split = df['dist_km_bos_old']

        # Treat quality==0 as missing
        qual_y_split = qual_y_split.replace(0, np.nan)
        qual_o_split = qual_o_split.replace(0, np.nan)
        qual_joint_y = qual_joint_y.replace(0, np.nan)
        qual_joint_o = qual_joint_o.replace(0, np.nan)

        complete_mask = (
            qual_y_split.notna() & dist_y_split.notna() &
            qual_o_split.notna() & dist_o_split.notna() &
            qual_joint_y.notna() & dist_joint_y.notna() &
            qual_joint_o.notna() & dist_joint_o.notna()
        )

        return int(complete_mask.sum())
        
    def get_starting_values(self):
        # Sensible starting values based on the test harness
        return np.array([1.0, -0.1, 1.0, -0.1, 0.5, 0.8])
    
    def estimate(self, method="Nelder-Mead", maxiter=1000):
        print("Starting estimation...")
        x0 = self.get_starting_values()
        
        start_ll = self.likelihood.log_likelihood(x0)
        print(f"Initial log-likelihood: {start_ll:.4f}")
        
        try:
            # Use bounds to constrain omega_y to [0,1]. We'll use L-BFGS-B by default
            # unless the user explicitly requests another method.
            bounds = [
                (None, None),  # beta_y_q
                (None, None),  # beta_y_d
                (None, None),  # beta_o_q
                (None, None),  # beta_o_d
                (0.0, 1.0),    # omega_y (weight between 0 and 1)
                (None, None),  # gamma (joint bonus)
            ]

            opt_method = method if method is not None else "L-BFGS-B"
            if opt_method == "Nelder-Mead":
                # Nelder-Mead does not support bounds; warn and run unbounded
                print("Warning: Nelder-Mead ignores bounds. Consider using 'L-BFGS-B' to enforce 0<=omega_y<=1.")

            result = optimize.minimize(
                fun=self.likelihood.negative_log_likelihood,
                x0=x0,
                method="L-BFGS-B",
                bounds=bounds,
                options={"maxiter": maxiter}
            )
            
            self.results = result
            print(f"\nSuccess: {result['success']}")
            print(f"Final log-likelihood: {-result['fun']:.4f}")
            # Print all estimated parameters with names
            est = result['x']
            for name, val in zip(self.param_names, est):
                print(f"Estimated {name}: {val:.6f}")
            
            return result
            
        except Exception as e:
            print(f"Error in estimation: {e}")
            return None
    
    def save_results(self):
        if self.results is None:
            return
        est = self.results["x"]
        results_dict: Dict[str, Any] = {
            "model_type": self.model_type,
            "params": {name: float(val) for name, val in zip(self.param_names, est)},
            "log_likelihood": float(-self.results["fun"]),
            "success": bool(self.results["success"]),
            "n_obs": int(self.likelihood.n_obs)
        }
        
        # Save to results directory relative to script location
        script_dir = os.path.dirname(os.path.abspath(__file__))
        results_dir = os.path.join(script_dir, "results")
        os.makedirs(results_dir, exist_ok=True)
        
        results_file = os.path.join(results_dir, "estimation_results.json")
        with open(results_file, "w") as f:
            json.dump(results_dict, f, indent=4)
        
        # Also export a simple LaTeX table with parameter estimates
        tex_path = os.path.join(results_dir, "estimation_results.tex")
        try:
            with open(tex_path, "w") as tf:
                tf.write("% Auto-generated LaTeX table of estimation results\n")
                tf.write("\\begin{table}[ht]\n\\centering\n")
                tf.write("\\begin{tabular}{lr}\n\\hline\n")
                tf.write("Parameter & Estimate \\\\ \n\\hline\n")
                for name, val in zip(self.param_names, est):
                    tf.write(f"{name} & {float(val):.6f} \\\\ \n")
                tf.write("\\hline\n\\end{tabular}\n")
                # Add a small caption with fit statistics
                tf.write(f"\\caption{{Estimated parameters (log-likelihood={results_dict['log_likelihood']:.3f}, n={results_dict['n_obs']})}}\\n")
                tf.write("\\label{tab:estimation_results}\n\\end{table}\n")
            print(f"LaTeX table written to {tex_path}")
        except Exception as e:
            print(f"Warning: could not write LaTeX results file: {e}")

def main():
    print("=" * 60)
    print("PREFERENCE ESTIMATION")
    print("=" * 60)
    
    # Load data
    try:
        data = pd.read_csv("data/survey_responses.csv")
        print(f"Loaded joint data: {len(data)} observations")
    except FileNotFoundError:
        print("Error: data/survey_responses.csv not found")
        return
    
    # Try to load marginal data
    try:
        marginal_older = pd.read_csv("data/marginal_applications_older.csv")
        marginal_younger = pd.read_csv("data/marginal_applications_younger.csv")
        print(f"Loaded marginal data:")
        print(f"  - Older sibling: {len(marginal_older)} school choices")
        print(f"  - Younger sibling: {len(marginal_younger)} school choices")
        use_marginals = True
    except FileNotFoundError:
        print("Warning: Marginal data not found, using joint vs split only")
        marginal_older = None
        marginal_younger = None
        use_marginals = False
    
    # Initialize estimator
    estimator = PreferenceEstimator(data, marginal_older, marginal_younger, use_marginals)
    print(f"\nModel type: {estimator.model_type}")
    
    # Run estimation
    results = estimator.estimate()
    
    if results is not None and results["success"]:
        estimator.save_results()
        print("\nResults saved to results/estimation_results.json")
    
    print("\nEstimation completed!")
    print("=" * 60)

if __name__ == "__main__":
    main()
