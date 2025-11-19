"""
Exploded Logit Model for Sibling School Assignment Preferences (CB-Siblings Project)

Implements an exploded logit model to analyze family preferences over joint vs split
school allocations for siblings, using partial ranking data from Chilean SAE surveys.

This module includes:
1. Joint vs Split likelihood (comparing joint and split allocations)
2. Marginal ranking likelihoods for each sibling (individual school rankings)

The full likelihood is the product of these three components, assuming independence
conditional on type.

Ranking variables used:
- sibl04_1: Top preferred school (both assigned together)
- sibl04_2: Least preferred school (both assigned together)
- sibl05_menor, sibl05_mayor: Preferences for younger/older sibling (assigned separately)
- sibl06_menos: Choice between split vs worst joint allocation
- sibl06_mas: Choice between best joint vs split allocation (only one school applied in common)

Marginal application data:
- marginal_applications_older.csv: Complete application rankings for older sibling
- marginal_applications_younger.csv: Complete application rankings for younger sibling

Author: Javiera Gazmuri
Date: Oct 2025 - Nov 2025
"""

import numpy as np
import pandas as pd
from scipy import optimize
from typing import Tuple, Dict, List, Any, Optional

class ExplodedSiblingLogit:
    """
    Exploded logit model for sibling school choice preferences.
    """
    
    def __init__(self, data: pd.DataFrame):
        """
        Initialize exploded logit model.
        
        Args:
            data: Survey response data with ranking information
        """
        # Keep only families with common schools
        self.data = data.copy()
        self.n_obs = len(self.data)

        
        # Create choice scenario indicators based on cant_common_rbd
        self._create_choice_indicators()
        
        # Create split vs joint allocation choices
        self.split_vs_joint = self._create_first_choices()
        
        print(f"Initialized exploded logit with {self.n_obs} observations")
        print(f"(Families with common schools only)")
        
    def _create_choice_indicators(self) -> None:
        """Create binary indicators for different choice scenarios based on cant_common_rbd."""
        # Multiple common schools case (cant_common_rbd > 1)
        multi_common = self.data['cant_common_rbd'] > 1
        # Single common school case (cant_common_rbd == 1)
        single_common = self.data['cant_common_rbd'] == 1
        
        # Store masks for later use
        self.multi_common = multi_common
        self.single_common = single_common
    
    def _create_first_choices(self) -> np.ndarray:
        """Create binary choices comparing split vs joint allocation."""
        # For multiple common schools: compare split vs worst joint (sibl06_menos)
        # For single common school: compare split vs only joint (sibl06_mas)
        choices = np.zeros((self.n_obs, 2))  # [chose_split, chose_joint]
        
        # Multiple common schools case
        is_joint_multi = self.data.loc[self.multi_common, 'worstjoint_vs_split'].fillna('').str.startswith('Ambos')
        choices[self.multi_common, 0] = ~is_joint_multi
        choices[self.multi_common, 1] = is_joint_multi
        
        # Single common school case
        is_joint_single = self.data.loc[self.single_common, 'joint_vs_split'].fillna('').str.startswith('Ambos')
        choices[self.single_common, 0] = ~is_joint_single
        choices[self.single_common, 1] = is_joint_single
        
        return choices
    
    def compute_utilities(self, params: np.ndarray) -> np.ndarray:
        """
        Calculate utilities for split vs joint allocation choice using covariates.

        Model (hierarchical, linear-in-parameters):
            u_ijkt = omega_y * u_yij + (1 - omega_y) * u_oik + gamma * I[joint]

        where u_yij = X_yij beta_y and u_oik = X_oik beta_o. X includes quality and distance.

        Args:
            params: Parameter vector [beta_y_q, beta_y_d, beta_o_q, beta_o_d, omega_y, gamma]

        Returns:
            np.ndarray: (n_obs x 2) array of utilities for [split, joint]
        """
        if len(params) != 6:
            raise ValueError(f"Expected 6 parameters ([beta_y_q, beta_y_d, beta_o_q, beta_o_d, omega_y, gamma]), got {len(params)}")

        beta_y_q, beta_y_d, beta_o_q, beta_o_d, omega_y, gamma = params

        # Required covariate columns
        required = [
            'dist_km_bos_old', 'dist_km_bos_young', 'qual_bos_old', 'qual_bos_young',
            'dist_km_wj_old', 'dist_km_wj_young', 'qual_wj_old', 'qual_wj_young',
            'dist_km_bj_old', 'dist_km_bj_young', 'qual_bj_old', 'qual_bj_young'
        ]
        missing = [c for c in required if c not in self.data.columns]
        if missing:
            raise ValueError(f"Missing required covariate columns: {missing}")

        # Use sibling-specific covariates (don't average):
        # For split option: younger = *_young, older = *_old (bos = best older/younger solo)
        qual_y_split = self.data['qual_bos_young'].astype(float).to_numpy()
        dist_y_split = self.data['dist_km_bos_young'].astype(float).to_numpy()

        qual_o_split = self.data['qual_bos_old'].astype(float).to_numpy()
        dist_o_split = self.data['dist_km_bos_old'].astype(float).to_numpy()

        # Joint candidates: worst joint (wj) or best joint (bj)
        qual_wj_y = self.data['qual_wj_young'].astype(float).to_numpy()
        dist_wj_y = self.data['dist_km_wj_young'].astype(float).to_numpy()
        qual_wj_o = self.data['qual_wj_old'].astype(float).to_numpy()
        dist_wj_o = self.data['dist_km_wj_old'].astype(float).to_numpy()

        qual_bj_y = self.data['qual_bj_young'].astype(float).to_numpy()
        dist_bj_y = self.data['dist_km_bj_young'].astype(float).to_numpy()
        qual_bj_o = self.data['qual_bj_old'].astype(float).to_numpy()
        dist_bj_o = self.data['dist_km_bj_old'].astype(float).to_numpy()

        # Treat quality recorded as 0 as missing (0 encodes missing in the data)
        def _zero_to_nan(arr):
            arr = np.asarray(arr, dtype=float)
            mask0 = (arr == 0)
            if mask0.any():
                arr[mask0] = np.nan
            return arr

        qual_y_split = _zero_to_nan(qual_y_split)
        qual_o_split = _zero_to_nan(qual_o_split)
        qual_wj_y = _zero_to_nan(qual_wj_y)
        qual_wj_o = _zero_to_nan(qual_wj_o)
        qual_bj_y = _zero_to_nan(qual_bj_y)
        qual_bj_o = _zero_to_nan(qual_bj_o)

        # Select joint covariates depending on multiple common schools
        multi_mask = self.multi_common.values if hasattr(self.multi_common, 'values') else np.asarray(self.multi_common)
        qual_joint_y = np.where(multi_mask, qual_wj_y, qual_bj_y)
        dist_joint_y = np.where(multi_mask, dist_wj_y, dist_bj_y)
        qual_joint_o = np.where(multi_mask, qual_wj_o, qual_bj_o)
        dist_joint_o = np.where(multi_mask, dist_wj_o, dist_bj_o)

        # Impute NaNs with column means
        def _impute(arr):
            arr = np.asarray(arr, dtype=float)
            mask = np.isnan(arr)
            if mask.all():
                return np.zeros_like(arr)
            mv = np.nanmean(arr)
            arr[mask] = mv
            return arr

        qual_y_split = _impute(qual_y_split)
        dist_y_split = _impute(dist_y_split)
        qual_o_split = _impute(qual_o_split)
        dist_o_split = _impute(dist_o_split)

        qual_joint_y = _impute(qual_joint_y)
        dist_joint_y = _impute(dist_joint_y)
        qual_joint_o = _impute(qual_joint_o)
        dist_joint_o = _impute(dist_joint_o)

        # Compute child-specific utilities using sibling-specific covariates
        u_y_split = beta_y_q * qual_y_split + beta_y_d * dist_y_split
        u_o_split = beta_o_q * qual_o_split + beta_o_d * dist_o_split

        u_y_joint = beta_y_q * qual_joint_y + beta_y_d * dist_joint_y
        u_o_joint = beta_o_q * qual_joint_o + beta_o_d * dist_joint_o

        # Aggregate by omega_y
        u_split = omega_y * u_y_split + (1 - omega_y) * u_o_split
        u_joint = omega_y * u_y_joint + (1 - omega_y) * u_o_joint + gamma

        return np.column_stack([u_split, u_joint])

    def choice_probabilities(self, params: np.ndarray) -> np.ndarray:
        """
        Calculate choice probabilities for split vs joint allocation.

        Args:
            params: Parameter vector [beta_y_q, beta_y_d, beta_o_q, beta_o_d, omega_y, gamma]

        Returns:
            np.ndarray: Probabilities for split vs joint allocation
        """
        utils = self.compute_utilities(params)
        
        # Logit probabilities with numerical stability (normalizing by max utility)
        max_util = np.max(utils, axis=1, keepdims=True)
        exp_utils = np.exp(utils - max_util)
        sum_exp_utils = np.sum(exp_utils, axis=1, keepdims=True)
        
        probs = exp_utils / sum_exp_utils
        # Ensure probabilities are valid
        probs = np.clip(probs, 1e-10, 1-1e-10)
        probs = probs / np.sum(probs, axis=1, keepdims=True)
        
        return probs
    
    def log_likelihood(self, params: np.ndarray) -> float:
        """
        Calculate log-likelihood across all choice scenarios.
        
        Args:
            params: Parameter vector [beta_y_q, beta_y_d, beta_o_q, beta_o_d, omega_y, gamma]
            
        Returns:
            float: Total log-likelihood value
        """
        try:
            probabilities = self.choice_probabilities(params)
            
            # Calculate log-likelihood for split vs joint choice
            # For cant_common_rbd > 1: split vs worst joint school
            # For cant_common_rbd == 1: split vs only joint school
            log_probs = np.log(probabilities)
            total_ll = np.sum(self.split_vs_joint * log_probs)
            
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

# Testing the likelihood function with sample data

def test_likelihood_function(data: pd.DataFrame):
    """
    Test the exploded logit with provided survey data.
    
    Args:
        data: Survey response data with ranking information
    """
    print("=" * 60)
    print("TESTING EXPLODED LOGIT")
    print("=" * 60)
    
    # Initialize likelihood
    likelihood = ExplodedSiblingLogit(data)
    
    # Test with example parameters: [beta_y_q, beta_y_d, beta_o_q, beta_o_d, omega_y, gamma]
    test_params = np.array([1.0, -0.1, 1.0, -0.1, 0.5, 0.8])
    
    print(f"\nTesting with parameters:")
    print("Test params (beta_y_q, beta_y_d, beta_o_q, beta_o_d, omega_y, gamma):", test_params)
    
    try:
        # Count observations with non-missing values for the eight covariates
        # Corresponding columns: qual_bos_young, dist_km_bos_young, qual_bos_old, dist_km_bos_old,
        # and for joint: qual_wj_young/qual_bj_young, dist_km_wj_young/dist_km_bj_young,
        # qual_wj_old/qual_bj_old, dist_km_wj_old/dist_km_bj_old (selected by cant_common_rbd)
        required = [
            'qual_bos_young', 'dist_km_bos_young', 'qual_bos_old', 'dist_km_bos_old',
            'qual_wj_young', 'dist_km_wj_young', 'qual_wj_old', 'dist_km_wj_old',
            'qual_bj_young', 'dist_km_bj_young', 'qual_bj_old', 'dist_km_bj_old',
        ]
        missing_cols = [c for c in required if c not in data.columns]
        if missing_cols:
            print(f"Warning: some covariate columns are missing, cannot compute complete-case count: {missing_cols}")
            complete_count = 0
        else:
            # Replace empty strings with NaN to treat them as missing
            df = data.copy()
            df = df.replace('', np.nan)
            multi_mask = df['cant_common_rbd'] > 1

            # Build the series for joint covariates depending on multi_mask
            qual_joint_y = pd.Series(np.where(multi_mask, df['qual_wj_young'], df['qual_bj_young']), index=df.index)
            dist_joint_y = pd.Series(np.where(multi_mask, df['dist_km_wj_young'], df['dist_km_bj_young']), index=df.index)
            qual_joint_o = pd.Series(np.where(multi_mask, df['qual_wj_old'], df['qual_bj_old']), index=df.index)
            dist_joint_o = pd.Series(np.where(multi_mask, df['dist_km_wj_old'], df['dist_km_bj_old']), index=df.index)

            qual_y_split = df['qual_bos_young']
            dist_y_split = df['dist_km_bos_young']
            qual_o_split = df['qual_bos_old']
            dist_o_split = df['dist_km_bos_old']

            # Treat quality == 0 as missing (0 encodes missing in the source data)
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

            complete_count = int(complete_mask.sum())

        print(f"\nObservations with complete values for the 8 covariates: {complete_count} / {likelihood.n_obs}")

        # Test utility calculation
        utilities = likelihood.compute_utilities(test_params)
        print("\nUtilities shape:", utilities.shape)
        print("Sample utilities (split, joint):", utilities[0])
        
        # Calculate probabilities
        probs = likelihood.choice_probabilities(test_params)
        print("\nProbabilities shape:", probs.shape)
        print("Sample probabilities (split, joint):", probs[0])
        print("Probabilities sum to:", np.sum(probs[0]))
        
        # Calculate likelihood
        ll_value = likelihood.log_likelihood(test_params)
        print(f"\nLog-likelihood: {ll_value:.4f}")
        
    except Exception as e:
        print(f"Error in calculation: {e}")
        return
    
    print("\nExploded logit test completed successfully!")

class ExtendedSiblingLogit(ExplodedSiblingLogit):
    """
    Extended exploded logit model that includes:
    1. Joint vs Split likelihood (from ExplodedSiblingLogit)
    2. Younger sibling marginal ranking likelihood
    3. Older sibling marginal ranking likelihood
    
    The full likelihood is the product: L = L_joint_split × L_younger × L_older
    
    Assumes independence of marginals conditional on type, following Type-I 
    Extreme Value distribution for idiosyncratic shocks.
    """
    
    def __init__(self, 
                 joint_data: pd.DataFrame,
                 marginal_older: pd.DataFrame,
                 marginal_younger: pd.DataFrame):
        """
        Initialize extended model with joint and marginal data.
        
        Args:
            joint_data: Survey response data (joint vs split scenarios)
            marginal_older: Complete application rankings for older sibling
            marginal_younger: Complete application rankings for younger sibling
        """
        # Initialize parent class with joint data
        super().__init__(joint_data)
        
        # Store marginal data
        self.marginal_older = marginal_older.copy()
        self.marginal_younger = marginal_younger.copy()
        
        # Prepare marginal data for likelihood calculation
        self._prepare_marginal_data()
        
        print(f"Extended likelihood initialized:")
        print(f"  - Joint vs split: {self.n_obs} observations")
        print(f"  - Older marginal: {len(self.marginal_older)} school choices")
        print(f"  - Younger marginal: {len(self.marginal_younger)} school choices")
    
    def _prepare_marginal_data(self) -> None:
        """
        Prepare marginal application data for likelihood calculation.
        
        For each family, we need:
        - Complete ranking (orden) for all schools
        - Covariates (quality, distance) for each school
        """
        # Ensure orden is numeric
        self.marginal_older['orden'] = pd.to_numeric(self.marginal_older['orden'], errors='coerce')
        self.marginal_younger['orden'] = pd.to_numeric(self.marginal_younger['orden'], errors='coerce')
        
        # Treat quality == 0 as missing
        for df in [self.marginal_older, self.marginal_younger]:
            df['qual'] = df['qual'].replace(0, np.nan)
            # Impute with mean
            df['qual'] = df['qual'].fillna(df['qual'].mean())
            df['dist_km'] = df['dist_km'].fillna(df['dist_km'].mean())
        
        # Sort by family and orden to ensure correct ranking order
        self.marginal_older = self.marginal_older.sort_values(['id_apoderado', 'orden'])
        self.marginal_younger = self.marginal_younger.sort_values(['id_apoderado', 'orden'])
    
    def _marginal_log_likelihood(self, 
                                  params: np.ndarray,
                                  marginal_data: pd.DataFrame,
                                  sibling_type: str) -> float:
        """
        Calculate log-likelihood for one sibling's marginal rankings.
        
        Uses exploded logit: P(ranking) = exp(V_ranked) / sum(exp(V_j)) for j in choice set
        
        Args:
            params: [beta_y_q, beta_y_d, beta_o_q, beta_o_d, omega_y, gamma]
            marginal_data: DataFrame with columns [id_apoderado, school_name, orden, qual, dist_km]
            sibling_type: 'younger' or 'older'
            
        Returns:
            float: Log-likelihood contribution from this sibling's marginal rankings
        """
        if sibling_type == 'younger':
            beta_q, beta_d = params[0], params[1]  # beta_y_q, beta_y_d
        else:  # older
            beta_q, beta_d = params[2], params[3]  # beta_o_q, beta_o_d
        
        total_ll = 0.0
        
        # Group by family (id_apoderado)
        for family_id, family_data in marginal_data.groupby('id_apoderado'):
            # Get covariates for all schools in this family's choice set
            qualities = family_data['qual'].values
            distances = family_data['dist_km'].values
            ordenes = family_data['orden'].values
            
            # Skip if missing data
            if len(qualities) == 0:
                continue
            
            # Compute utilities: V_j = beta_q * quality_j + beta_d * distance_j
            utilities = beta_q * qualities + beta_d * distances
            
            # For exploded logit, we need the probability of the observed ranking
            # The first choice is the school with orden==1 (highest ranked)
            # P(school with orden=1) = exp(V_1) / sum_j exp(V_j)
            
            # Find the school that was ranked first (orden == min(orden))
            first_choice_idx = np.argmin(ordenes)
            
            # Numerically stable softmax
            max_util = np.max(utilities)
            exp_utils = np.exp(utilities - max_util)
            sum_exp = np.sum(exp_utils)
            
            # Probability of choosing the first-ranked school
            prob_first = exp_utils[first_choice_idx] / sum_exp
            prob_first = np.clip(prob_first, 1e-10, 1-1e-10)
            
            # Add to log-likelihood
            total_ll += np.log(prob_first)
        
        return total_ll
    
    def log_likelihood(self, params: np.ndarray) -> float:
        """
        Calculate full log-likelihood: joint_split × younger × older.
        
        Args:
            params: Parameter vector [beta_y_q, beta_y_d, beta_o_q, beta_o_d, omega_y, gamma]
            
        Returns:
            float: Total log-likelihood value
        """
        try:
            # 1. Joint vs split likelihood (from parent class)
            ll_joint_split = super().log_likelihood(params)
            
            # 2. Younger sibling marginal likelihood
            ll_younger = self._marginal_log_likelihood(params, self.marginal_younger, 'younger')
            
            # 3. Older sibling marginal likelihood
            ll_older = self._marginal_log_likelihood(params, self.marginal_older, 'older')
            
            # Total log-likelihood (sum in log space = product in probability space)
            total_ll = ll_joint_split + ll_younger + ll_older
            
            # Check for numerical issues
            if np.isnan(total_ll) or np.isinf(total_ll):
                print(f"Invalid total log-likelihood: {total_ll}")
                print(f"  Joint-split: {ll_joint_split}, Younger: {ll_younger}, Older: {ll_older}")
                return -1e10
            
            return total_ll
            
        except Exception as e:
            print(f"Error in extended log_likelihood calculation: {e}")
            return -1e10


def test_extended_likelihood(joint_data: pd.DataFrame,
                             marginal_older: pd.DataFrame,
                             marginal_younger: pd.DataFrame):
    """
    Test the extended likelihood with marginal rankings.
    
    Args:
        joint_data: Survey response data
        marginal_older: Marginal applications for older sibling
        marginal_younger: Marginal applications for younger sibling
    """
    print("=" * 60)
    print("TESTING EXTENDED LIKELIHOOD WITH MARGINAL RANKINGS")
    print("=" * 60)
    
    # Initialize extended likelihood
    likelihood = ExtendedSiblingLogit(joint_data, marginal_older, marginal_younger)
    
    # Test with example parameters
    test_params = np.array([1.0, -0.1, 1.0, -0.1, 0.5, 0.8])
    
    print(f"\nTesting with parameters:")
    print("Test params (beta_y_q, beta_y_d, beta_o_q, beta_o_d, omega_y, gamma):", test_params)
    
    try:
        # Calculate each component
        ll_joint_split = ExplodedSiblingLogit.log_likelihood(likelihood, test_params)
        ll_younger = likelihood._marginal_log_likelihood(test_params, marginal_younger, 'younger')
        ll_older = likelihood._marginal_log_likelihood(test_params, marginal_older, 'older')
        ll_total = likelihood.log_likelihood(test_params)
        
        print(f"\nLog-likelihood components:")
        print(f"  Joint vs split: {ll_joint_split:.4f}")
        print(f"  Younger marginal: {ll_younger:.4f}")
        print(f"  Older marginal: {ll_older:.4f}")
        print(f"  Total: {ll_total:.4f}")
        print(f"  Sum check: {ll_joint_split + ll_younger + ll_older:.4f}")
        
    except Exception as e:
        print(f"Error in calculation: {e}")
        return
    
    print("\nExtended likelihood test completed successfully!")


def main():
    """Main execution function."""
    print("=" * 60)
    print("PREFERENCE ESTIMATION: Extended Exploded Logit Model")
    print("=" * 60)
    
    # Load and check data
    try:
        joint_data = pd.read_csv('data/survey_responses.csv')
        marginal_older = pd.read_csv('data/marginal_applications_older.csv')
        marginal_younger = pd.read_csv('data/marginal_applications_younger.csv')
        
        print("\nTesting basic likelihood (joint vs split only):")
        test_likelihood_function(joint_data)
        
        print("\n" + "=" * 60)
        print("Testing extended likelihood (with marginals):")
        test_extended_likelihood(joint_data, marginal_older, marginal_younger)
        
    except FileNotFoundError as e:
        print(f"Data files not found: {e}")
        return
    except Exception as e:
        print(f"Error testing likelihood function: {e}")
        return
    
    print("\n" + "=" * 60)
    print("Extended exploded logit model ready for estimation!")
    print("=" * 60)

if __name__ == "__main__":
    main()