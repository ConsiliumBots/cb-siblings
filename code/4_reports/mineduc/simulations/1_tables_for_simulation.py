#%%
# -----------------------------------------------------------------------------
# File Description
# -----------------------------------------------------------------------------
	# Project: Siblings
    # Objective: Transform public data (files A, B, C, D and F) of 2023 SAE 
    # and turn in the format required to run DA of Consilium/Tether.
    # Created: June 14, 2024 by Javi Gazmuri
    # Last Modified: June 17, 2024 by Javi Gazmuri

    # IMPORTANT: Search the crosswalk_programs file for explorer-consistent program_ids

# -----------------------------------------------------------------------------

import pandas as pd
import math

path_sae = "/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings/data/inputs/SAE_2023/"
path_siblings = "/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings/data/intermediate/feedback/2023/"

A1 = pd.read_csv(path_sae + "A1_Oferta_Establecimientos_etapa_regular_2023_Admisión_2024.csv", delimiter=';')
B1 = pd.read_csv(path_sae + "B1_Postulantes_etapa_regular_2023_Admisión_2024_PUBL.csv", delimiter=';')
C1 = pd.read_csv(path_sae + "C1_Postulaciones_etapa_regular_2023_Admisión_2024_PUBL.csv", delimiter=';')
F1 = pd.read_csv(path_sae + "F1_Relaciones_entre_postulantes_etapa_regular_2023_Admisión_2024_PUBL.csv", delimiter=';')

crosswalk = pd.read_csv("/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/ChileSAE/SAE 2023/cartillas/cartillas_postulación/1_etapa_regular/1_inputs/correlativas_SAE_explorador/public_offer_TO_explorer_program_id.csv")
crosswalk = crosswalk.rename(columns={'rbd':'institution_id','program_id':'new_program_id'})

priority_profiles = pd.read_csv(path_siblings + 'jpal_to_public_data/SAE_2022_priority_profiles.csv')
#%%
# -----------------------------------------------------------------------------
# Original assignment
# -----------------------------------------------------------------------------

def pd_level_priority_profile_translate(df):
    priority_profiles = (df['prioridad_matriculado']*33) + (1-df['prioridad_matriculado'])*(
        df['prioridad_hermano']*(15+16*df['prioridad_neep']+df['prioridad_alta_exigencia']) + (1-df['prioridad_hermano'])*(
            df['prioridad_hijo_funcionario']*(9+16*df['prioridad_neep'] +2*df['prioridad_alta_exigencia'] +1*df['prioridad_prioritario']) + (1-df['prioridad_hijo_funcionario'])*(
                df['prioridad_exalumno']*(5+16*df['prioridad_neep'] +2*df['prioridad_alta_exigencia'] +1*df['prioridad_prioritario']) + (1-df['prioridad_exalumno'])*(
                    1+16*df['prioridad_neep'] +2*df['prioridad_alta_exigencia'] +1*df['prioridad_prioritario']
                )
            )
        ))
    return priority_profiles


def nextpow10(n):
    if n>1:
        return 10 ** math.ceil(math.log10(n))
    else:
        return 1


    #Filtramos columnas relevantes de programas y cambiamos nombres
programs = A1.rename(columns={'rbd':'institution_id',
                                'cod_nivel':'grade_id'
                                }).drop(columns=['cod_ense','cod_grado','cod_jor','cod_espe','cod_sede',
                                                'con_copago','solo_hombres','solo_mujeres','lat','lon',
                                                'vacantes',
                                                'cupos_totales','tiene_orden_pie'], errors='ignore')


temp_program_ids = crosswalk[['institution_id','cod_curso','new_program_id']]

programs_index_df = temp_program_ids.set_index(['institution_id','cod_curso'])['new_program_id']
# Generamos un mapeo de rbd-codcurso a un único program_id
programs_index_dict = programs_index_df.to_dict()

programs = pd.merge(programs,temp_program_ids,on=['institution_id','cod_curso'])    
programs = programs.drop(columns=['cod_curso'])
programs = programs.rename(columns={'new_program_id':'program_id'})

assert programs.program_id.isna().sum()==0, "Nan program_ids"

# Guardamos info de tiene_orden_alta_t
if not 'tiene_orden_alta_t' in programs.columns:
    programs['tiene_orden_alta_t'] = 0
temp_programs_ae = programs[['program_id','tiene_orden_alta_t']].drop_duplicates().copy()
temp_programs_ae = temp_programs_ae.rename(columns={'tiene_orden_alta_t':'establecimiento_tiene_alta_exigencia_transitoria'})

# Expandimos vacantes por cuotas
programs['vacantes_alta_exigencia'] = programs[['vacantes_alta_exigencia_t','vacantes_alta_exigencia_r']].sum(axis=1)
programs = programs.drop(columns=['vacantes_alta_exigencia_t','vacantes_alta_exigencia_r','tiene_orden_alta_t'])
programs = programs.rename(columns={'vacantes_pie':'regular_vacancies1',
                                    'vacantes_alta_exigencia':'regular_vacancies2',
                                    'vacantes_prioritarios':'regular_vacancies3',
                                    'vacantes_regular':'regular_vacancies4'})
vacancies = pd.wide_to_long(programs,'regular_vacancies',i='program_id',j='quota_id').sort_index().reset_index()

# Vacantes listas


#Filtramos columnas relevantes de programas y cambiamos nombres de las postulaciones
applications = pd.merge(C1,B1[['mrun','alto_rendimiento','prioritario']],on='mrun',how='left'
                        ).rename(columns={'mrun':'applicant_id',
                                'rbd':'institution_id',
                                'preferencia_postulante':'ranking_program',
                                'es_pie':'prioridad_neep',
                                'alto_rendimiento':'prioridad_alta_exigencia',
                                'prioritario':'prioridad_prioritario'
                                }).drop(columns=['cod_nivel','agregada_por_continuidad'])

if not 'orden_pie' in applications.columns:
    applications['orden_pie'] = ' '
if not 'prioridad_neep' in applications.columns:
    applications['prioridad_neep'] = 0
if not 'orden_alta_exigencia_transicion' in applications.columns:
    applications['orden_alta_exigencia_transicion'] = ' '

applications['orden_pie'] = applications['orden_pie'].replace({' ':None}).astype(float)
applications['prioridad_neep'] = ((applications[['prioridad_neep','orden_pie']].max(axis=1))>0).astype(bool)
applications['orden_pie'] = applications['orden_pie'].fillna(10000)
applications['orden_alta_exigencia_transicion'] = applications['orden_alta_exigencia_transicion'].replace({' ':None}).astype(float)
applications['prioridad_alta_exigencia'] = ((applications[['prioridad_alta_exigencia','orden_alta_exigencia_transicion']].max(axis=1))>0).astype(bool)
applications['orden_alta_exigencia_transicion'] = applications['orden_alta_exigencia_transicion'].fillna(10000)


# Renombramos postulaciones deacuerdo al mapeo de program_id
applications['program_id'] = applications[['institution_id','cod_curso']].apply(tuple,axis=1).map(programs_index_dict)

# Es necesario agregar las postulaciones con matricula asegurada al df de applicants
applications_SE = applications.loc[applications.prioridad_matriculado==1][['applicant_id','program_id','prioridad_neep','prioridad_prioritario']
                                                                        ].rename(columns={'program_id':'secured_enrollment_program_id'})
applications_SE['secured_enrollment_quota_id']=4
applications_SE.loc[applications_SE.prioridad_prioritario==1,'secured_enrollment_quota_id']=3
applications_SE.loc[applications_SE.prioridad_neep==1,'secured_enrollment_quota_id']=1
applications_SE = applications_SE.drop(columns=['prioridad_neep','prioridad_prioritario'])

#Filtramos columnas relevantes de programas y cambiamos nombres de los postulantes
applicants = B1.rename(columns={'mrun':'applicant_id',
                                'cod_nivel':'grade_id',
                                'prioritario':'applicant_characteristic_1'
                                }).drop(columns=['es_mujer','alto_rendimiento','lat_con_error','lon_con_error','calidad_georef'], errors='ignore')
applicants['special_assignment']=0

# Agregamos postulaciones con matricula asegurada
applicants = pd.merge(applicants,applications_SE,on='applicant_id',how='left').fillna(0)

#Postulantes listos


# Agregamos info de AE
applications = pd.merge(applications,temp_programs_ae,on='program_id',how='left')

# Agregamos perfiles de prioridad
applications['priority_profile'] = pd_level_priority_profile_translate(applications)

# Con loterías:

pow10 = nextpow10(max(applications['loteria_original'].max(),applications['orden_pie'].max(),applications['orden_alta_exigencia_transicion'].max()))
applications['lottery_number_quota'] = applications['loteria_original']/pow10
applications['lottery_number_quota_temp_nee'] = 0
applications['lottery_number_quota_temp_academic'] = 0

applications.loc[(applications['prioridad_neep']==1) & (applications['orden_pie']>0),'lottery_number_quota_temp_nee'] = applications.loc[(applications['prioridad_neep']==1) & (applications['orden_pie']>0),'orden_pie']/pow10
applications.loc[(applications['establecimiento_tiene_alta_exigencia_transitoria']==1) & (applications['prioridad_alta_exigencia']==1),'lottery_number_quota_temp_academic'] = applications.loc[(applications['establecimiento_tiene_alta_exigencia_transitoria']==1) & (applications['prioridad_alta_exigencia']==1),'orden_alta_exigencia_transicion']/pow10

# Expandimos por quotas
applications_prev = pd.merge(applications,priority_profiles,on='priority_profile',how='left')

applications_prev = applications_prev.rename(columns={'priority_profile':'priority_profile_program'})
#applications_prev = applications_prev[['applicant_id', 'institution_id', 'program_id', 'ranking_program','priority_profile_program']+[col for col in applications_prev.columns if 'priority_q' in col]]
applications_prev = applications_prev[['applicant_id', 'institution_id', 'program_id', 'ranking_program','priority_profile_program','lottery_number_quota','lottery_number_quota_temp_nee','lottery_number_quota_temp_academic']+[col for col in applications_prev.columns if 'priority_q' in col]]

applications = pd.wide_to_long(applications_prev,'priority_q',i=['applicant_id','program_id'],j='quota_id')

applications = applications.rename(columns={'priority_q':'priority_number_quota'}).reset_index()

applications.loc[(applications['lottery_number_quota_temp_nee']!=0) & (applications['quota_id']==1),'lottery_number_quota'] = applications.loc[(applications['lottery_number_quota_temp_nee']!=0) & (applications['quota_id']==1),'lottery_number_quota_temp_nee']
applications.loc[(applications['lottery_number_quota_temp_academic']!=0) & (applications['quota_id']==2),'lottery_number_quota'] = applications.loc[(applications['lottery_number_quota_temp_academic']!=0) & (applications['quota_id']==2),'lottery_number_quota_temp_academic']

applications = applications.drop(columns=['lottery_number_quota_temp_nee','lottery_number_quota_temp_academic'])

# Postulaciones listas

# Filtramos columnas relevantes y cambiamos nombres para links y siblings
siblings = F1.rename(columns={'mrun_1':'applicant_id',
                                'mrun_2':'sibling_id'}
                    ).loc[F1.es_hermano==1
                            ].drop(columns=['mismo_nivel','es_hermano','postula_en_bloque'])
siblings_rev = siblings.rename(columns={'applicant_id':'sibling_id','sibling_id':'applicant_id'})
siblings = pd.concat((siblings,siblings_rev)).drop_duplicates()

links = F1.rename(columns={'mrun_1':'applicant_id',
                                'mrun_2':'linked_id'}
                    ).loc[F1.postula_en_bloque==1
                            ].drop(columns=['mismo_nivel','es_hermano','postula_en_bloque'])
links_rev = links.rename(columns={'applicant_id':'linked_id','linked_id':'applicant_id'})
links = pd.concat((links,links_rev)).drop_duplicates()

# Exportamos

applicants.to_csv(path_siblings + "mineduc_simulations/1_tables_simulation_format/0_simulation/applicants.csv", index = False)
applications.to_csv(path_siblings + "mineduc_simulations/1_tables_simulation_format/0_simulation/applications.csv", index = False)
vacancies.to_csv(path_siblings + "mineduc_simulations/1_tables_simulation_format/0_simulation/vacancies.csv", index = False)
links.to_csv(path_siblings + "mineduc_simulations/1_tables_simulation_format/0_simulation/links.csv", index = False)
siblings.to_csv(path_siblings + "mineduc_simulations/1_tables_simulation_format/0_simulation/siblings.csv", index = False)

#%%
# -----------------------------------------------------------------------------
# 1 SIMULATION: As nobody can use the fam. app.
# -----------------------------------------------------------------------------

# Change fam. app.

s1_F1 = F1.copy()
s1_F1['postula_en_bloque'] = 0

# Now format all databases

def pd_level_priority_profile_translate(df):
    priority_profiles = (df['prioridad_matriculado']*33) + (1-df['prioridad_matriculado'])*(
        df['prioridad_hermano']*(15+16*df['prioridad_neep']+df['prioridad_alta_exigencia']) + (1-df['prioridad_hermano'])*(
            df['prioridad_hijo_funcionario']*(9+16*df['prioridad_neep'] +2*df['prioridad_alta_exigencia'] +1*df['prioridad_prioritario']) + (1-df['prioridad_hijo_funcionario'])*(
                df['prioridad_exalumno']*(5+16*df['prioridad_neep'] +2*df['prioridad_alta_exigencia'] +1*df['prioridad_prioritario']) + (1-df['prioridad_exalumno'])*(
                    1+16*df['prioridad_neep'] +2*df['prioridad_alta_exigencia'] +1*df['prioridad_prioritario']
                )
            )
        ))
    return priority_profiles


def nextpow10(n):
    if n>1:
        return 10 ** math.ceil(math.log10(n))
    else:
        return 1


    #Filtramos columnas relevantes de programas y cambiamos nombres
programs = A1.rename(columns={'rbd':'institution_id',
                                'cod_nivel':'grade_id'
                                }).drop(columns=['cod_ense','cod_grado','cod_jor','cod_espe','cod_sede',
                                                'con_copago','solo_hombres','solo_mujeres','lat','lon',
                                                'vacantes',
                                                'cupos_totales','tiene_orden_pie'], errors='ignore')


temp_program_ids = crosswalk[['institution_id','cod_curso','new_program_id']]

programs_index_df = temp_program_ids.set_index(['institution_id','cod_curso'])['new_program_id']
# Generamos un mapeo de rbd-codcurso a un único program_id
programs_index_dict = programs_index_df.to_dict()

programs = pd.merge(programs,temp_program_ids,on=['institution_id','cod_curso'])    
programs = programs.drop(columns=['cod_curso'])
programs = programs.rename(columns={'new_program_id':'program_id'})

assert programs.program_id.isna().sum()==0, "Nan program_ids"

# Guardamos info de tiene_orden_alta_t
if not 'tiene_orden_alta_t' in programs.columns:
    programs['tiene_orden_alta_t'] = 0
temp_programs_ae = programs[['program_id','tiene_orden_alta_t']].drop_duplicates().copy()
temp_programs_ae = temp_programs_ae.rename(columns={'tiene_orden_alta_t':'establecimiento_tiene_alta_exigencia_transitoria'})

# Expandimos vacantes por cuotas
programs['vacantes_alta_exigencia'] = programs[['vacantes_alta_exigencia_t','vacantes_alta_exigencia_r']].sum(axis=1)
programs = programs.drop(columns=['vacantes_alta_exigencia_t','vacantes_alta_exigencia_r','tiene_orden_alta_t'])
programs = programs.rename(columns={'vacantes_pie':'regular_vacancies1',
                                    'vacantes_alta_exigencia':'regular_vacancies2',
                                    'vacantes_prioritarios':'regular_vacancies3',
                                    'vacantes_regular':'regular_vacancies4'})
vacancies = pd.wide_to_long(programs,'regular_vacancies',i='program_id',j='quota_id').sort_index().reset_index()

# Vacantes listas


#Filtramos columnas relevantes de programas y cambiamos nombres de las postulaciones
applications = pd.merge(C1,B1[['mrun','alto_rendimiento','prioritario']],on='mrun',how='left'
                        ).rename(columns={'mrun':'applicant_id',
                                'rbd':'institution_id',
                                'preferencia_postulante':'ranking_program',
                                'es_pie':'prioridad_neep',
                                'alto_rendimiento':'prioridad_alta_exigencia',
                                'prioritario':'prioridad_prioritario'
                                }).drop(columns=['cod_nivel','agregada_por_continuidad'])

if not 'orden_pie' in applications.columns:
    applications['orden_pie'] = ' '
if not 'prioridad_neep' in applications.columns:
    applications['prioridad_neep'] = 0
if not 'orden_alta_exigencia_transicion' in applications.columns:
    applications['orden_alta_exigencia_transicion'] = ' '

applications['orden_pie'] = applications['orden_pie'].replace({' ':None}).astype(float)
applications['prioridad_neep'] = ((applications[['prioridad_neep','orden_pie']].max(axis=1))>0).astype(bool)
applications['orden_pie'] = applications['orden_pie'].fillna(10000)
applications['orden_alta_exigencia_transicion'] = applications['orden_alta_exigencia_transicion'].replace({' ':None}).astype(float)
applications['prioridad_alta_exigencia'] = ((applications[['prioridad_alta_exigencia','orden_alta_exigencia_transicion']].max(axis=1))>0).astype(bool)
applications['orden_alta_exigencia_transicion'] = applications['orden_alta_exigencia_transicion'].fillna(10000)


# Renombramos postulaciones deacuerdo al mapeo de program_id
applications['program_id'] = applications[['institution_id','cod_curso']].apply(tuple,axis=1).map(programs_index_dict)

# Es necesario agregar las postulaciones con matricula asegurada al df de applicants
applications_SE = applications.loc[applications.prioridad_matriculado==1][['applicant_id','program_id','prioridad_neep','prioridad_prioritario']
                                                                        ].rename(columns={'program_id':'secured_enrollment_program_id'})
applications_SE['secured_enrollment_quota_id']=4
applications_SE.loc[applications_SE.prioridad_prioritario==1,'secured_enrollment_quota_id']=3
applications_SE.loc[applications_SE.prioridad_neep==1,'secured_enrollment_quota_id']=1
applications_SE = applications_SE.drop(columns=['prioridad_neep','prioridad_prioritario'])

#Filtramos columnas relevantes de programas y cambiamos nombres de los postulantes
applicants = B1.rename(columns={'mrun':'applicant_id',
                                'cod_nivel':'grade_id',
                                'prioritario':'applicant_characteristic_1'
                                }).drop(columns=['es_mujer','alto_rendimiento','lat_con_error','lon_con_error','calidad_georef'], errors='ignore')
applicants['special_assignment']=0

# Agregamos postulaciones con matricula asegurada
applicants = pd.merge(applicants,applications_SE,on='applicant_id',how='left').fillna(0)

#Postulantes listos


# Agregamos info de AE
applications = pd.merge(applications,temp_programs_ae,on='program_id',how='left')

# Agregamos perfiles de prioridad
applications['priority_profile'] = pd_level_priority_profile_translate(applications)

# Con loterías:

pow10 = nextpow10(max(applications['loteria_original'].max(),applications['orden_pie'].max(),applications['orden_alta_exigencia_transicion'].max()))
applications['lottery_number_quota'] = applications['loteria_original']/pow10
applications['lottery_number_quota_temp_nee'] = 0
applications['lottery_number_quota_temp_academic'] = 0

applications.loc[(applications['prioridad_neep']==1) & (applications['orden_pie']>0),'lottery_number_quota_temp_nee'] = applications.loc[(applications['prioridad_neep']==1) & (applications['orden_pie']>0),'orden_pie']/pow10
applications.loc[(applications['establecimiento_tiene_alta_exigencia_transitoria']==1) & (applications['prioridad_alta_exigencia']==1),'lottery_number_quota_temp_academic'] = applications.loc[(applications['establecimiento_tiene_alta_exigencia_transitoria']==1) & (applications['prioridad_alta_exigencia']==1),'orden_alta_exigencia_transicion']/pow10

# Expandimos por quotas
applications_prev = pd.merge(applications,priority_profiles,on='priority_profile',how='left')

applications_prev = applications_prev.rename(columns={'priority_profile':'priority_profile_program'})
#applications_prev = applications_prev[['applicant_id', 'institution_id', 'program_id', 'ranking_program','priority_profile_program']+[col for col in applications_prev.columns if 'priority_q' in col]]
applications_prev = applications_prev[['applicant_id', 'institution_id', 'program_id', 'ranking_program','priority_profile_program','lottery_number_quota','lottery_number_quota_temp_nee','lottery_number_quota_temp_academic']+[col for col in applications_prev.columns if 'priority_q' in col]]

applications = pd.wide_to_long(applications_prev,'priority_q',i=['applicant_id','program_id'],j='quota_id')

applications = applications.rename(columns={'priority_q':'priority_number_quota'}).reset_index()

applications.loc[(applications['lottery_number_quota_temp_nee']!=0) & (applications['quota_id']==1),'lottery_number_quota'] = applications.loc[(applications['lottery_number_quota_temp_nee']!=0) & (applications['quota_id']==1),'lottery_number_quota_temp_nee']
applications.loc[(applications['lottery_number_quota_temp_academic']!=0) & (applications['quota_id']==2),'lottery_number_quota'] = applications.loc[(applications['lottery_number_quota_temp_academic']!=0) & (applications['quota_id']==2),'lottery_number_quota_temp_academic']

applications = applications.drop(columns=['lottery_number_quota_temp_nee','lottery_number_quota_temp_academic'])

# Postulaciones listas

# Filtramos columnas relevantes y cambiamos nombres para links y siblings
siblings = s1_F1.rename(columns={'mrun_1':'applicant_id',
                                'mrun_2':'sibling_id'}
                    ).loc[s1_F1.es_hermano==1
                            ].drop(columns=['mismo_nivel','es_hermano','postula_en_bloque'])
siblings_rev = siblings.rename(columns={'applicant_id':'sibling_id','sibling_id':'applicant_id'})
siblings = pd.concat((siblings,siblings_rev)).drop_duplicates()

links = s1_F1.rename(columns={'mrun_1':'applicant_id',
                                'mrun_2':'linked_id'}
                    ).loc[s1_F1.postula_en_bloque==1
                            ].drop(columns=['mismo_nivel','es_hermano','postula_en_bloque'])
links_rev = links.rename(columns={'applicant_id':'linked_id','linked_id':'applicant_id'})
links = pd.concat((links,links_rev)).drop_duplicates()

# Exportamos

applicants.to_csv(path_siblings + "mineduc_simulations/1_tables_simulation_format/1_simulation/applicants.csv", index = False)
applications.to_csv(path_siblings + "mineduc_simulations/1_tables_simulation_format/1_simulation/applications.csv", index = False)
vacancies.to_csv(path_siblings + "mineduc_simulations/1_tables_simulation_format/1_simulation/vacancies.csv", index = False)
links.to_csv(path_siblings + "mineduc_simulations/1_tables_simulation_format/1_simulation/links.csv", index = False)
siblings.to_csv(path_siblings + "mineduc_simulations/1_tables_simulation_format/1_simulation/siblings.csv", index = False)

#%%
# -----------------------------------------------------------------------------
# 2 SIMULATION: Turn off the fam. app. only for siblings with same secure enrollment school.
# -----------------------------------------------------------------------------

# Identify siblings with same secure enrollment 
    
secure_enrollment = C1.loc[(C1.agregada_por_continuidad == 1)]
secure_enrollment = secure_enrollment[['mrun','rbd']]

secure_enrollment_1 = secure_enrollment.rename(columns = {'mrun':'mrun_1', 'rbd':'rbd_1'})
secure_enrollment_2 = secure_enrollment.rename(columns = {'mrun':'mrun_2', 'rbd':'rbd_2'})

s2_F1 = pd.merge(F1,secure_enrollment_1, how = 'left', on = 'mrun_1')
s2_F1 = pd.merge(s2_F1,secure_enrollment_2, how = 'left', on = 'mrun_2')

# Change fam. app for those families

s2_F1['dummy'] = (s2_F1['rbd_1'].notna() & 
                            s2_F1['rbd_2'].notna() & 
                            (s2_F1['rbd_1'] == s2_F1['rbd_2'])).astype(int)

s2_F1.loc[s2_F1['dummy'] == 1, 'postula_en_bloque'] = 0
s2_F1.drop(columns = ['dummy','rbd_1','rbd_2'], inplace = True)

# Now format all databases

def pd_level_priority_profile_translate(df):
    priority_profiles = (df['prioridad_matriculado']*33) + (1-df['prioridad_matriculado'])*(
        df['prioridad_hermano']*(15+16*df['prioridad_neep']+df['prioridad_alta_exigencia']) + (1-df['prioridad_hermano'])*(
            df['prioridad_hijo_funcionario']*(9+16*df['prioridad_neep'] +2*df['prioridad_alta_exigencia'] +1*df['prioridad_prioritario']) + (1-df['prioridad_hijo_funcionario'])*(
                df['prioridad_exalumno']*(5+16*df['prioridad_neep'] +2*df['prioridad_alta_exigencia'] +1*df['prioridad_prioritario']) + (1-df['prioridad_exalumno'])*(
                    1+16*df['prioridad_neep'] +2*df['prioridad_alta_exigencia'] +1*df['prioridad_prioritario']
                )
            )
        ))
    return priority_profiles


def nextpow10(n):
    if n>1:
        return 10 ** math.ceil(math.log10(n))
    else:
        return 1


    #Filtramos columnas relevantes de programas y cambiamos nombres
programs = A1.rename(columns={'rbd':'institution_id',
                                'cod_nivel':'grade_id'
                                }).drop(columns=['cod_ense','cod_grado','cod_jor','cod_espe','cod_sede',
                                                'con_copago','solo_hombres','solo_mujeres','lat','lon',
                                                'vacantes',
                                                'cupos_totales','tiene_orden_pie'], errors='ignore')


temp_program_ids = crosswalk[['institution_id','cod_curso','new_program_id']]

programs_index_df = temp_program_ids.set_index(['institution_id','cod_curso'])['new_program_id']
# Generamos un mapeo de rbd-codcurso a un único program_id
programs_index_dict = programs_index_df.to_dict()

programs = pd.merge(programs,temp_program_ids,on=['institution_id','cod_curso'])    
programs = programs.drop(columns=['cod_curso'])
programs = programs.rename(columns={'new_program_id':'program_id'})

assert programs.program_id.isna().sum()==0, "Nan program_ids"

# Guardamos info de tiene_orden_alta_t
if not 'tiene_orden_alta_t' in programs.columns:
    programs['tiene_orden_alta_t'] = 0
temp_programs_ae = programs[['program_id','tiene_orden_alta_t']].drop_duplicates().copy()
temp_programs_ae = temp_programs_ae.rename(columns={'tiene_orden_alta_t':'establecimiento_tiene_alta_exigencia_transitoria'})

# Expandimos vacantes por cuotas
programs['vacantes_alta_exigencia'] = programs[['vacantes_alta_exigencia_t','vacantes_alta_exigencia_r']].sum(axis=1)
programs = programs.drop(columns=['vacantes_alta_exigencia_t','vacantes_alta_exigencia_r','tiene_orden_alta_t'])
programs = programs.rename(columns={'vacantes_pie':'regular_vacancies1',
                                    'vacantes_alta_exigencia':'regular_vacancies2',
                                    'vacantes_prioritarios':'regular_vacancies3',
                                    'vacantes_regular':'regular_vacancies4'})
vacancies = pd.wide_to_long(programs,'regular_vacancies',i='program_id',j='quota_id').sort_index().reset_index()

# Vacantes listas


#Filtramos columnas relevantes de programas y cambiamos nombres de las postulaciones
applications = pd.merge(C1,B1[['mrun','alto_rendimiento','prioritario']],on='mrun',how='left'
                        ).rename(columns={'mrun':'applicant_id',
                                'rbd':'institution_id',
                                'preferencia_postulante':'ranking_program',
                                'es_pie':'prioridad_neep',
                                'alto_rendimiento':'prioridad_alta_exigencia',
                                'prioritario':'prioridad_prioritario'
                                }).drop(columns=['cod_nivel','agregada_por_continuidad'])

if not 'orden_pie' in applications.columns:
    applications['orden_pie'] = ' '
if not 'prioridad_neep' in applications.columns:
    applications['prioridad_neep'] = 0
if not 'orden_alta_exigencia_transicion' in applications.columns:
    applications['orden_alta_exigencia_transicion'] = ' '

applications['orden_pie'] = applications['orden_pie'].replace({' ':None}).astype(float)
applications['prioridad_neep'] = ((applications[['prioridad_neep','orden_pie']].max(axis=1))>0).astype(bool)
applications['orden_pie'] = applications['orden_pie'].fillna(10000)
applications['orden_alta_exigencia_transicion'] = applications['orden_alta_exigencia_transicion'].replace({' ':None}).astype(float)
applications['prioridad_alta_exigencia'] = ((applications[['prioridad_alta_exigencia','orden_alta_exigencia_transicion']].max(axis=1))>0).astype(bool)
applications['orden_alta_exigencia_transicion'] = applications['orden_alta_exigencia_transicion'].fillna(10000)


# Renombramos postulaciones deacuerdo al mapeo de program_id
applications['program_id'] = applications[['institution_id','cod_curso']].apply(tuple,axis=1).map(programs_index_dict)

# Es necesario agregar las postulaciones con matricula asegurada al df de applicants
applications_SE = applications.loc[applications.prioridad_matriculado==1][['applicant_id','program_id','prioridad_neep','prioridad_prioritario']
                                                                        ].rename(columns={'program_id':'secured_enrollment_program_id'})
applications_SE['secured_enrollment_quota_id']=4
applications_SE.loc[applications_SE.prioridad_prioritario==1,'secured_enrollment_quota_id']=3
applications_SE.loc[applications_SE.prioridad_neep==1,'secured_enrollment_quota_id']=1
applications_SE = applications_SE.drop(columns=['prioridad_neep','prioridad_prioritario'])

#Filtramos columnas relevantes de programas y cambiamos nombres de los postulantes
applicants = B1.rename(columns={'mrun':'applicant_id',
                                'cod_nivel':'grade_id',
                                'prioritario':'applicant_characteristic_1'
                                }).drop(columns=['es_mujer','alto_rendimiento','lat_con_error','lon_con_error','calidad_georef'], errors='ignore')
applicants['special_assignment']=0

# Agregamos postulaciones con matricula asegurada
applicants = pd.merge(applicants,applications_SE,on='applicant_id',how='left').fillna(0)

#Postulantes listos


# Agregamos info de AE
applications = pd.merge(applications,temp_programs_ae,on='program_id',how='left')

# Agregamos perfiles de prioridad
applications['priority_profile'] = pd_level_priority_profile_translate(applications)

# Con loterías:

pow10 = nextpow10(max(applications['loteria_original'].max(),applications['orden_pie'].max(),applications['orden_alta_exigencia_transicion'].max()))
applications['lottery_number_quota'] = applications['loteria_original']/pow10
applications['lottery_number_quota_temp_nee'] = 0
applications['lottery_number_quota_temp_academic'] = 0

applications.loc[(applications['prioridad_neep']==1) & (applications['orden_pie']>0),'lottery_number_quota_temp_nee'] = applications.loc[(applications['prioridad_neep']==1) & (applications['orden_pie']>0),'orden_pie']/pow10
applications.loc[(applications['establecimiento_tiene_alta_exigencia_transitoria']==1) & (applications['prioridad_alta_exigencia']==1),'lottery_number_quota_temp_academic'] = applications.loc[(applications['establecimiento_tiene_alta_exigencia_transitoria']==1) & (applications['prioridad_alta_exigencia']==1),'orden_alta_exigencia_transicion']/pow10

# Expandimos por quotas
applications_prev = pd.merge(applications,priority_profiles,on='priority_profile',how='left')

applications_prev = applications_prev.rename(columns={'priority_profile':'priority_profile_program'})
#applications_prev = applications_prev[['applicant_id', 'institution_id', 'program_id', 'ranking_program','priority_profile_program']+[col for col in applications_prev.columns if 'priority_q' in col]]
applications_prev = applications_prev[['applicant_id', 'institution_id', 'program_id', 'ranking_program','priority_profile_program','lottery_number_quota','lottery_number_quota_temp_nee','lottery_number_quota_temp_academic']+[col for col in applications_prev.columns if 'priority_q' in col]]

applications = pd.wide_to_long(applications_prev,'priority_q',i=['applicant_id','program_id'],j='quota_id')

applications = applications.rename(columns={'priority_q':'priority_number_quota'}).reset_index()

applications.loc[(applications['lottery_number_quota_temp_nee']!=0) & (applications['quota_id']==1),'lottery_number_quota'] = applications.loc[(applications['lottery_number_quota_temp_nee']!=0) & (applications['quota_id']==1),'lottery_number_quota_temp_nee']
applications.loc[(applications['lottery_number_quota_temp_academic']!=0) & (applications['quota_id']==2),'lottery_number_quota'] = applications.loc[(applications['lottery_number_quota_temp_academic']!=0) & (applications['quota_id']==2),'lottery_number_quota_temp_academic']

applications = applications.drop(columns=['lottery_number_quota_temp_nee','lottery_number_quota_temp_academic'])

# Postulaciones listas

# Filtramos columnas relevantes y cambiamos nombres para links y siblings
siblings = s2_F1.rename(columns={'mrun_1':'applicant_id',
                                'mrun_2':'sibling_id'}
                    ).loc[s2_F1.es_hermano==1
                            ].drop(columns=['mismo_nivel','es_hermano','postula_en_bloque'])
siblings_rev = siblings.rename(columns={'applicant_id':'sibling_id','sibling_id':'applicant_id'})
siblings = pd.concat((siblings,siblings_rev)).drop_duplicates()

links = s2_F1.rename(columns={'mrun_1':'applicant_id',
                                'mrun_2':'linked_id'}
                    ).loc[s2_F1.postula_en_bloque==1
                            ].drop(columns=['mismo_nivel','es_hermano','postula_en_bloque'])
links_rev = links.rename(columns={'applicant_id':'linked_id','linked_id':'applicant_id'})
links = pd.concat((links,links_rev)).drop_duplicates()

# Exportamos

applicants.to_csv(path_siblings + "mineduc_simulations/1_tables_simulation_format/2_simulation/applicants.csv", index = False)
applications.to_csv(path_siblings + "mineduc_simulations/1_tables_simulation_format/2_simulation/applications.csv", index = False)
vacancies.to_csv(path_siblings + "mineduc_simulations/1_tables_simulation_format/2_simulation/vacancies.csv", index = False)
links.to_csv(path_siblings + "mineduc_simulations/1_tables_simulation_format/2_simulation/links.csv", index = False)
siblings.to_csv(path_siblings + "mineduc_simulations/1_tables_simulation_format/2_simulation/siblings.csv", index = False)

#%%
# -----------------------------------------------------------------------------
# 3 SIMULATION: Run the algorithm from pre-K to senior year (IVº medio)
# -----------------------------------------------------------------------------

# Multiply cod_nivel by -1 (so it is run in the other way)

s3_A1 = A1.copy()
s3_A1['cod_nivel'] = s3_A1['cod_nivel'] * -1

s3_B1 = B1.copy()
s3_B1['cod_nivel'] = s3_B1['cod_nivel'] * -1

s3_C1 = C1.copy()
s3_C1['cod_nivel'] = s3_C1['cod_nivel'] * -1

# Now format all databases

def pd_level_priority_profile_translate(df):
    priority_profiles = (df['prioridad_matriculado']*33) + (1-df['prioridad_matriculado'])*(
        df['prioridad_hermano']*(15+16*df['prioridad_neep']+df['prioridad_alta_exigencia']) + (1-df['prioridad_hermano'])*(
            df['prioridad_hijo_funcionario']*(9+16*df['prioridad_neep'] +2*df['prioridad_alta_exigencia'] +1*df['prioridad_prioritario']) + (1-df['prioridad_hijo_funcionario'])*(
                df['prioridad_exalumno']*(5+16*df['prioridad_neep'] +2*df['prioridad_alta_exigencia'] +1*df['prioridad_prioritario']) + (1-df['prioridad_exalumno'])*(
                    1+16*df['prioridad_neep'] +2*df['prioridad_alta_exigencia'] +1*df['prioridad_prioritario']
                )
            )
        ))
    return priority_profiles


def nextpow10(n):
    if n>1:
        return 10 ** math.ceil(math.log10(n))
    else:
        return 1


    #Filtramos columnas relevantes de programas y cambiamos nombres
programs = s3_A1.rename(columns={'rbd':'institution_id',
                                'cod_nivel':'grade_id'
                                }).drop(columns=['cod_ense','cod_grado','cod_jor','cod_espe','cod_sede',
                                                'con_copago','solo_hombres','solo_mujeres','lat','lon',
                                                'vacantes',
                                                'cupos_totales','tiene_orden_pie'], errors='ignore')


temp_program_ids = crosswalk[['institution_id','cod_curso','new_program_id']]

programs_index_df = temp_program_ids.set_index(['institution_id','cod_curso'])['new_program_id']
# Generamos un mapeo de rbd-codcurso a un único program_id
programs_index_dict = programs_index_df.to_dict()

programs = pd.merge(programs,temp_program_ids,on=['institution_id','cod_curso'])    
programs = programs.drop(columns=['cod_curso'])
programs = programs.rename(columns={'new_program_id':'program_id'})

assert programs.program_id.isna().sum()==0, "Nan program_ids"

# Guardamos info de tiene_orden_alta_t
if not 'tiene_orden_alta_t' in programs.columns:
    programs['tiene_orden_alta_t'] = 0
temp_programs_ae = programs[['program_id','tiene_orden_alta_t']].drop_duplicates().copy()
temp_programs_ae = temp_programs_ae.rename(columns={'tiene_orden_alta_t':'establecimiento_tiene_alta_exigencia_transitoria'})

# Expandimos vacantes por cuotas
programs['vacantes_alta_exigencia'] = programs[['vacantes_alta_exigencia_t','vacantes_alta_exigencia_r']].sum(axis=1)
programs = programs.drop(columns=['vacantes_alta_exigencia_t','vacantes_alta_exigencia_r','tiene_orden_alta_t'])
programs = programs.rename(columns={'vacantes_pie':'regular_vacancies1',
                                    'vacantes_alta_exigencia':'regular_vacancies2',
                                    'vacantes_prioritarios':'regular_vacancies3',
                                    'vacantes_regular':'regular_vacancies4'})
vacancies = pd.wide_to_long(programs,'regular_vacancies',i='program_id',j='quota_id').sort_index().reset_index()

# Vacantes listas


#Filtramos columnas relevantes de programas y cambiamos nombres de las postulaciones
applications = pd.merge(s3_C1,s3_B1[['mrun','alto_rendimiento','prioritario']],on='mrun',how='left'
                        ).rename(columns={'mrun':'applicant_id',
                                'rbd':'institution_id',
                                'preferencia_postulante':'ranking_program',
                                'es_pie':'prioridad_neep',
                                'alto_rendimiento':'prioridad_alta_exigencia',
                                'prioritario':'prioridad_prioritario'
                                }).drop(columns=['cod_nivel','agregada_por_continuidad'])

if not 'orden_pie' in applications.columns:
    applications['orden_pie'] = ' '
if not 'prioridad_neep' in applications.columns:
    applications['prioridad_neep'] = 0
if not 'orden_alta_exigencia_transicion' in applications.columns:
    applications['orden_alta_exigencia_transicion'] = ' '

applications['orden_pie'] = applications['orden_pie'].replace({' ':None}).astype(float)
applications['prioridad_neep'] = ((applications[['prioridad_neep','orden_pie']].max(axis=1))>0).astype(bool)
applications['orden_pie'] = applications['orden_pie'].fillna(10000)
applications['orden_alta_exigencia_transicion'] = applications['orden_alta_exigencia_transicion'].replace({' ':None}).astype(float)
applications['prioridad_alta_exigencia'] = ((applications[['prioridad_alta_exigencia','orden_alta_exigencia_transicion']].max(axis=1))>0).astype(bool)
applications['orden_alta_exigencia_transicion'] = applications['orden_alta_exigencia_transicion'].fillna(10000)


# Renombramos postulaciones deacuerdo al mapeo de program_id
applications['program_id'] = applications[['institution_id','cod_curso']].apply(tuple,axis=1).map(programs_index_dict)

# Es necesario agregar las postulaciones con matricula asegurada al df de applicants
applications_SE = applications.loc[applications.prioridad_matriculado==1][['applicant_id','program_id','prioridad_neep','prioridad_prioritario']
                                                                        ].rename(columns={'program_id':'secured_enrollment_program_id'})
applications_SE['secured_enrollment_quota_id']=4
applications_SE.loc[applications_SE.prioridad_prioritario==1,'secured_enrollment_quota_id']=3
applications_SE.loc[applications_SE.prioridad_neep==1,'secured_enrollment_quota_id']=1
applications_SE = applications_SE.drop(columns=['prioridad_neep','prioridad_prioritario'])

#Filtramos columnas relevantes de programas y cambiamos nombres de los postulantes
applicants = s3_B1.rename(columns={'mrun':'applicant_id',
                                'cod_nivel':'grade_id',
                                'prioritario':'applicant_characteristic_1'
                                }).drop(columns=['es_mujer','alto_rendimiento','lat_con_error','lon_con_error','calidad_georef'], errors='ignore')
applicants['special_assignment']=0

# Agregamos postulaciones con matricula asegurada
applicants = pd.merge(applicants,applications_SE,on='applicant_id',how='left').fillna(0)

#Postulantes listos


# Agregamos info de AE
applications = pd.merge(applications,temp_programs_ae,on='program_id',how='left')

# Agregamos perfiles de prioridad
applications['priority_profile'] = pd_level_priority_profile_translate(applications)

# Con loterías:

pow10 = nextpow10(max(applications['loteria_original'].max(),applications['orden_pie'].max(),applications['orden_alta_exigencia_transicion'].max()))
applications['lottery_number_quota'] = applications['loteria_original']/pow10
applications['lottery_number_quota_temp_nee'] = 0
applications['lottery_number_quota_temp_academic'] = 0

applications.loc[(applications['prioridad_neep']==1) & (applications['orden_pie']>0),'lottery_number_quota_temp_nee'] = applications.loc[(applications['prioridad_neep']==1) & (applications['orden_pie']>0),'orden_pie']/pow10
applications.loc[(applications['establecimiento_tiene_alta_exigencia_transitoria']==1) & (applications['prioridad_alta_exigencia']==1),'lottery_number_quota_temp_academic'] = applications.loc[(applications['establecimiento_tiene_alta_exigencia_transitoria']==1) & (applications['prioridad_alta_exigencia']==1),'orden_alta_exigencia_transicion']/pow10

# Expandimos por quotas
applications_prev = pd.merge(applications,priority_profiles,on='priority_profile',how='left')

applications_prev = applications_prev.rename(columns={'priority_profile':'priority_profile_program'})
#applications_prev = applications_prev[['applicant_id', 'institution_id', 'program_id', 'ranking_program','priority_profile_program']+[col for col in applications_prev.columns if 'priority_q' in col]]
applications_prev = applications_prev[['applicant_id', 'institution_id', 'program_id', 'ranking_program','priority_profile_program','lottery_number_quota','lottery_number_quota_temp_nee','lottery_number_quota_temp_academic']+[col for col in applications_prev.columns if 'priority_q' in col]]

applications = pd.wide_to_long(applications_prev,'priority_q',i=['applicant_id','program_id'],j='quota_id')

applications = applications.rename(columns={'priority_q':'priority_number_quota'}).reset_index()

applications.loc[(applications['lottery_number_quota_temp_nee']!=0) & (applications['quota_id']==1),'lottery_number_quota'] = applications.loc[(applications['lottery_number_quota_temp_nee']!=0) & (applications['quota_id']==1),'lottery_number_quota_temp_nee']
applications.loc[(applications['lottery_number_quota_temp_academic']!=0) & (applications['quota_id']==2),'lottery_number_quota'] = applications.loc[(applications['lottery_number_quota_temp_academic']!=0) & (applications['quota_id']==2),'lottery_number_quota_temp_academic']

applications = applications.drop(columns=['lottery_number_quota_temp_nee','lottery_number_quota_temp_academic'])

# Postulaciones listas

# Filtramos columnas relevantes y cambiamos nombres para links y siblings
siblings = F1.rename(columns={'mrun_1':'applicant_id',
                                'mrun_2':'sibling_id'}
                    ).loc[F1.es_hermano==1
                            ].drop(columns=['mismo_nivel','es_hermano','postula_en_bloque'])
siblings_rev = siblings.rename(columns={'applicant_id':'sibling_id','sibling_id':'applicant_id'})
siblings = pd.concat((siblings,siblings_rev)).drop_duplicates()

links = F1.rename(columns={'mrun_1':'applicant_id',
                                'mrun_2':'linked_id'}
                    ).loc[F1.postula_en_bloque==1
                            ].drop(columns=['mismo_nivel','es_hermano','postula_en_bloque'])
links_rev = links.rename(columns={'applicant_id':'linked_id','linked_id':'applicant_id'})
links = pd.concat((links,links_rev)).drop_duplicates()

# Exportamos

applicants.to_csv(path_siblings + "mineduc_simulations/1_tables_simulation_format/3_simulation/applicants.csv", index = False)
applications.to_csv(path_siblings + "mineduc_simulations/1_tables_simulation_format/3_simulation/applications.csv", index = False)
vacancies.to_csv(path_siblings + "mineduc_simulations/1_tables_simulation_format/3_simulation/vacancies.csv", index = False)
links.to_csv(path_siblings + "mineduc_simulations/1_tables_simulation_format/3_simulation/links.csv", index = False)
siblings.to_csv(path_siblings + "mineduc_simulations/1_tables_simulation_format/3_simulation/siblings.csv", index = False)

#%%