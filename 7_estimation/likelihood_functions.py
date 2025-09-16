"""
Likelihood Function Implementation

This script implements the exploded logit likelihood function for preferences
over joint allocations with Type-1 extreme value idiosyncratic shocks.

Author: Preference Estimation Framework
Date: 2024
"""

import numpy as np
import pandas as pd
from scipy import optimize
from typing import Tuple, Dict, List, Any

class ExplodedLogitLikelihood:
    """
    Exploded logit likelihood for joint allocation preferences.
    
    Assumes each pair (i,j) has idiosyncratic preference shocks following
    Type-1 extreme value distribution.
    """
    
    def __init__(self, data: pd.DataFrame, covariates: pd.DataFrame):
        """
        Initialize likelihood function.
        
        Args:
            data: Survey response data with choices
            covariates: Design matrix with explanatory variables
        """
        self.data = data
        self.covariates = covariates
        self.n_obs = len(data)
        
        # Use data as base and add categorical dummies from covariates
        categorical_cols = ['income_high', 'income_low', 'income_medium', 
                           'education_primary', 'education_secondary', 'education_tertiary']
        
        # Select only categorical columns from covariates
        categorical_data = covariates[['respondent_id', 'choice_id'] + categorical_cols].copy()
        
        # Convert boolean columns to numeric (0/1)
        for col in categorical_cols:
            categorical_data[col] = categorical_data[col].astype(int)
        
        # Merge with survey data
        self.merged_data = data.merge(categorical_data, on=['respondent_id', 'choice_id'])
        
        # Extract choice outcomes
        self.choices = data[['option_0_chosen', 'option_1_chosen', 
                            'option_2_chosen', 'option_3_chosen']].values
        
        # Define covariate names for utility functions (excluding income_low and education_primary as reference)
        self.covariate_names = [
            'household_size', 'school_i_quality', 'school_j_quality',
            'school_i_distance', 'school_j_distance',
            'income_medium', 'income_high',  # income_low is reference category
            'education_secondary', 'education_tertiary'  # education_primary is reference
        ]
        
        # Extract covariate matrix and convert to float
        self.X = self.merged_data[self.covariate_names].values.astype(np.float64)
        
        print(f"Initialized likelihood with {self.n_obs} observations")
        print(f"Covariate matrix shape: {self.X.shape}")
    
    def utility_functions(self, params: np.ndarray, X: np.ndarray) -> np.ndarray:
        """
        Calculate utility for each allocation option.
        
        Args:
            params: Parameter vector
            X: Covariate matrix
            
        Returns:
            np.ndarray: Utilities for each option (n_obs x 4)
        """
        n_obs = X.shape[0]
        n_covariates = X.shape[1]
        
        # Parameter structure:
        # - Quality preferences (2 params): quality_own, quality_sibling
        # - Distance disutility (1 param): distance_coeff
        # - Together bonus (1 param): together_bonus
        # - Covariate effects (n_covariates params): effects on together_bonus
        
        if len(params) != 4 + n_covariates:
            raise ValueError(f"Expected {4 + n_covariates} parameters, got {len(params)}")
        
        quality_own = params[0]
        quality_sibling = params[1] 
        distance_coeff = params[2]
        together_bonus_base = params[3]
        covariate_effects = params[4:]
        
        # Extract school characteristics
        household_size = X[:, 0]
        quality_i = X[:, 1]
        quality_j = X[:, 2]
        distance_i = X[:, 3]
        distance_j = X[:, 4]
        
        # Calculate together bonus with covariate effects
        together_bonus = together_bonus_base + np.dot(X, covariate_effects)
        
        # Option utilities:
        # Option 0: Both siblings to school i
        u_both_i = (quality_own * quality_i + quality_sibling * quality_i + 
                   distance_coeff * (-2 * distance_i) + together_bonus)
        
        # Option 1: Both siblings to school j
        u_both_j = (quality_own * quality_j + quality_sibling * quality_j + 
                   distance_coeff * (-2 * distance_j) + together_bonus)
        
        # Option 2: Sibling 1 to i, Sibling 2 to j (split)
        u_split_ij = (quality_own * quality_i + quality_sibling * quality_j +
                      distance_coeff * (-distance_i - distance_j))
        
        # Option 3: Sibling 1 to j, Sibling 2 to i (split)
        u_split_ji = (quality_own * quality_j + quality_sibling * quality_i +
                      distance_coeff * (-distance_i - distance_j))
        
        # Stack utilities
        utilities = np.column_stack([u_both_i, u_both_j, u_split_ij, u_split_ji])
        
        # Ensure output is a numpy array with correct shape and check for numerical issues
        utilities = np.array(utilities, dtype=np.float64)
        if utilities.ndim == 1:
            utilities = utilities.reshape(1, -1)
        
        # Replace any inf or nan values with large but finite numbers
        utilities = np.where(np.isnan(utilities), -1e6, utilities)
        utilities = np.where(np.isinf(utilities), np.sign(utilities) * 1e6, utilities)
        
        return utilities
    
    def choice_probabilities(self, params: np.ndarray, X: np.ndarray) -> np.ndarray:
        """
        Calculate choice probabilities using logit formula.
        
        Args:
            params: Parameter vector
            X: Covariate matrix
            
        Returns:
            np.ndarray: Choice probabilities (n_obs x 4)
        """
        utilities = self.utility_functions(params, X)
        
        # Ensure utilities is a numpy array
        utilities = np.array(utilities, dtype=np.float64)
        
        # Logit probabilities with numerical stability
        # Use log-sum-exp trick for numerical stability
        max_util = np.max(utilities, axis=1, keepdims=True)
        
        # Prevent overflow by clipping utilities
        utilities_stable = np.clip(utilities - max_util, -700, 700)
        exp_utils = np.exp(utilities_stable)
        sum_exp_utils = np.sum(exp_utils, axis=1, keepdims=True)
        
        # Ensure sum is not zero
        sum_exp_utils = np.maximum(sum_exp_utils, 1e-15)
        
        probabilities = exp_utils / sum_exp_utils
        
        # Ensure probabilities are positive and sum to 1
        probabilities = np.clip(probabilities, 1e-15, 1-1e-15)
        row_sums = np.sum(probabilities, axis=1, keepdims=True)
        probabilities = probabilities / row_sums
        
        return probabilities
    
    def log_likelihood(self, params: np.ndarray) -> float:
        """
        Calculate log-likelihood for given parameters.
        
        Args:
            params: Parameter vector
            
        Returns:
            float: Log-likelihood value
        """
        try:
            probabilities = self.choice_probabilities(params, self.X)
            
            # Ensure probabilities are valid
            if np.any(np.isnan(probabilities)) or np.any(np.isinf(probabilities)):
                print(f"Invalid probabilities detected")
                return -1e10
                
            # Calculate log-likelihood with numerical stability
            log_probs = np.log(np.maximum(probabilities, 1e-15))
            individual_ll = np.sum(self.choices * log_probs, axis=1)
            
            # Check for numerical issues in individual contributions
            if np.any(np.isnan(individual_ll)) or np.any(np.isinf(individual_ll)):
                print(f"Invalid individual log-likelihoods detected")
                return -1e10
                
            total_ll = np.sum(individual_ll)
            
            # Final check for numerical issues
            if np.isnan(total_ll) or np.isinf(total_ll):
                print(f"Invalid total log-likelihood: {total_ll}")
                return -1e10
                
            return total_ll
            
        except Exception as e:
            print(f"Error in log_likelihood calculation: {e}")
            return -1e10
    
    def negative_log_likelihood(self, params: np.ndarray) -> float:
        """
        Negative log-likelihood for minimization.
        
        Args:
            params: Parameter vector
            
        Returns:
            float: Negative log-likelihood value
        """
        return -self.log_likelihood(params)
    
    def gradient_log_likelihood(self, params: np.ndarray) -> np.ndarray:
        """
        Calculate gradient of log-likelihood (numerical approximation).
        
        Args:
            params: Parameter vector
            
        Returns:
            np.ndarray: Gradient vector
        """
        eps = 1e-6
        grad = np.zeros_like(params)
        
        for i in range(len(params)):
            params_plus = params.copy()
            params_minus = params.copy()
            params_plus[i] += eps
            params_minus[i] -= eps
            
            grad[i] = (self.log_likelihood(params_plus) - 
                      self.log_likelihood(params_minus)) / (2 * eps)
        
        return grad

def test_likelihood_function():
    """Test the likelihood function with synthetic data."""
    print("=" * 60)
    print("TESTING LIKELIHOOD FUNCTION")
    print("=" * 60)
    
    # Load test data
    data = pd.read_csv('data/survey_responses.csv')
    covariates = pd.read_csv('data/covariates.csv')
    
    # Initialize likelihood
    likelihood = ExplodedLogitLikelihood(data, covariates)
    
    # Test with random parameters
    n_params = 4 + len(likelihood.covariate_names)
    test_params = np.random.normal(0, 0.1, n_params)
    
    print(f"\nTesting with {n_params} parameters:")
    print(f"Parameter vector: {test_params}")
    
    # Test utility calculation first
    print("\nTesting utility calculation...")
    X_test = likelihood.X[:2]  # Test with first 2 observations
    print(f"X_test shape: {X_test.shape}")
    print(f"X_test type: {type(X_test)}")
    print(f"X_test:\n{X_test}")
    
    try:
        utilities = likelihood.utility_functions(test_params, X_test)
        print(f"Utilities shape: {utilities.shape}")
        print(f"Utilities type: {type(utilities)}")
        print(f"Utilities:\n{utilities}")
    except Exception as e:
        print(f"Error in utility calculation: {e}")
        return
    
    # Calculate likelihood
    ll_value = likelihood.log_likelihood(test_params)
    print(f"Log-likelihood: {ll_value:.4f}")
    
    print("\nLikelihood function test completed!")

def main():
    """Main execution function."""
    print("=" * 60)
    print("PREFERENCE ESTIMATION: Likelihood Function")
    print("=" * 60)
    
    # Check if data exists
    try:
        test_likelihood_function()
    except FileNotFoundError:
        print("Data files not found. Please run 1_load_data.py first.")
        return
    
    print("\n" + "=" * 60)
    print("Likelihood function module ready for estimation!")
    print("=" * 60)

if __name__ == "__main__":
    main()