from cb_da import da
import pandas as pd

Inputs_Path = "/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings/data/intermediate/feedback/2023/jpal_to_public_data/"
Outputs_Path = "/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings/data/outputs/feedback_simulations/"

#context = "pre_feedback/"
context = "post_feedback/"

vacancies = pd.read_csv(Inputs_Path + context + 'vacancies.csv')
applicants = pd.read_csv(Inputs_Path + context + 'applicants.csv')
applications = pd.read_csv(Inputs_Path + context + 'applications.csv')
priority_profiles = pd.read_csv(Inputs_Path + 'SAE_2022_priority_profiles.csv')
quota_order = pd.read_csv(Inputs_Path + 'SAE_2022_quota_order.csv')
siblings = pd.read_csv(Inputs_Path + context + 'siblings.csv')
links = pd.read_csv(Inputs_Path + context + 'links.csv')


results_applications = applications.loc[(applications.quota_id == 1)]

# Pegamos los tipos
results_applications['n_assigned'] = 0

for i in range(0,100):
    
    arguments = {'sibling_priority_activation' :        True,
                'linked_postulation_activation' :       True,
                'secured_enrollment_assignment' :       True,
                'forced_secured_enrollment_assignment': True,
                'transfer_capacity_activation' :        False,
                'tie_break_method':                     'multiple',
                'tie_break_level':                      'program',
                'sibling_lottery':                      True,
                'seed':                                 i
                }

    results = da(vacancies = vacancies,
                applicants = applicants,
                applications = applications,
                priority_profiles = priority_profiles,
                quota_order = quota_order,
                siblings = siblings,
                links = links,
                **arguments)

    results = results[['applicant_id','institution_id','program_id']]
    results_applications = pd.merge(results_applications, results, how = 'left', left_on = ['applicant_id','institution_id','program_id'], right_on = ['applicant_id','institution_id','program_id'], indicator = True)
    results_applications.loc[(results_applications['_merge'] == 'both'), 'n_assigned'] = results_applications['n_assigned'] + 1
    del results_applications['_merge']
    print(i)

results_applications.to_csv(Outputs_Path + context + 'results.csv',index=False)
