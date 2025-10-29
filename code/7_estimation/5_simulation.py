"""
Simulation and Visualization Script

This script uses estimated parameters and data covariates to simulate preference
distributions and create summary visualizations.

Author: Preference Estimation Framework
Date: 2024
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats
import json
import os
from typing import Dict, Tuple, List, Any

# Import the likelihood module
import sys
import os
sys.path.append(os.path.dirname(__file__))
from likelihood_functions import ExplodedLogitLikelihood

# Set plotting style
plt.style.use('seaborn-v0_8-whitegrid')
sns.set_palette("husl")

class PreferenceSimulator:
    """
    Simulate preference distributions using estimated parameters.
    """
    
    def __init__(self, estimated_params: np.ndarray, param_names: List[str], 
                 data: pd.DataFrame, covariates: pd.DataFrame):
        """
        Initialize simulator with estimated parameters.
        
        Args:
            estimated_params: Estimated parameter vector
            param_names: Parameter names
            data: Original survey data
            covariates: Covariate matrix
        """
        self.params = estimated_params
        self.param_names = param_names
        self.data = data
        self.covariates = covariates
        
        # Initialize likelihood object for simulations
        self.likelihood = ExplodedLogitLikelihood(data, covariates)
        
        print(f"Initialized simulator with {len(self.params)} parameters")
    
    def simulate_choice_probabilities(self, n_scenarios: int = 1000) -> pd.DataFrame:
        """
        Simulate choice probabilities for different scenarios.
        
        Args:
            n_scenarios: Number of scenarios to simulate
            
        Returns:
            pd.DataFrame: Simulated choice probabilities
        """
        print(f"Simulating choice probabilities for {n_scenarios} scenarios...")
        
        # Create simulation scenarios with varying characteristics
        np.random.seed(123)  # For reproducibility
        
        scenarios = []
        for i in range(n_scenarios):
            # Generate scenario characteristics
            household_size = np.random.choice([2, 3, 4, 5], p=[0.1, 0.4, 0.4, 0.1])
            
            # School quality (standardized)
            quality_i = np.random.normal(0, 1)
            quality_j = np.random.normal(0, 1)
            
            # Distance (exponential distribution)
            distance_i = np.random.exponential(2)
            distance_j = np.random.exponential(2)
            
            # Income and education (categorical)
            income_medium = np.random.choice([0, 1], p=[0.5, 0.5])
            income_high = np.random.choice([0, 1], p=[0.8, 0.2])
            education_secondary = np.random.choice([0, 1], p=[0.5, 0.5])
            education_tertiary = np.random.choice([0, 1], p=[0.7, 0.3])
            
            scenarios.append([
                household_size, quality_i, quality_j, distance_i, distance_j,
                income_medium, income_high, education_secondary, education_tertiary
            ])
        
        # Convert to array
        X_sim = np.array(scenarios)
        
        # Calculate choice probabilities
        probs = self.likelihood.choice_probabilities(self.params, X_sim)
        
        # Create results dataframe
        results = pd.DataFrame({
            'scenario': range(n_scenarios),
            'prob_both_i': probs[:, 0],
            'prob_both_j': probs[:, 1], 
            'prob_split_ij': probs[:, 2],
            'prob_split_ji': probs[:, 3],
            'household_size': X_sim[:, 0],
            'quality_diff': X_sim[:, 1] - X_sim[:, 2],  # i - j
            'distance_diff': X_sim[:, 3] - X_sim[:, 4],  # i - j
            'income_medium': X_sim[:, 5],
            'income_high': X_sim[:, 6],
            'education_secondary': X_sim[:, 7],
            'education_tertiary': X_sim[:, 8]
        })
        
        # Add derived variables
        results['prob_together'] = results['prob_both_i'] + results['prob_both_j']
        results['prob_split'] = results['prob_split_ij'] + results['prob_split_ji']
        results['prefer_higher_quality'] = np.where(
            results['quality_diff'] > 0, 
            results['prob_both_i'], 
            results['prob_both_j']
        )
        
        return results
    
    def create_preference_distribution_plot(self, sim_results: pd.DataFrame) -> None:
        """
        Create plots showing distribution of preferences.
        
        Args:
            sim_results: Simulation results
        """
        fig, axes = plt.subplots(2, 2, figsize=(12, 10))
        
        # Plot 1: Distribution of together vs split preferences
        axes[0, 0].hist(sim_results['prob_together'], bins=30, alpha=0.7, 
                       label='Together', density=True)
        axes[0, 0].hist(sim_results['prob_split'], bins=30, alpha=0.7, 
                       label='Split', density=True)
        axes[0, 0].set_xlabel('Probability')
        axes[0, 0].set_ylabel('Density')
        axes[0, 0].set_title('Distribution of Together vs Split Preferences')
        axes[0, 0].legend()
        axes[0, 0].grid(True, alpha=0.3)
        
        # Plot 2: Preference by household size
        household_sizes = [2, 3, 4, 5]
        together_by_size = [sim_results[sim_results['household_size'] == size]['prob_together'].mean() 
                           for size in household_sizes]
        
        axes[0, 1].bar(household_sizes, together_by_size, alpha=0.7, color='skyblue')
        axes[0, 1].set_xlabel('Household Size')
        axes[0, 1].set_ylabel('Average Probability of Together')
        axes[0, 1].set_title('Together Preference by Household Size')
        axes[0, 1].grid(True, alpha=0.3)
        
        # Plot 3: Preference by quality difference
        quality_bins = [-3, -1, 0, 1, 3]
        sim_results['quality_bin'] = pd.cut(sim_results['quality_diff'], bins=quality_bins, 
                                           labels=['Much Lower', 'Lower', 'Higher', 'Much Higher'])
        
        quality_preference = sim_results.groupby('quality_bin')['prob_together'].mean()
        axes[1, 0].bar(range(len(quality_preference)), quality_preference.values, 
                      alpha=0.7, color='lightgreen')
        axes[1, 0].set_xlabel('School i Quality vs School j')
        axes[1, 0].set_ylabel('Average Probability of Together')
        axes[1, 0].set_title('Together Preference by Quality Difference')
        axes[1, 0].set_xticks(range(len(quality_preference)))
        axes[1, 0].set_xticklabels(quality_preference.index, rotation=45)
        axes[1, 0].grid(True, alpha=0.3)
        
        # Plot 4: Preference by income and education
        income_education_groups = [
            ('Low Income, Low Education', 
             (sim_results['income_medium'] == 0) & (sim_results['income_high'] == 0) & 
             (sim_results['education_secondary'] == 0) & (sim_results['education_tertiary'] == 0)),
            ('Medium Income, Secondary Education', 
             (sim_results['income_medium'] == 1) & (sim_results['education_secondary'] == 1)),
            ('High Income, Tertiary Education', 
             (sim_results['income_high'] == 1) & (sim_results['education_tertiary'] == 1))
        ]
        
        group_preferences = []
        group_labels = []
        for label, mask in income_education_groups:
            if mask.sum() > 0:
                group_preferences.append(sim_results[mask]['prob_together'].mean())
                group_labels.append(label)
        
        axes[1, 1].bar(range(len(group_preferences)), group_preferences, 
                      alpha=0.7, color='coral')
        axes[1, 1].set_xlabel('Income-Education Group')
        axes[1, 1].set_ylabel('Average Probability of Together')
        axes[1, 1].set_title('Together Preference by Socioeconomic Status')
        axes[1, 1].set_xticks(range(len(group_labels)))
        axes[1, 1].set_xticklabels([label.replace(', ', '\n') for label in group_labels], 
                                  fontsize=8)
        axes[1, 1].grid(True, alpha=0.3)
        
        plt.tight_layout()
        
        # Save plot
        os.makedirs('figures', exist_ok=True)
        plt.savefig('figures/preference_distribution.png', dpi=300, bbox_inches='tight')
        print("Saved preference distribution plot: figures/preference_distribution.png")
        
        plt.show()
    
    def create_covariate_effects_plot(self) -> None:
        """
        Create plot showing estimated covariate effects.
        """
        # Extract covariate effects from parameters
        covariate_effects = {}
        
        for i, param_name in enumerate(self.param_names):
            if param_name.startswith('together_bonus_'):
                covariate_name = param_name.replace('together_bonus_', '')
                covariate_effects[covariate_name] = self.params[i]
        
        if not covariate_effects:
            print("No covariate effects found in parameters")
            return
        
        # Create plot
        fig, ax = plt.subplots(1, 1, figsize=(10, 6))
        
        # Sort effects by magnitude
        sorted_effects = sorted(covariate_effects.items(), key=lambda x: abs(x[1]), reverse=True)
        
        names = [name.replace('_', ' ').title() for name, _ in sorted_effects]
        effects = [effect for _, effect in sorted_effects]
        colors = ['red' if effect < 0 else 'blue' for effect in effects]
        
        bars = ax.barh(range(len(names)), effects, color=colors, alpha=0.7)
        ax.set_yticks(range(len(names)))
        ax.set_yticklabels(names)
        ax.set_xlabel('Effect on Together Bonus')
        ax.set_title('Estimated Covariate Effects on Together Preference')
        ax.axvline(x=0, color='black', linestyle='--', alpha=0.5)
        ax.grid(True, alpha=0.3)
        
        # Add value labels on bars
        for i, (bar, effect) in enumerate(zip(bars, effects)):
            ax.text(effect + (0.01 if effect > 0 else -0.01), i, f'{effect:.3f}', 
                   va='center', ha='left' if effect > 0 else 'right')
        
        plt.tight_layout()
        
        # Save plot
        os.makedirs('figures', exist_ok=True)
        plt.savefig('figures/covariate_effects.png', dpi=300, bbox_inches='tight')
        print("Saved covariate effects plot: figures/covariate_effects.png")
        
        plt.show()
    
    def create_utility_surface_plot(self) -> None:
        """
        Create 3D surface plot showing utility as function of key variables.
        """
        # Create grid of quality and distance values
        quality_range = np.linspace(-2, 2, 20)
        distance_range = np.linspace(0.5, 4, 20)
        
        Q, D = np.meshgrid(quality_range, distance_range)
        
        # Calculate utilities for "both together at school i" vs "split"
        # Using median values for other covariates
        median_covariates = np.array([3, 0, 0, 2, 2, 0, 0, 1, 0])  # Median/mode values
        
        utility_together = np.zeros_like(Q)
        utility_split = np.zeros_like(Q)
        
        for i in range(Q.shape[0]):
            for j in range(Q.shape[1]):
                # Create scenario
                scenario = median_covariates.copy()
                scenario[1] = Q[i, j]  # quality_i
                scenario[2] = 0        # quality_j (reference)
                scenario[3] = D[i, j]  # distance_i
                scenario[4] = 2        # distance_j (reference)
                
                # Calculate utilities
                utilities = self.likelihood.utility_functions(self.params, scenario.reshape(1, -1))
                utility_together[i, j] = utilities[0, 0]  # Both to school i
                utility_split[i, j] = utilities[0, 2]     # Split arrangement
        
        # Create plot
        fig = plt.figure(figsize=(12, 5))
        
        # Utility difference surface
        ax1 = fig.add_subplot(121, projection='3d')
        utility_diff = utility_together - utility_split
        
        surf = ax1.plot_surface(Q, D, utility_diff, cmap='RdYlBu', alpha=0.8)
        ax1.set_xlabel('School Quality')
        ax1.set_ylabel('Distance')
        ax1.set_zlabel('Utility Difference (Together - Split)')
        ax1.set_title('Utility Difference Surface')
        
        # Contour plot
        ax2 = fig.add_subplot(122)
        contour = ax2.contour(Q, D, utility_diff, levels=15, cmap='RdYlBu')
        ax2.clabel(contour, inline=True, fontsize=8)
        ax2.set_xlabel('School Quality')
        ax2.set_ylabel('Distance')
        ax2.set_title('Utility Difference Contours')
        ax2.grid(True, alpha=0.3)
        
        plt.tight_layout()
        
        # Save plot
        os.makedirs('figures', exist_ok=True)
        plt.savefig('figures/utility_surface.png', dpi=300, bbox_inches='tight')
        print("Saved utility surface plot: figures/utility_surface.png")
        
        plt.show()
    
    def generate_simulation_summary(self, sim_results: pd.DataFrame) -> str:
        """
        Generate text summary of simulation results.
        
        Args:
            sim_results: Simulation results
            
        Returns:
            str: Summary text
        """
        summary = []
        
        summary.append("SIMULATION RESULTS SUMMARY")
        summary.append("=" * 50)
        summary.append("")
        
        # Overall preferences
        avg_together = sim_results['prob_together'].mean()
        avg_split = sim_results['prob_split'].mean()
        
        summary.append("OVERALL PREFERENCE PATTERNS:")
        summary.append("-" * 35)
        summary.append(f"Average probability of keeping siblings together: {avg_together:.3f}")
        summary.append(f"Average probability of splitting siblings: {avg_split:.3f}")
        summary.append("")
        
        # By household characteristics
        summary.append("PREFERENCES BY HOUSEHOLD SIZE:")
        summary.append("-" * 35)
        for size in [2, 3, 4, 5]:
            subset = sim_results[sim_results['household_size'] == size]
            if len(subset) > 0:
                avg_pref = subset['prob_together'].mean()
                summary.append(f"Household size {size}: {avg_pref:.3f}")
        summary.append("")
        
        # By quality difference
        summary.append("PREFERENCES BY QUALITY DIFFERENCE:")
        summary.append("-" * 40)
        quality_quartiles = sim_results['quality_diff'].quantile([0.25, 0.5, 0.75])
        
        for i, (label, threshold) in enumerate([("Low", quality_quartiles[0.25]), 
                                              ("Medium", quality_quartiles[0.5]), 
                                              ("High", quality_quartiles[0.75])]):
            if i == 0:
                subset = sim_results[sim_results['quality_diff'] <= threshold]
            elif i == 1:
                subset = sim_results[(sim_results['quality_diff'] > quality_quartiles[0.25]) & 
                                   (sim_results['quality_diff'] <= threshold)]
            else:
                subset = sim_results[sim_results['quality_diff'] > quality_quartiles[0.5]]
            
            if len(subset) > 0:
                avg_pref = subset['prob_together'].mean()
                summary.append(f"{label} quality difference: {avg_pref:.3f}")
        
        summary.append("")
        summary.append("Note: Results based on simulation with estimated parameters")
        summary.append("and synthetic data for testing purposes.")
        
        return "\n".join(summary)

def load_estimation_results() -> Tuple[np.ndarray, List[str], Dict[str, Any]]:
    """
    Load estimation results for simulation.
    
    Returns:
        Tuple: (parameters, parameter_names, summary)
    """
    try:
        # Load parameters
        params_df = pd.read_csv('results/parameter_estimates.csv')
        parameters = params_df['estimate'].values
        param_names = params_df['parameter'].tolist()
        
        # Load summary
        with open('results/estimation_summary.json', 'r') as f:
            summary = json.load(f)
        
        return parameters, param_names, summary
        
    except FileNotFoundError as e:
        print(f"Results files not found: {e}")
        return None, None, None

def main():
    """Main execution function."""
    print("=" * 60)
    print("PREFERENCE ESTIMATION: Simulation and Visualization")
    print("=" * 60)
    
    # Load estimation results
    print("Loading estimation results...")
    parameters, param_names, summary = load_estimation_results()
    
    if parameters is None:
        print("Could not load estimation results. Please run 3_estimation.py first.")
        return
    
    # Load data
    print("Loading data...")
    try:
        data = pd.read_csv('data/survey_responses.csv')
        covariates = pd.read_csv('data/covariates.csv')
    except FileNotFoundError:
        print("Data files not found. Please run 1_load_data.py first.")
        return
    
    # Initialize simulator
    print("Initializing simulator...")
    simulator = PreferenceSimulator(parameters, param_names, data, covariates)
    
    # Run simulations
    print("\n" + "-" * 60)
    print("Running preference simulations...")
    sim_results = simulator.simulate_choice_probabilities(n_scenarios=2000)
    
    # Create visualizations
    print("\n" + "-" * 60)
    print("Creating visualizations...")
    
    simulator.create_preference_distribution_plot(sim_results)
    simulator.create_covariate_effects_plot()
    simulator.create_utility_surface_plot()
    
    # Generate summary
    print("\n" + "-" * 60)
    print("Generating simulation summary...")
    summary_text = simulator.generate_simulation_summary(sim_results)
    
    # Save summary
    os.makedirs('results', exist_ok=True)
    with open('results/simulation_summary.txt', 'w') as f:
        f.write(summary_text)
    
    # Save simulation results
    sim_results.to_csv('results/simulation_results.csv', index=False)
    
    print("\n" + "=" * 60)
    print("SIMULATION SUMMARY")
    print("=" * 60)
    print(summary_text)
    
    print("\n" + "=" * 60)
    print("Simulation and visualization completed!")
    print("Files generated:")
    print("  - figures/preference_distribution.png")
    print("  - figures/covariate_effects.png")
    print("  - figures/utility_surface.png")
    print("  - results/simulation_summary.txt")
    print("  - results/simulation_results.csv")
    print("=" * 60)

if __name__ == "__main__":
    main()