#%%
from cb_da import da
import pandas as pd

path_siblings = "/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings/data/intermediate/feedback/2023/mineduc_simulations/"

for i in range(2, 4):

    vacancies = pd.read_csv(path_siblings + f"1_tables_simulation_format/{i}_simulation/vacancies.csv")    
    applicants = pd.read_csv(path_siblings + f"1_tables_simulation_format/{i}_simulation/applicants.csv")
    applications = pd.read_csv(path_siblings + f"1_tables_simulation_format/{i}_simulation/applications.csv")
    siblings = pd.read_csv(path_siblings + f"1_tables_simulation_format/{i}_simulation/siblings.csv")
    links = pd.read_csv(path_siblings + f"1_tables_simulation_format/{i}_simulation/links.csv")

    priority_profiles = pd.read_csv('/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings/data/intermediate/feedback/2023/jpal_to_public_data/SAE_2022_priority_profiles.csv')
    quota_order = pd.read_csv('/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings/data/intermediate/feedback/2023/jpal_to_public_data/SAE_2022_quota_order.csv')
        
    arguments = {'sibling_priority_activation' :        True,
                'linked_postulation_activation' :       True,
                'secured_enrollment_assignment' :       True,
                'forced_secured_enrollment_assignment': True,
                'transfer_capacity_activation' :        False
                }

    results = da(vacancies = vacancies,
                applicants = applicants,
                applications = applications,
                priority_profiles = priority_profiles,
                quota_order = quota_order,
                siblings = siblings,
                links = links,
                **arguments)

    results.to_csv(path_siblings + f"2_results/{i}_simulation.csv", index = False)    

#%%