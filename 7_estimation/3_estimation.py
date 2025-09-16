"""
Maximum Likelihood Estimation Script

This script performs maximum likelihood estimation of the preference parameters
and saves the results.

Author: Preference Estimation Framework
Date: 2024
"""

import numpy as np
import pandas as pd
from scipy import optimize
import json
import time
import os
from typing import Dict, Tuple, Any

import sys
import os
sys.path.append(os.path.dirname(__file__))
from likelihood_functions import ExplodedLogitLikelihood

class PreferenceEstimator:
    """
    Maximum likelihood estimator for preference parameters.
    """
    
    def __init__(self, data: pd.DataFrame, covariates: pd.DataFrame):
        """
        Initialize estimator.
        
        Args:
            data: Survey response data
            covariates: Covariate matrix
        """
        self.likelihood = ExplodedLogitLikelihood(data, covariates)
        self.n_params = 4 + len(self.likelihood.covariate_names)
        
        # Parameter names for results
        self.param_names = [
            'quality_own',
            'quality_sibling', 
            'distance_coeff',
            'together_bonus_base'
        ] + [f'together_bonus_{name}' for name in self.likelihood.covariate_names]
        
        self.results = None
    
    def get_starting_values(self) -> np.ndarray:
        """
        Generate reasonable starting values for optimization.
        
        Returns:
            np.ndarray: Starting parameter vector
        """
        starting_values = np.zeros(self.n_params)
        
        # Quality preferences (positive)
        starting_values[0] = 0.5  # quality_own
        starting_values[1] = 0.3  # quality_sibling
        
        # Distance disutility (negative)
        starting_values[2] = -0.2  # distance_coeff
        
        # Together bonus (positive)
        starting_values[3] = 0.4  # together_bonus_base
        
        # Covariate effects (small random values)
        starting_values[4:] = np.random.normal(0, 0.05, len(starting_values) - 4)
        
        return starting_values
    
    def estimate(self, method: str = 'BFGS', maxiter: int = 1000, 
                 tolerance: float = 1e-6) -> Dict[str, Any]:
        """
        Perform maximum likelihood estimation.
        
        Args:
            method: Optimization method
            maxiter: Maximum iterations
            tolerance: Convergence tolerance
            
        Returns:
            Dict: Estimation results
        """
        print(f"Starting maximum likelihood estimation...")
        print(f"Method: {method}, Max iterations: {maxiter}")
        print(f"Number of parameters: {self.n_params}")
        print(f"Number of observations: {self.likelihood.n_obs}")
        
        # Get starting values
        x0 = self.get_starting_values()
        print(f"Starting values: {x0}")
        
        # Test likelihood at starting values
        start_ll = self.likelihood.log_likelihood(x0)
        print(f"Initial log-likelihood: {start_ll:.4f}")
        
        # Optimize
        start_time = time.time()
        
        try:
            if method == 'BFGS':
                result = optimize.minimize(
                    self.likelihood.negative_log_likelihood,
                    x0,
                    method='BFGS',
                    options={'maxiter': maxiter, 'gtol': tolerance}
                )
            elif method == 'Nelder-Mead':
                result = optimize.minimize(
                    self.likelihood.negative_log_likelihood,
                    x0,
                    method='Nelder-Mead',
                    options={'maxiter': maxiter, 'xatol': tolerance}
                )
            elif method == 'L-BFGS-B':
                result = optimize.minimize(
                    self.likelihood.negative_log_likelihood,
                    x0,
                    method='L-BFGS-B',
                    options={'maxiter': maxiter, 'gtol': tolerance}
                )
            else:
                raise ValueError(f"Unknown optimization method: {method}")
                
        except Exception as e:
            print(f"Optimization failed: {e}")
            result = None
        
        estimation_time = time.time() - start_time
        
        # Process results
        if result is not None and result.success:
            print(f"\nOptimization successful!")
            print(f"Convergence: {result.success}")
            print(f"Final log-likelihood: {-result.fun:.4f}")
            print(f"Iterations: {result.nit}")
            print(f"Estimation time: {estimation_time:.2f} seconds")
            
            # Calculate standard errors (approximate)
            std_errors = self._calculate_standard_errors(result.x)
            
            self.results = {
                'success': True,
                'parameters': result.x,
                'parameter_names': self.param_names,
                'log_likelihood': -result.fun,
                'std_errors': std_errors,
                'iterations': result.nit,
                'estimation_time': estimation_time,
                'method': method,
                'convergence_message': result.message
            }
            
        else:
            print(f"\nOptimization failed!")
            if result is not None:
                print(f"Message: {result.message}")
            
            self.results = {
                'success': False,
                'message': result.message if result is not None else 'Optimization error',
                'estimation_time': estimation_time
            }
        
        return self.results
    
    def _calculate_standard_errors(self, params: np.ndarray) -> np.ndarray:
        """
        Calculate approximate standard errors using numerical Hessian.
        
        Args:
            params: Estimated parameters
            
        Returns:
            np.ndarray: Standard errors
        """
        print("Calculating standard errors...")
        
        try:
            # Calculate numerical Hessian
            hessian = self._numerical_hessian(params)
            
            # Standard errors from inverse Hessian diagonal
            inv_hessian = np.linalg.inv(hessian)
            std_errors = np.sqrt(np.diag(inv_hessian))
            
            return std_errors
            
        except Exception as e:
            print(f"Warning: Could not calculate standard errors: {e}")
            return np.full(len(params), np.nan)
    
    def _numerical_hessian(self, params: np.ndarray, eps: float = 1e-5) -> np.ndarray:
        """
        Calculate numerical Hessian matrix.
        
        Args:
            params: Parameter vector
            eps: Step size for numerical differentiation
            
        Returns:
            np.ndarray: Hessian matrix
        """
        n = len(params)
        hessian = np.zeros((n, n))
        
        for i in range(n):
            for j in range(n):
                if i == j:
                    # Second derivative
                    params_plus = params.copy()
                    params_minus = params.copy()
                    params_plus[i] += eps
                    params_minus[i] -= eps
                    
                    hessian[i, j] = (
                        self.likelihood.negative_log_likelihood(params_plus) +
                        self.likelihood.negative_log_likelihood(params_minus) -
                        2 * self.likelihood.negative_log_likelihood(params)
                    ) / (eps ** 2)
                else:
                    # Cross derivative
                    params_pp = params.copy()
                    params_pm = params.copy()
                    params_mp = params.copy()
                    params_mm = params.copy()
                    
                    params_pp[i] += eps; params_pp[j] += eps
                    params_pm[i] += eps; params_pm[j] -= eps
                    params_mp[i] -= eps; params_mp[j] += eps
                    params_mm[i] -= eps; params_mm[j] -= eps
                    
                    hessian[i, j] = (
                        self.likelihood.negative_log_likelihood(params_pp) -
                        self.likelihood.negative_log_likelihood(params_pm) -
                        self.likelihood.negative_log_likelihood(params_mp) +
                        self.likelihood.negative_log_likelihood(params_mm)
                    ) / (4 * eps ** 2)
        
        return hessian
    
    def save_results(self) -> None:
        """Save estimation results to files."""
        if self.results is None:
            print("No results to save. Run estimation first.")
            return
        
        os.makedirs('results', exist_ok=True)
        
        if self.results['success']:
            # Save parameter estimates
            param_df = pd.DataFrame({
                'parameter': self.results['parameter_names'],
                'estimate': self.results['parameters'],
                'std_error': self.results['std_errors'],
                't_stat': self.results['parameters'] / self.results['std_errors']
            })
            param_df.to_csv('results/parameter_estimates.csv', index=False)
            
            # Save estimation summary
            summary = {
                'log_likelihood': self.results['log_likelihood'],
                'n_observations': self.likelihood.n_obs,
                'n_parameters': self.n_params,
                'aic': -2 * self.results['log_likelihood'] + 2 * self.n_params,
                'bic': -2 * self.results['log_likelihood'] + self.n_params * np.log(self.likelihood.n_obs),
                'iterations': self.results['iterations'],
                'estimation_time': self.results['estimation_time'],
                'method': self.results['method']
            }
            
            with open('results/estimation_summary.json', 'w') as f:
                json.dump(summary, f, indent=2)
            
            # Save text summary
            with open('results/estimation_summary.txt', 'w') as f:
                f.write("PREFERENCE ESTIMATION RESULTS\n")
                f.write("=" * 50 + "\n\n")
                f.write(f"Log-likelihood: {summary['log_likelihood']:.4f}\n")
                f.write(f"AIC: {summary['aic']:.4f}\n")
                f.write(f"BIC: {summary['bic']:.4f}\n")
                f.write(f"Observations: {summary['n_observations']}\n")
                f.write(f"Parameters: {summary['n_parameters']}\n")
                f.write(f"Method: {summary['method']}\n")
                f.write(f"Iterations: {summary['iterations']}\n")
                f.write(f"Time: {summary['estimation_time']:.2f} seconds\n\n")
                
                f.write("PARAMETER ESTIMATES\n")
                f.write("-" * 50 + "\n")
                for _, row in param_df.iterrows():
                    f.write(f"{row['parameter']:20s}: {row['estimate']:8.4f} ({row['std_error']:6.4f})\n")
            
            print("Results saved successfully!")
            print(f"Parameter estimates: results/parameter_estimates.csv")
            print(f"Estimation summary: results/estimation_summary.txt")
            
        else:
            # Save failure information
            with open('results/estimation_failed.txt', 'w') as f:
                f.write("ESTIMATION FAILED\n")
                f.write("=" * 30 + "\n\n")
                f.write(f"Message: {self.results['message']}\n")
                f.write(f"Time: {self.results['estimation_time']:.2f} seconds\n")
            
            print("Estimation failed. Failure information saved to results/estimation_failed.txt")

def main():
    """Main execution function."""
    print("=" * 60)
    print("PREFERENCE ESTIMATION: Maximum Likelihood")
    print("=" * 60)
    
    # Load data
    try:
        print("Loading data...")
        data = pd.read_csv('data/survey_responses.csv')
        covariates = pd.read_csv('data/covariates.csv')
        print(f"Loaded {len(data)} observations")
    except FileNotFoundError as e:
        print(f"Data files not found: {e}")
        print("Please run 1_load_data.py first.")
        return
    
    # Initialize estimator
    estimator = PreferenceEstimator(data, covariates)
    
    # Run estimation
    print("\n" + "-" * 60)
    results = estimator.estimate(method='BFGS', maxiter=1000)
    
    # Save results
    print("\n" + "-" * 60)
    estimator.save_results()
    
    print("\n" + "=" * 60)
    print("Maximum likelihood estimation completed!")
    print("=" * 60)

if __name__ == "__main__":
    main()