from cb_da import da
import pandas as pd

Path = "/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings/data/intermediate/feedback/2023/daily_simulations/"

suffixes = [
    "08-09", "08-10", "08-14", "08-16", "08-17", "08-18", "08-21", 
    "08-22", "08-23", "08-24", "08-25", "08-27", "08-28", "08-29", 
    "08-30", "08-31", "09-01", "09-02", "09-03", "09-04", "09-05", "09-20"]

for s in suffixes:

    vacancies = pd.read_csv(Path + "2_tables_simulation_format/" + 'vacancies_' + s + '.csv')
    applicants = pd.read_csv(Path + "2_tables_simulation_format/" + 'applicants_' + s + '.csv')
    applications = pd.read_csv(Path + "2_tables_simulation_format/" + 'applications_' + s + '.csv')
    siblings = pd.read_csv(Path + "2_tables_simulation_format/" + 'siblings_' + s + '.csv')
    links = pd.read_csv(Path + "2_tables_simulation_format/" + 'links_' + s + '.csv')

    priority_profiles = pd.read_csv('/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings/data/intermediate/feedback/2023/jpal_to_public_data/SAE_2022_priority_profiles.csv')
    quota_order = pd.read_csv('/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings/data/intermediate/feedback/2023/jpal_to_public_data/SAE_2022_quota_order.csv')

    results_applications = applications.loc[(applications.quota_id == 1)]

    # Pegamos los tipos
    results_applications['n_assigned'] = 0
        
    arguments = {'sibling_priority_activation' :        True,
                'linked_postulation_activation' :       True,
                'secured_enrollment_assignment' :       True,
                'forced_secured_enrollment_assignment': True,
                'transfer_capacity_activation' :        False,
                'tie_break_method':                     'multiple',
                'tie_break_level':                      'program',
                'sibling_lottery':                      True,
                'seed':                                 0
                }

    results = da(vacancies = vacancies,
                applicants = applicants,
                applications = applications,
                priority_profiles = priority_profiles,
                quota_order = quota_order,
                siblings = siblings,
                links = links,
                **arguments)

    results.to_csv(Path + '3_results/' + 'results_' + s + '.csv', index=False)
    
