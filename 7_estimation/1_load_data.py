"""
Data Loading and Preprocessing Script

This script loads survey response data on preferences over joint allocations
and formats it for likelihood estimation.

Author: Javiera Gazmuri
Date: Oct 2025
"""
# %%

import numpy as np
import pandas as pd
import os
from typing import Tuple, Dict, Any

""""
NOTAS:
1) Agregar covariates (con y sin distancia):
- Distance (distancias marginales y between)
- Cosas de la cartilla (promedio para split)

Resp:
- Survey: id_postulante, id_apoderado
- School data: 'SAE 2023/cartillas/cartillas_postulación/1_etapa_regular/4_research_tables/oferta/options_feedback_2023_08_28.csv'
- Applicant data: 'SAE 2023/cartillas/cartillas_postulación/1_etapa_regular/4_research_tables/applications/datos_jpal/datos_jpal_2023_08_28.csv'

"""
from path_config import APPLICANTS, BASE_PATH, PROGRAMS, SURVEY_FILE

#applicants = pd.read_csv(APPLICANTS)
#applicants = applicants[['id_postulante', 'id_apoderado', 'orden', 'rbd', 'cod_curso']]

#programs = pd.read_csv(PROGRAMS)
#programs = programs[['campus_name', 'rbd','cod_curso', 'sch_lon','sch_lat','quality_category_label']]

#app_programs = applicants.merge(programs, on = ['rbd','cod_curso'], how = 'left') # All merge 



def load_survey_data() -> pd.DataFrame:
    """
    Load survey data on preferences over joint allocations.
    
    Returns:
        pd.DataFrame: Cleaned survey response data
    """
    # Use real survey answers from 0_path.py
    from path_config import SURVEY_FILE, BASE_PATH
    print(f"Loading survey data from: {SURVEY_FILE}")
    df = pd.read_csv(SURVEY_FILE)

    print("Applying cleaning steps...")
    print(f"Initial observations: {len(df)}")
    
    # Drop if id_apoderado is empty
    df = df[df['id_apoderado'].notna() & (df['id_apoderado'] != "")]
    print(f"After dropping empty id_apoderado: {len(df)}")
    
    # Keep if sibl04_1 is not empty
    if 'sibl04_1' in df.columns:
        df = df[df['sibl04_1'].notna() & (df['sibl04_1'] != "")]
        print(f"After keeping non-empty sibl04_1: {len(df)}")

    # Merge id_mayor and id_menor from separate encoded files (deduplicate first)
    SURVEY_MAYOR = BASE_PATH + 'encuesta/inputs/seccion_hermanos/dropdown_mayor_encoded.csv'
    mayor_df = pd.read_csv(SURVEY_MAYOR, usecols=['id_apoderado', 'id_mayor'])
    mayor_df = mayor_df.drop_duplicates(subset='id_apoderado')
    df = df.merge(mayor_df, on='id_apoderado', how='left')

    SURVEY_MENOR = BASE_PATH + 'encuesta/inputs/seccion_hermanos/dropdown_menor_encoded.csv'
    menor_df = pd.read_csv(SURVEY_MENOR, usecols=['id_apoderado', 'id_menor'])
    menor_df = menor_df.drop_duplicates(subset='id_apoderado')
    df = df.merge(menor_df, on='id_apoderado', how='left')  

    # Keep only relevant columns (include id_postulante and orden)
    keep_cols = ['id_postulante', 'id_apoderado', 'orden', 'opcion_seleccionada', 'cant_common_rbd', 'id_mayor', 'id_menor','sibl04_1','sibl04_2','sibl05_menor','sibl05_mayor','sibl06_menos','sibl06_mas']
    # Add any schjoint0* columns that hold rankings / school IDs
    keep_cols += [col for col in df.columns if col.startswith('schjoint0')]
    keep_cols += [col for col in df.columns if col.startswith('schmayor0')]
    keep_cols += [col for col in df.columns if col.startswith('schmenor0')]

    # Only keep columns that actually exist in the file to avoid KeyError
    keep_cols = [c for c in keep_cols if c in df.columns]
    df = df[keep_cols]
    print(f"Final number of columns: {len(df.columns)}")
    
    return df

    return df

"""
This function has been temporarily removed while we focus on survey data loading and cleaning.
"""

def save_processed_data(df: pd.DataFrame) -> None:
    """
    Save processed data to CSV files.
    
    Args:
        df: Survey response data
    """
    os.makedirs('data', exist_ok=True)
    
    # Save main dataset
    df.to_csv('data/survey_responses.csv', index=False)
    print(f"Saved survey responses: {len(df)} observations")

def main():
    """Main execution function."""
    print("=" * 60)
    print("PREFERENCE ESTIMATION: Data Loading")
    print("=" * 60)
    
    # Load survey data
    print("\n1. Loading survey data...")
    survey_data = load_survey_data()
    
    # Save processed data
    print("\n2. Saving processed data...")
    save_processed_data(survey_data)
    
    # Print data summary
    print("\n3. Data Summary:")
    print(f"   - Total observations: {len(survey_data)}")
    print(f"   - Unique respondents: {survey_data['id_apoderado'].nunique()}")
    
    print("\n" + "=" * 60)
    print("Data loading completed successfully!")
    print("=" * 60)

if __name__ == "__main__":
    main()
# %%
