"""
Data Loading and Preprocessing Script

This script loads survey response data on preferences over joint allocations
and formats it for likelihood estimation.

Author: Preference Estimation Framework
Date: 2024
"""

import numpy as np
import pandas as pd
import os
from typing import Tuple, Dict, Any

def load_survey_data() -> pd.DataFrame:
    """
    Load survey data on preferences over joint allocations.
    
    If original data is not available, generates synthetic data for testing.
    
    Returns:
        pd.DataFrame: Cleaned survey response data
    """
    # Try to load actual survey data first
    survey_path = "../2_surveys/questionaries/"
    
    # Check if we have access to the actual survey data files
    if os.path.exists(survey_path):
        print("Survey data folder found, but no specific data files detected.")
        print("Generating synthetic data for testing purposes...")
    else:
        print("Survey data folder not accessible. Generating synthetic data...")
    
    # Generate synthetic survey data for testing
    np.random.seed(42)  # For reproducibility
    
    n_respondents = 1000
    n_choices_per_respondent = 10
    
    # Create synthetic survey responses
    data = []
    
    for respondent_id in range(n_respondents):
        # Generate respondent characteristics
        household_size = np.random.choice([2, 3, 4, 5], p=[0.1, 0.4, 0.4, 0.1])
        income_category = np.random.choice(['low', 'medium', 'high'], p=[0.3, 0.5, 0.2])
        parent_education = np.random.choice(['primary', 'secondary', 'tertiary'], p=[0.2, 0.5, 0.3])
        
        # Generate choice scenarios for this respondent
        for choice_id in range(n_choices_per_respondent):
            # School characteristics for pair (school_i, school_j)
            school_i_quality = np.random.normal(0, 1)
            school_j_quality = np.random.normal(0, 1)
            
            school_i_distance = np.random.exponential(2)
            school_j_distance = np.random.exponential(2)
            
            # Joint allocation options
            # Option 1: Both siblings to school i
            # Option 2: Both siblings to school j  
            # Option 3: Sibling 1 to school i, Sibling 2 to school j
            # Option 4: Sibling 1 to school j, Sibling 2 to school i
            
            # Calculate utilities (for synthetic data generation)
            # Together bonus
            together_bonus = 0.5
            
            # Utility components
            utility_base_i = school_i_quality - 0.3 * school_i_distance
            utility_base_j = school_j_quality - 0.3 * school_j_distance
            
            # Option utilities
            u_both_i = 2 * utility_base_i + together_bonus + np.random.gumbel()
            u_both_j = 2 * utility_base_j + together_bonus + np.random.gumbel()
            u_split_ij = utility_base_i + utility_base_j + np.random.gumbel()
            u_split_ji = utility_base_i + utility_base_j + np.random.gumbel()
            
            utilities = np.array([u_both_i, u_both_j, u_split_ij, u_split_ji])
            chosen_option = np.argmax(utilities)
            
            # Store data
            data.append({
                'respondent_id': respondent_id,
                'choice_id': choice_id,
                'household_size': household_size,
                'income_category': income_category,
                'parent_education': parent_education,
                'school_i_quality': school_i_quality,
                'school_j_quality': school_j_quality,
                'school_i_distance': school_i_distance,
                'school_j_distance': school_j_distance,
                'chosen_option': chosen_option,
                'option_0_chosen': int(chosen_option == 0),  # Both to school i
                'option_1_chosen': int(chosen_option == 1),  # Both to school j
                'option_2_chosen': int(chosen_option == 2),  # Split: sib1->i, sib2->j
                'option_3_chosen': int(chosen_option == 3),  # Split: sib1->j, sib2->i
            })
    
    return pd.DataFrame(data)

def create_covariates_matrix(df: pd.DataFrame) -> pd.DataFrame:
    """
    Create design matrix with covariates for estimation.
    
    Args:
        df: Raw survey data
        
    Returns:
        pd.DataFrame: Design matrix with covariates
    """
    # Create dummy variables for categorical covariates
    income_dummies = pd.get_dummies(df['income_category'], prefix='income')
    education_dummies = pd.get_dummies(df['parent_education'], prefix='education')
    
    # Combine with continuous variables (avoid duplication by selecting unique columns)
    covariates = pd.concat([
        df[['respondent_id', 'choice_id', 'household_size', 
            'school_i_quality', 'school_j_quality', 
            'school_i_distance', 'school_j_distance']],
        income_dummies,
        education_dummies
    ], axis=1)
    
    return covariates

def save_processed_data(df: pd.DataFrame, covariates: pd.DataFrame) -> None:
    """
    Save processed data to CSV files.
    
    Args:
        df: Survey response data
        covariates: Covariate matrix
    """
    os.makedirs('data', exist_ok=True)
    
    # Save main dataset
    df.to_csv('data/survey_responses.csv', index=False)
    print(f"Saved survey responses: {len(df)} observations")
    
    # Save covariates
    covariates.to_csv('data/covariates.csv', index=False)
    print(f"Saved covariates matrix: {covariates.shape}")
    
    # Save summary statistics
    summary_stats = df.describe()
    summary_stats.to_csv('data/summary_statistics.csv')
    print("Saved summary statistics")

def main():
    """Main execution function."""
    print("=" * 60)
    print("PREFERENCE ESTIMATION: Data Loading")
    print("=" * 60)
    
    # Load survey data
    print("\n1. Loading survey data...")
    survey_data = load_survey_data()
    
    # Create covariates matrix
    print("\n2. Creating covariates matrix...")
    covariates = create_covariates_matrix(survey_data)
    
    # Save processed data
    print("\n3. Saving processed data...")
    save_processed_data(survey_data, covariates)
    
    # Print data summary
    print("\n4. Data Summary:")
    print(f"   - Total observations: {len(survey_data)}")
    print(f"   - Unique respondents: {survey_data['respondent_id'].nunique()}")
    print(f"   - Choices per respondent: {survey_data.groupby('respondent_id').size().mean():.1f}")
    print(f"   - Covariate dimensions: {covariates.shape}")
    
    print("\n" + "=" * 60)
    print("Data loading completed successfully!")
    print("=" * 60)

if __name__ == "__main__":
    main()