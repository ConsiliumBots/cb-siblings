"""
Results Table Generation Script

This script reads estimated parameters and formats them into publication-ready tables.

Author: Preference Estimation Framework
Date: 2024
"""

import pandas as pd
import numpy as np
import json
import os
from typing import Dict, Any

def load_estimation_results() -> Dict[str, Any]:
    """
    Load estimation results from files.
    
    Returns:
        Dict: Combined estimation results
    """
    results = {}
    
    # Load parameter estimates
    try:
        params_df = pd.read_csv('results/parameter_estimates.csv')
        results['parameters'] = params_df
        print(f"Loaded {len(params_df)} parameter estimates")
    except FileNotFoundError:
        print("Parameter estimates file not found")
        return None
    
    # Load summary statistics
    try:
        with open('results/estimation_summary.json', 'r') as f:
            summary = json.load(f)
        results['summary'] = summary
        print("Loaded estimation summary")
    except FileNotFoundError:
        print("Warning: Estimation summary not found")
        results['summary'] = {}
    
    return results

def format_parameter_table(params_df: pd.DataFrame) -> pd.DataFrame:
    """
    Format parameter estimates into a publication-ready table.
    
    Args:
        params_df: Raw parameter estimates
        
    Returns:
        pd.DataFrame: Formatted parameter table
    """
    # Create formatted table
    formatted_table = params_df.copy()
    
    # Calculate significance levels
    formatted_table['p_value'] = 2 * (1 - np.abs(formatted_table['t_stat']))
    formatted_table['significant'] = formatted_table['p_value'] < 0.05
    
    # Create formatted estimate column with standard errors
    def format_estimate(row):
        estimate = f"{row['estimate']:.4f}"
        std_err = f"({row['std_error']:.4f})"
        
        # Add significance stars
        if row['p_value'] < 0.01:
            estimate += "***"
        elif row['p_value'] < 0.05:
            estimate += "**" 
        elif row['p_value'] < 0.10:
            estimate += "*"
            
        return f"{estimate}\\n{std_err}"
    
    formatted_table['formatted_estimate'] = formatted_table.apply(format_estimate, axis=1)
    
    # Create clean parameter names for display
    param_name_mapping = {
        'quality_own': 'Own Quality Preference',
        'quality_sibling': 'Sibling Quality Preference',
        'distance_coeff': 'Distance Disutility',
        'together_bonus_base': 'Together Bonus (Base)',
        'together_bonus_household_size': 'Together Bonus × Household Size',
        'together_bonus_school_i_quality': 'Together Bonus × School i Quality',
        'together_bonus_school_j_quality': 'Together Bonus × School j Quality',
        'together_bonus_school_i_distance': 'Together Bonus × School i Distance',
        'together_bonus_school_j_distance': 'Together Bonus × School j Distance',
        'together_bonus_income_medium': 'Together Bonus × Medium Income',
        'together_bonus_income_high': 'Together Bonus × High Income',
        'together_bonus_education_secondary': 'Together Bonus × Secondary Education',
        'together_bonus_education_tertiary': 'Together Bonus × Tertiary Education'
    }
    
    formatted_table['display_name'] = formatted_table['parameter'].map(
        lambda x: param_name_mapping.get(x, x.replace('_', ' ').title())
    )
    
    return formatted_table

def create_latex_table(formatted_table: pd.DataFrame, summary: Dict[str, Any]) -> str:
    """
    Create LaTeX formatted table.
    
    Args:
        formatted_table: Formatted parameter table
        summary: Estimation summary statistics
        
    Returns:
        str: LaTeX table code
    """
    latex_code = []
    
    # Table header
    latex_code.append("\\begin{table}[htbp]")
    latex_code.append("\\centering")
    latex_code.append("\\caption{Preference Estimation Results}")
    latex_code.append("\\label{tab:preference_estimates}")
    latex_code.append("\\begin{tabular}{lc}")
    latex_code.append("\\toprule")
    latex_code.append("Parameter & Estimate \\\\")
    latex_code.append("\\midrule")
    
    # Add parameters by category
    categories = {
        'Quality Preferences': ['quality_own', 'quality_sibling'],
        'Distance and Together Bonus': ['distance_coeff', 'together_bonus_base'],
        'Interaction Effects': [p for p in formatted_table['parameter'] 
                               if p.startswith('together_bonus_') and p != 'together_bonus_base']
    }
    
    for category, param_list in categories.items():
        latex_code.append(f"\\multicolumn{{2}}{{l}}{{\\textbf{{{category}}}}} \\\\")
        
        for param in param_list:
            row = formatted_table[formatted_table['parameter'] == param]
            if len(row) > 0:
                display_name = row.iloc[0]['display_name']
                estimate = f"{row.iloc[0]['estimate']:.4f}"
                std_err = f"({row.iloc[0]['std_error']:.4f})"
                
                # Add significance stars
                p_val = row.iloc[0]['p_value']
                if p_val < 0.01:
                    estimate += "***"
                elif p_val < 0.05:
                    estimate += "**"
                elif p_val < 0.10:
                    estimate += "*"
                
                latex_code.append(f"\\quad {display_name} & {estimate} \\\\")
                latex_code.append(f"& {std_err} \\\\")
        
        latex_code.append("\\\\")
    
    # Table footer with summary statistics
    latex_code.append("\\midrule")
    latex_code.append("\\multicolumn{2}{l}{\\textbf{Model Statistics}} \\\\")
    
    if summary:
        latex_code.append(f"Log-likelihood & {summary.get('log_likelihood', 'N/A'):.4f} \\\\")
        latex_code.append(f"AIC & {summary.get('aic', 'N/A'):.4f} \\\\")
        latex_code.append(f"BIC & {summary.get('bic', 'N/A'):.4f} \\\\")
        latex_code.append(f"Observations & {summary.get('n_observations', 'N/A'):,} \\\\")
        latex_code.append(f"Parameters & {summary.get('n_parameters', 'N/A')} \\\\")
    
    latex_code.append("\\bottomrule")
    latex_code.append("\\end{tabular}")
    latex_code.append("\\begin{flushleft}")
    latex_code.append("\\footnotesize")
    latex_code.append("Standard errors in parentheses. ")
    latex_code.append("*** p$<$0.01, ** p$<$0.05, * p$<$0.10")
    latex_code.append("\\end{flushleft}")
    latex_code.append("\\end{table}")
    
    return "\n".join(latex_code)

def create_summary_table(summary: Dict[str, Any]) -> pd.DataFrame:
    """
    Create summary statistics table.
    
    Args:
        summary: Estimation summary
        
    Returns:
        pd.DataFrame: Summary table
    """
    summary_data = []
    
    if summary:
        summary_data = [
            ['Log-likelihood', f"{summary.get('log_likelihood', 'N/A'):.4f}"],
            ['AIC', f"{summary.get('aic', 'N/A'):.4f}"],
            ['BIC', f"{summary.get('bic', 'N/A'):.4f}"],
            ['Observations', f"{summary.get('n_observations', 'N/A'):,}"],
            ['Parameters', f"{summary.get('n_parameters', 'N/A')}"],
            ['Method', summary.get('method', 'N/A')],
            ['Iterations', f"{summary.get('iterations', 'N/A')}"],
            ['Estimation Time (sec)', f"{summary.get('estimation_time', 'N/A'):.2f}"]
        ]
    
    return pd.DataFrame(summary_data, columns=['Statistic', 'Value'])

def generate_interpretation(formatted_table: pd.DataFrame) -> str:
    """
    Generate interpretation of results.
    
    Args:
        formatted_table: Formatted parameter table
        
    Returns:
        str: Interpretation text
    """
    interpretation = []
    
    interpretation.append("INTERPRETATION OF ESTIMATION RESULTS")
    interpretation.append("=" * 50)
    interpretation.append("")
    
    # Key findings
    quality_own = formatted_table[formatted_table['parameter'] == 'quality_own']['estimate'].iloc[0]
    quality_sibling = formatted_table[formatted_table['parameter'] == 'quality_sibling']['estimate'].iloc[0]
    distance_coeff = formatted_table[formatted_table['parameter'] == 'distance_coeff']['estimate'].iloc[0]
    together_bonus = formatted_table[formatted_table['parameter'] == 'together_bonus_base']['estimate'].iloc[0]
    
    interpretation.append("KEY FINDINGS:")
    interpretation.append("-" * 20)
    interpretation.append(f"• Own quality preference: {quality_own:.4f}")
    interpretation.append(f"• Sibling quality preference: {quality_sibling:.4f}")
    interpretation.append(f"• Distance disutility: {distance_coeff:.4f}")
    interpretation.append(f"• Together bonus: {together_bonus:.4f}")
    interpretation.append("")
    
    # Economic interpretation
    interpretation.append("ECONOMIC INTERPRETATION:")
    interpretation.append("-" * 30)
    
    if quality_own > quality_sibling:
        interpretation.append("• Parents value own child's school quality more than sibling's")
    elif quality_sibling > quality_own:
        interpretation.append("• Parents value sibling's school quality more than own child's")
    else:
        interpretation.append("• Parents value both children's school quality equally")
    
    if distance_coeff < 0:
        interpretation.append("• Distance creates disutility as expected")
    else:
        interpretation.append("• Unexpected positive distance coefficient")
    
    if together_bonus > 0:
        interpretation.append("• Positive preference for keeping siblings together")
    else:
        interpretation.append("• No preference (or negative preference) for keeping siblings together")
    
    interpretation.append("")
    interpretation.append("Note: This interpretation is based on synthetic data for testing purposes.")
    
    return "\n".join(interpretation)

def main():
    """Main execution function."""
    print("=" * 60)
    print("PREFERENCE ESTIMATION: Results Tables")
    print("=" * 60)
    
    # Load results
    print("Loading estimation results...")
    results = load_estimation_results()
    
    if results is None:
        print("Could not load results. Please run 3_estimation.py first.")
        return
    
    # Format parameter table
    print("\nFormatting parameter table...")
    formatted_table = format_parameter_table(results['parameters'])
    
    # Create output directory
    os.makedirs('results', exist_ok=True)
    
    # Save formatted table
    formatted_table.to_csv('results/formatted_parameter_table.csv', index=False)
    print("Saved formatted parameter table")
    
    # Create LaTeX table
    print("Creating LaTeX table...")
    latex_table = create_latex_table(formatted_table, results['summary'])
    
    with open('results/parameter_table.tex', 'w') as f:
        f.write(latex_table)
    print("Saved LaTeX table: results/parameter_table.tex")
    
    # Create summary table
    print("Creating summary statistics table...")
    summary_table = create_summary_table(results['summary'])
    summary_table.to_csv('results/summary_statistics_table.csv', index=False)
    
    # Generate interpretation
    print("Generating interpretation...")
    interpretation = generate_interpretation(formatted_table)
    
    with open('results/interpretation.txt', 'w') as f:
        f.write(interpretation)
    print("Saved interpretation: results/interpretation.txt")
    
    # Display results summary
    print("\n" + "=" * 60)
    print("RESULTS SUMMARY")
    print("=" * 60)
    
    print("\nParameter Estimates:")
    print("-" * 40)
    for _, row in formatted_table.iterrows():
        significance = ""
        if row['p_value'] < 0.01:
            significance = "***"
        elif row['p_value'] < 0.05:
            significance = "**"
        elif row['p_value'] < 0.10:
            significance = "*"
        
        print(f"{row['display_name']:30s}: {row['estimate']:8.4f}{significance:3s} ({row['std_error']:.4f})")
    
    if results['summary']:
        print(f"\nModel Statistics:")
        print(f"Log-likelihood: {results['summary'].get('log_likelihood', 'N/A'):.4f}")
        print(f"AIC: {results['summary'].get('aic', 'N/A'):.4f}")
        print(f"BIC: {results['summary'].get('bic', 'N/A'):.4f}")
    
    print("\n" + "=" * 60)
    print("Results table generation completed!")
    print("Files saved:")
    print("  - results/formatted_parameter_table.csv")
    print("  - results/parameter_table.tex")
    print("  - results/summary_statistics_table.csv") 
    print("  - results/interpretation.txt")
    print("=" * 60)

if __name__ == "__main__":
    main()