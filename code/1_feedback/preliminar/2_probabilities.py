#!/usr/bin/env python
# coding: utf-8

# In[1]:


import os
import pandas as pd
import numpy as np

Path = '/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings/data/'

postulaciones = pd.read_csv(Path + 'intermediate/simulation_probabilities/inputs_for_joint_probabilities.csv')

riesgos = pd.read_csv(Path + 'intermediate/simulation_probabilities/riesgos_data-_oficialEqSAEAnterior_500r_exp0.csv')

postulaciones = pd.merge(postulaciones, riesgos, how = 'left', left_on =['rbd','codcurso','tipo'], right_on = ['rbd','cod_curso','tipo'], indicator = True)
postulaciones['_merge'].value_counts()

postulaciones.loc[(postulaciones['_merge'] == 'left_only'), 'risk'] = 0
del postulaciones['_merge']


# # Prob. Mayor

# In[2]:


# Filtramos la data

postulaciones_mayor = postulaciones.loc[(postulaciones.hermano_mayor == 1)]

# Calculando probabilidades de asignación

postulaciones_mayor = postulaciones_mayor.sort_values(['mrun','preferencia_postulante']).reset_index(drop=True)
postulaciones_mayor['prob_asig'] = np.nan
# Variable auxiliar
postulaciones_mayor['prob_acum'] = np.nan

# Loop

for i in range(0,len(postulaciones_mayor)):
    if postulaciones_mayor.loc[i,'preferencia_postulante'] == 1:
        postulaciones_mayor.loc[i,'prob_asig'] = 1 - postulaciones_mayor.loc[i,'risk']
        postulaciones_mayor.loc[i,'prob_acum'] = postulaciones_mayor.loc[i,'prob_asig']
    else:
        postulaciones_mayor.loc[i,'prob_asig'] = (1 - postulaciones_mayor.loc[i-1,'prob_acum']) * (1 - postulaciones_mayor.loc[i,'risk'])
        postulaciones_mayor.loc[i,'prob_acum'] = postulaciones_mayor.loc[i,'prob_asig'] + postulaciones_mayor.loc[i-1,'prob_acum']

mayor_no_asignado = postulaciones_mayor.groupby('mrun').agg({'prob_asig':'sum'}).reset_index()

mayor_no_asignado['prob_no_asignado'] = 1 - mayor_no_asignado['prob_asig']
# Algunos aparecen con probabilidad negativa porque en realidad es 0,00000000x
mayor_no_asignado.loc[(mayor_no_asignado['prob_no_asignado'] < 0), 'prob_no_asignado'] = 0

del mayor_no_asignado['prob_asig']



# # Prob. Menor

# ## Postulación en bloque

# ### Creando la data

# In[3]:


# Filtramos la data

postulaciones_menor = postulaciones.loc[(postulaciones.hermano_mayor == 0)]

# Eliminamos riesgo porque los volveremos a obtener

del postulaciones_menor['risk']

# Eliminamos tipo porque lo volveremos a obtener

del postulaciones_menor['tipo']

# Pegamos las postulaciones del hermano mayor, para que cada el set de postulaciones del menor se repita para cada postulación del mayor

postulaciones_mayor_para_hermano = postulaciones_mayor[['mrun','prob_asig','rbd']]
postulaciones_mayor_para_hermano = postulaciones_mayor_para_hermano.rename(columns={'mrun': 'mrun_hermano_final', 'prob_asig': 'prob_asig_mayor', 'rbd': 'rbd_mayor'})

conjunto_postulaciones = pd.merge(postulaciones_menor, postulaciones_mayor_para_hermano, how = 'left', left_on = ['mrun_hermano_final'], right_on = ['mrun_hermano_final'], indicator = True)
conjunto_postulaciones['_merge'].value_counts()
# Todas las obs pegan :)
del conjunto_postulaciones['_merge']

# Hacemos append de las postulaciones del menor para sumar el caso en que el mayor no es asignado

mayor_no_asignado = mayor_no_asignado.rename(columns={'mrun': 'mrun_hermano_final', 'prob_no_asignado': 'prob_no_asignado_mayor'})
conjunto_no_asignado = pd.merge(postulaciones_menor, mayor_no_asignado, how = 'left', left_on = ['mrun_hermano_final'], right_on = ['mrun_hermano_final'], indicator = True)
conjunto_no_asignado['_merge'].value_counts()
# Todas las obs pegan :)
del conjunto_no_asignado['_merge']

conjunto_final = conjunto_postulaciones.append(conjunto_no_asignado)

# Ordenamos la data

conjunto_final = conjunto_final.sort_values(['mrun','rbd_mayor','preferencia_postulante']).reset_index(drop=True)


# ### 1. Prioridad dinámica

# In[4]:


# Reemplazamos prioridad por dinámica cuando corresponda

# 1. Reemplazamos la variable criterioprioridad 
# Se reemplaza por 4 cuando criterioprioridad < 4 y es el rbd correspondiente

conjunto_final.loc[(conjunto_final['criterioprioridad'] < 4) & (conjunto_final['rbd_mayor'] == conjunto_final['rbd']), 'criterioprioridad'] = 4
conjunto_final['criterioprioridad'].value_counts()

# 2. Pegamos con la base tipos

tipos = pd.read_csv('/Users/javieragazmuri/ConsiliumBots Dropbox/Javiera Gazmuri/Archivos de javiera@consiliumbots.com/ejemploJavi/tipos_data-data2022_5r_exp0.csv')

tipos = pd.read_csv(Path + 'intermediate/simulation_probabilities/tipos_data-_oficialEqSAEAnterior_500r_exp0.csv')

tipos = tipos.rename(columns={'criterioPrioridad': 'criterioprioridad'})
del tipos['criterioPrioridad_label']
del tipos['tipo_label']

conjunto_final = pd.merge(conjunto_final, tipos, how = 'left', left_on = ['criterioprioridad','prioritario','alto_rendimiento'], right_on = ['criterioprioridad','prioritario','alto_rendimiento'], indicator = True)
conjunto_final['_merge'].value_counts()
del conjunto_final['_merge']

conjunto_final = pd.merge(conjunto_final, riesgos, how = 'left', left_on =['rbd','codcurso','tipo'], right_on = ['rbd','cod_curso','tipo'], indicator = True)
conjunto_final['_merge'].value_counts()
conjunto_final.loc[(conjunto_final['_merge'] == 'left_only'), 'risk'] = 0
del conjunto_final['_merge']


# ### 2. Postulación familiar (para no activar postulación familiar, no se corre)

# In[5]:


# Re-ordenamos preferencias por postulación en bloque

conjunto_final['dummy'] = 0
conjunto_final.loc[(conjunto_final['rbd_mayor'] == conjunto_final['rbd']), 'dummy'] = 1

# Indicador de que la postulacion del mayor esta en la del menor
conjunto_final['mrun_con_dummy'] = conjunto_final.groupby(['mrun','rbd_mayor'])['dummy'].transform('max')

# Variable que sirve para ver si es que el menor postulo a ese colegio en su primera preferencia
conjunto_final['num_preferencia'] = 0
conjunto_final.loc[(conjunto_final['rbd_mayor'] == conjunto_final['rbd']), 'num_preferencia'] = conjunto_final['preferencia_postulante']

conjunto_final['max_num_preferencia'] = conjunto_final.groupby(['mrun','rbd_mayor'])['num_preferencia'].transform('max')

# Reordenando
conjunto_final.loc[(conjunto_final['max_num_preferencia'] != 1) & (conjunto_final['max_num_preferencia'] != np.nan) & (conjunto_final['mrun_con_dummy']==1), 'preferencia_postulante'] = conjunto_final['preferencia_postulante'] + 1
conjunto_final.loc[(conjunto_final['max_num_preferencia'] != 1) & (conjunto_final['max_num_preferencia'] != np.nan) & (conjunto_final['mrun_con_dummy']==1) & (conjunto_final['rbd_mayor'] == conjunto_final['rbd']), 'preferencia_postulante'] = 1

# Creando nueva variable de preferencia_postulante
conjunto_final = conjunto_final.sort_values(['mrun','rbd_mayor','preferencia_postulante']).reset_index(drop=True)

conjunto_final['new_pref'] = 1
conjunto_final['new_pref'] = conjunto_final.groupby(['mrun','rbd_mayor']).cumcount() + 1

missing_rbd_mask = conjunto_final['rbd_mayor'].isnull()

conjunto_final.loc[missing_rbd_mask, 'new_pref'] = conjunto_final.loc[missing_rbd_mask, 'preferencia_postulante']

del conjunto_final['preferencia_postulante']
conjunto_final = conjunto_final.rename(columns={'new_pref': 'preferencia_postulante'})


# ### 3. Cálculo probabilidades

# In[6]:


# Corremos la fórmula

# Calculando probabilidades de asignación

conjunto_final['prob_asig_menor_t'] = np.nan
# Variable auxiliar
conjunto_final['prob_acum_menor'] = np.nan

# Loop

for i in range(0,len(conjunto_final)):
    if conjunto_final.loc[i,'preferencia_postulante'] == 1:
        conjunto_final.loc[i,'prob_asig_menor_t'] = 1 - conjunto_final.loc[i,'risk']
        conjunto_final.loc[i,'prob_acum_menor'] = conjunto_final.loc[i,'prob_asig_menor_t']
    else:
        conjunto_final.loc[i,'prob_asig_menor_t'] = (1 - conjunto_final.loc[i-1,'prob_acum_menor']) * (1 - conjunto_final.loc[i,'risk'])
        conjunto_final.loc[i,'prob_acum_menor'] = conjunto_final.loc[i,'prob_asig_menor_t'] + conjunto_final.loc[i-1,'prob_acum_menor']



# In[7]:


# Obteniendo las probabilidades finales

conjunto_final['prob_asig_menor'] = conjunto_final['prob_asig_mayor'] * conjunto_final['prob_asig_menor_t'] 

prob_asignaciones_menor = conjunto_final.groupby(['mrun','rbd']).agg({'prob_asig_menor':'sum'}).reset_index()

postulaciones_menor = pd.merge(postulaciones_menor, prob_asignaciones_menor, how = 'left', left_on =['mrun','rbd'], right_on = ['mrun','rbd'], indicator = True)
postulaciones_menor['_merge'].value_counts()


# In[8]:


# Probabilidad de no asignación

menor_no_asignado = postulaciones_menor.groupby('mrun').agg({'prob_asig_menor':'sum', 'mrun_hermano_final':'mean'}).reset_index()

menor_no_asignado['prob_no_asignado'] = 1 - menor_no_asignado['prob_asig_menor']
# Algunos aparecen con probabilidad negativa porque en realidad es 0,00000000x
menor_no_asignado.loc[(menor_no_asignado['prob_no_asignado'] < 0), 'prob_no_asignado'] = 0
del menor_no_asignado['prob_asig_menor']

menor_no_asignado = menor_no_asignado.rename(columns={'mrun': 'mrun_menor'})


# ### Prob. conjuntas

# In[9]:


# Menor

prob_menor = postulaciones_menor[['mrun','rbd','codcurso','preferencia_postulante','prob_asig_menor','mrun_hermano_final']]
prob_menor = prob_menor.rename(columns={'mrun': 'mrun_menor', 'preferencia_postulante': 'preferencia_menor','rbd':'rbd_menor', 'codcurso': 'cod_curso_menor'})

prob_menor = prob_menor.append(menor_no_asignado)

prob_menor = prob_menor.sort_values(['mrun_menor','preferencia_menor']).reset_index(drop=True)

missing_rbd_mask = prob_menor['preferencia_menor'].isnull()

prob_menor.loc[missing_rbd_mask, 'prob_asig_menor'] = prob_menor.loc[missing_rbd_mask, 'prob_no_asignado']
del prob_menor['prob_no_asignado']

# Mayor

prob_mayor = postulaciones_mayor[['mrun','rbd','codcurso','preferencia_postulante','prob_asig']]
mayor_no_asignado = mayor_no_asignado.rename(columns={'mrun_hermano_final': 'mrun'})

prob_mayor = prob_mayor.append(mayor_no_asignado)

prob_mayor = prob_mayor.sort_values(['mrun','preferencia_postulante']).reset_index(drop=True)

missing_rbd_mask = prob_mayor['preferencia_postulante'].isnull()

prob_mayor.loc[missing_rbd_mask, 'prob_asig'] = prob_mayor.loc[missing_rbd_mask, 'prob_no_asignado_mayor']
del prob_mayor['prob_no_asignado_mayor']

prob_mayor = prob_mayor.rename(columns={'mrun': 'mrun_hermano_final', 'preferencia_postulante': 'preferencia_mayor','prob_asig': 'prob_asig_mayor', 'rbd':'rbd_mayor','codcurso':'cod_curso_mayor'})

# Merging datasets

prob_conjunta_1 = pd.merge(prob_menor, prob_mayor, how = 'left', left_on = 'mrun_hermano_final', right_on = 'mrun_hermano_final', indicator = True)
prob_conjunta_1['_merge'].value_counts()
del prob_conjunta_1['_merge']

# Probabilidad conjunta

prob_conjunta_1['prob_conjunta'] = prob_conjunta_1['prob_asig_menor'] * prob_conjunta_1['prob_asig_mayor']

prob_conjunta_1 = prob_conjunta_1.sort_values(['mrun_menor','prob_conjunta'], ascending = False).reset_index(drop=True)

prob_conjunta_1['auxiliar'] = 1
prob_conjunta_1['auxiliar'] = prob_conjunta_1.groupby(['mrun_menor']).cumcount() + 1

# A veces auxiliar toma un valor pero en realidad la prob_conjunta = 0 
prob_conjunta_1.loc[(prob_conjunta_1['prob_conjunta'] == 0), 'auxiliar'] = 0

# Con auxiliar = 1 y = 2 podemos identificar los dos eventos con mayor probabilidad.


# ### Estadística

# In[10]:


# Describiendo los eventos

# 1. Necesitamos la matrícula asegurada 

matricula_asegurada = postulaciones[['mrun','rbd','codcurso','criterioprioridad']]
matricula_asegurada = matricula_asegurada[matricula_asegurada['criterioprioridad'] == 6]
del matricula_asegurada['criterioprioridad']

matricula_asegurada_menor = matricula_asegurada.rename(columns={'mrun': 'mrun_menor', 'rbd': 'rbd_mat_aseg_menor', 'codcurso': 'cod_curso_menor_mat_aseg'})
matricula_asegurada_mayor = matricula_asegurada.rename(columns={'mrun': 'mrun_hermano_final', 'rbd': 'rbd_mat_aseg_mayor', 'codcurso':'cod_curso_mayor_mat_aseg' })

prob_conjunta_1 = pd.merge(prob_conjunta_1,matricula_asegurada_menor, how = 'left', left_on = 'mrun_menor', right_on = 'mrun_menor')
prob_conjunta_1 = pd.merge(prob_conjunta_1,matricula_asegurada_mayor, how = 'left', left_on = 'mrun_hermano_final', right_on = 'mrun_hermano_final')

# En vez de que aparezca el nº con la preferencia, pondremos matrícula asegurada

prob_conjunta_1.loc[(prob_conjunta_1['rbd_menor'] == prob_conjunta_1['rbd_mat_aseg_menor']) & (prob_conjunta_1['cod_curso_menor'] == prob_conjunta_1['cod_curso_menor_mat_aseg']), 'preferencia_menor'] = 'mat_aseg'
prob_conjunta_1.loc[(prob_conjunta_1['rbd_mayor'] == prob_conjunta_1['rbd_mat_aseg_mayor']) & (prob_conjunta_1['cod_curso_mayor'] == prob_conjunta_1['cod_curso_mayor_mat_aseg']), 'preferencia_mayor'] = 'mat_aseg'

# Creando variable que combina ambas preferencias

# Convert 'preferencia_menor' and 'preferencia_mayor' columns to strings
prob_conjunta_1['preferencia_menor'] = prob_conjunta_1['preferencia_menor'].astype(str)
prob_conjunta_1['preferencia_mayor'] = prob_conjunta_1['preferencia_mayor'].astype(str)

prob_conjunta_1.loc[prob_conjunta_1['preferencia_menor'] == 'nan', 'preferencia_menor'] = 'no_asig'
prob_conjunta_1.loc[prob_conjunta_1['preferencia_mayor'] == 'nan', 'preferencia_mayor'] = 'no_asig'

# Concatenate 'preferencia_mayor' and 'preferencia_menor' columns with ':' separator
prob_conjunta_1['evento'] = prob_conjunta_1['preferencia_mayor'] + ':' + prob_conjunta_1['preferencia_menor']

# Viendo cómo se caracterizan los dos eventos más probables
prob_conjunta_1.loc[prob_conjunta_1['auxiliar'] == 1, 'evento'].value_counts().head(10)


# ## Sin postulación en bloque

# ### Creando la data

# In[11]:


# Filtramos la data

postulaciones_menor = postulaciones.loc[(postulaciones.hermano_mayor == 0)]

# Eliminamos riesgo porque los volveremos a obtener

del postulaciones_menor['risk']

# Eliminamos tipo porque lo volveremos a obtener

del postulaciones_menor['tipo']

# Pegamos las postulaciones del hermano mayor, para que cada el set de postulaciones del menor se repita para cada postulación del mayor

postulaciones_mayor_para_hermano = postulaciones_mayor[['mrun','prob_asig','rbd']]
postulaciones_mayor_para_hermano = postulaciones_mayor_para_hermano.rename(columns={'mrun': 'mrun_hermano_final', 'prob_asig': 'prob_asig_mayor', 'rbd': 'rbd_mayor'})

conjunto_postulaciones = pd.merge(postulaciones_menor, postulaciones_mayor_para_hermano, how = 'left', left_on = ['mrun_hermano_final'], right_on = ['mrun_hermano_final'], indicator = True)
conjunto_postulaciones['_merge'].value_counts()
# Todas las obs pegan :)
del conjunto_postulaciones['_merge']

# Hacemos append de las postulaciones del menor para sumar el caso en que el mayor no es asignado

mayor_no_asignado = mayor_no_asignado.rename(columns={'mrun': 'mrun_hermano_final', 'prob_no_asignado': 'prob_no_asignado_mayor'})
conjunto_no_asignado = pd.merge(postulaciones_menor, mayor_no_asignado, how = 'left', left_on = ['mrun_hermano_final'], right_on = ['mrun_hermano_final'], indicator = True)
conjunto_no_asignado['_merge'].value_counts()
# Todas las obs pegan :)
del conjunto_no_asignado['_merge']

conjunto_final = conjunto_postulaciones.append(conjunto_no_asignado)

# Ordenamos la data

conjunto_final = conjunto_final.sort_values(['mrun','rbd_mayor','preferencia_postulante']).reset_index(drop=True)


# ### Prioridad dinámica

# In[12]:


# Reemplazamos prioridad por dinámica cuando corresponda

# 1. Reemplazamos la variable criterioprioridad 
# Se reemplaza por 4 cuando criterioprioridad < 4 y es el rbd correspondiente

conjunto_final.loc[(conjunto_final['criterioprioridad'] < 4) & (conjunto_final['rbd_mayor'] == conjunto_final['rbd']), 'criterioprioridad'] = 4
conjunto_final['criterioprioridad'].value_counts()

# 2. Pegamos con la base tipos

tipos = pd.read_csv('/Users/javieragazmuri/ConsiliumBots Dropbox/Javiera Gazmuri/Archivos de javiera@consiliumbots.com/ejemploJavi/tipos_data-data2022_5r_exp0.csv')

tipos = pd.read_csv(Path + 'intermediate/simulation_probabilities/tipos_data-_oficialEqSAEAnterior_500r_exp0.csv')

tipos = tipos.rename(columns={'criterioPrioridad': 'criterioprioridad'})
del tipos['criterioPrioridad_label']
del tipos['tipo_label']

conjunto_final = pd.merge(conjunto_final, tipos, how = 'left', left_on = ['criterioprioridad','prioritario','alto_rendimiento'], right_on = ['criterioprioridad','prioritario','alto_rendimiento'], indicator = True)
conjunto_final['_merge'].value_counts()
del conjunto_final['_merge']

conjunto_final = pd.merge(conjunto_final, riesgos, how = 'left', left_on =['rbd','codcurso','tipo'], right_on = ['rbd','cod_curso','tipo'], indicator = True)
conjunto_final['_merge'].value_counts()
conjunto_final.loc[(conjunto_final['_merge'] == 'left_only'), 'risk'] = 0
del conjunto_final['_merge']


# ### Cálculo probabilidades

# In[13]:


# Corremos la fórmula

# Calculando probabilidades de asignación

conjunto_final['prob_asig_menor_t'] = np.nan
# Variable auxiliar
conjunto_final['prob_acum_menor'] = np.nan

# Loop

for i in range(0,len(conjunto_final)):
    if conjunto_final.loc[i,'preferencia_postulante'] == 1:
        conjunto_final.loc[i,'prob_asig_menor_t'] = 1 - conjunto_final.loc[i,'risk']
        conjunto_final.loc[i,'prob_acum_menor'] = conjunto_final.loc[i,'prob_asig_menor_t']
    else:
        conjunto_final.loc[i,'prob_asig_menor_t'] = (1 - conjunto_final.loc[i-1,'prob_acum_menor']) * (1 - conjunto_final.loc[i,'risk'])
        conjunto_final.loc[i,'prob_acum_menor'] = conjunto_final.loc[i,'prob_asig_menor_t'] + conjunto_final.loc[i-1,'prob_acum_menor']


# In[14]:


# Obteniendo las probabilidades finales

conjunto_final['prob_asig_menor'] = conjunto_final['prob_asig_mayor'] * conjunto_final['prob_asig_menor_t'] 

prob_asignaciones_menor = conjunto_final.groupby(['mrun','rbd']).agg({'prob_asig_menor':'sum'}).reset_index()

postulaciones_menor = pd.merge(postulaciones_menor, prob_asignaciones_menor, how = 'left', left_on =['mrun','rbd'], right_on = ['mrun','rbd'], indicator = True)
postulaciones_menor['_merge'].value_counts()


# In[15]:


# Probabilidad de no asignación

menor_no_asignado = postulaciones_menor.groupby('mrun').agg({'prob_asig_menor':'sum', 'mrun_hermano_final':'mean'}).reset_index()

menor_no_asignado['prob_no_asignado'] = 1 - menor_no_asignado['prob_asig_menor']
# Algunos aparecen con probabilidad negativa porque en realidad es 0,00000000x
menor_no_asignado.loc[(menor_no_asignado['prob_no_asignado'] < 0), 'prob_no_asignado'] = 0
del menor_no_asignado['prob_asig_menor']

menor_no_asignado = menor_no_asignado.rename(columns={'mrun': 'mrun_menor'})


# ### Prob. conjuntas

# In[16]:


# Menor

prob_menor = postulaciones_menor[['mrun','rbd','codcurso','preferencia_postulante','prob_asig_menor','mrun_hermano_final']]
prob_menor = prob_menor.rename(columns={'mrun': 'mrun_menor', 'preferencia_postulante': 'preferencia_menor','rbd':'rbd_menor', 'codcurso': 'cod_curso_menor'})

prob_menor = prob_menor.append(menor_no_asignado)

prob_menor = prob_menor.sort_values(['mrun_menor','preferencia_menor']).reset_index(drop=True)

missing_rbd_mask = prob_menor['preferencia_menor'].isnull()

prob_menor.loc[missing_rbd_mask, 'prob_asig_menor'] = prob_menor.loc[missing_rbd_mask, 'prob_no_asignado']
del prob_menor['prob_no_asignado']

# Mayor

prob_mayor = postulaciones_mayor[['mrun','rbd','codcurso','preferencia_postulante','prob_asig']]
mayor_no_asignado = mayor_no_asignado.rename(columns={'mrun_hermano_final': 'mrun'})

prob_mayor = prob_mayor.append(mayor_no_asignado)

prob_mayor = prob_mayor.sort_values(['mrun','preferencia_postulante']).reset_index(drop=True)

missing_rbd_mask = prob_mayor['preferencia_postulante'].isnull()

prob_mayor.loc[missing_rbd_mask, 'prob_asig'] = prob_mayor.loc[missing_rbd_mask, 'prob_no_asignado_mayor']
del prob_mayor['prob_no_asignado_mayor']

prob_mayor = prob_mayor.rename(columns={'mrun': 'mrun_hermano_final', 'preferencia_postulante': 'preferencia_mayor','prob_asig': 'prob_asig_mayor', 'rbd':'rbd_mayor','codcurso':'cod_curso_mayor'})

# Merging datasets

prob_conjunta_2 = pd.merge(prob_menor, prob_mayor, how = 'left', left_on = 'mrun_hermano_final', right_on = 'mrun_hermano_final', indicator = True)
prob_conjunta_2['_merge'].value_counts()
del prob_conjunta_2['_merge']

# Probabilidad conjunta

prob_conjunta_2['prob_conjunta'] = prob_conjunta_2['prob_asig_menor'] * prob_conjunta_2['prob_asig_mayor']

prob_conjunta_2 = prob_conjunta_2.sort_values(['mrun_menor','prob_conjunta'], ascending = False).reset_index(drop=True)

prob_conjunta_2['auxiliar'] = 1
prob_conjunta_2['auxiliar'] = prob_conjunta_2.groupby(['mrun_menor']).cumcount() + 1

# A veces auxiliar toma un valor pero en realidad la prob_conjunta = 0 
prob_conjunta_2.loc[(prob_conjunta_2['prob_conjunta'] == 0), 'auxiliar'] = 0

# Con auxiliar = 1 y = 2 podemos identificar los dos eventos con mayor probabilidad.


# ### Estadística

# In[17]:


# Describiendo los eventos

# 1. Necesitamos la matrícula asegurada 

matricula_asegurada = postulaciones[['mrun','rbd','codcurso','criterioprioridad']]
matricula_asegurada = matricula_asegurada[matricula_asegurada['criterioprioridad'] == 6]
del matricula_asegurada['criterioprioridad']

matricula_asegurada_menor = matricula_asegurada.rename(columns={'mrun': 'mrun_menor', 'rbd': 'rbd_mat_aseg_menor', 'codcurso': 'cod_curso_menor_mat_aseg'})
matricula_asegurada_mayor = matricula_asegurada.rename(columns={'mrun': 'mrun_hermano_final', 'rbd': 'rbd_mat_aseg_mayor', 'codcurso':'cod_curso_mayor_mat_aseg'})

prob_conjunta_2 = pd.merge(prob_conjunta_2,matricula_asegurada_menor, how = 'left', left_on = 'mrun_menor', right_on = 'mrun_menor')
prob_conjunta_2 = pd.merge(prob_conjunta_2,matricula_asegurada_mayor, how = 'left', left_on = 'mrun_hermano_final', right_on = 'mrun_hermano_final')

# En vez de que aparezca el nº con la preferencia, pondremos matrícula asegurada

prob_conjunta_2.loc[(prob_conjunta_2['rbd_menor'] == prob_conjunta_2['rbd_mat_aseg_menor']) & (prob_conjunta_2['cod_curso_menor'] == prob_conjunta_2['cod_curso_menor_mat_aseg']), 'preferencia_menor'] = 'mat_aseg'
prob_conjunta_2.loc[(prob_conjunta_2['rbd_mayor'] == prob_conjunta_2['rbd_mat_aseg_mayor']) & (prob_conjunta_2['cod_curso_mayor'] == prob_conjunta_2['cod_curso_mayor_mat_aseg']), 'preferencia_mayor'] = 'mat_aseg'

# Creando variable que combina ambas preferencias

# Convert 'preferencia_menor' and 'preferencia_mayor' columns to strings
prob_conjunta_2['preferencia_menor'] = prob_conjunta_2['preferencia_menor'].astype(str)
prob_conjunta_2['preferencia_mayor'] = prob_conjunta_2['preferencia_mayor'].astype(str)

prob_conjunta_2.loc[prob_conjunta_2['preferencia_menor'] == 'nan', 'preferencia_menor'] = 'no_asig'
prob_conjunta_2.loc[prob_conjunta_2['preferencia_mayor'] == 'nan', 'preferencia_mayor'] = 'no_asig'

# Concatenate 'preferencia_mayor' and 'preferencia_menor' columns with ':' separator
prob_conjunta_2['evento'] = prob_conjunta_2['preferencia_mayor'] + ':' + prob_conjunta_2['preferencia_menor']

# Viendo cómo se caracterizan los dos eventos más probables
prob_conjunta_2.loc[prob_conjunta_2['auxiliar'] == 1, 'evento'].value_counts().head(10)


# # Totalidad eventos

# In[18]:


# Diferencia probabilidades conjuntas

prob_conjunta_sin_bloque = prob_conjunta_2[['mrun_menor', 'evento', 'prob_conjunta','auxiliar']]
prob_conjunta_sin_bloque = prob_conjunta_sin_bloque.rename(columns={'prob_conjunta': 'prob_conjunta_sinbloque', 'auxiliar':'auxiliar_sinbloque'})

ambas_prob = pd.merge(prob_conjunta_1, prob_conjunta_sin_bloque, how = 'left', left_on = ['mrun_menor', 'evento'], right_on = ['mrun_menor', 'evento'], indicator = True)
ambas_prob['_merge'].value_counts()

ambas_prob['dif_prob'] = abs(ambas_prob['prob_conjunta'] - ambas_prob['prob_conjunta_sinbloque'])

ambas_prob = ambas_prob.sort_values(['mrun_menor','dif_prob'], ascending = False).reset_index(drop=True)

ambas_prob['auxiliar_diferencia'] = 1
ambas_prob['auxiliar_diferencia'] = ambas_prob.groupby(['mrun_menor']).cumcount() + 1

# Viendo cómo se caracterizan los eventos con mayor diferencia
ambas_prob.loc[ambas_prob['auxiliar_diferencia'].isin([1, 2]), 'evento'].value_counts().head(10)


# ## Eventos estáticos

# ### Eventos separados

# In[22]:


# Reglas:
# 1. Evento más probable con postulación familiar
# 2. Evento más probable con postulación independiente (si no está en anteriores)
# 3. 1-1 (si no está en anteriores)
# 4. más probable colegios distintos (prob. bloque o independiente, depende cual es mayor) (si no está en anteriores)

base_eventos =  ambas_prob[['mrun_menor','rbd_menor','cod_curso_menor','preferencia_menor', 'mrun_hermano_final', 'rbd_mayor','cod_curso_mayor','preferencia_mayor','evento','prob_conjunta','prob_conjunta_sinbloque']]

base_eventos['n_evento'] = 0

# Evento 1

base_eventos = base_eventos.sort_values(['mrun_menor','prob_conjunta'], ascending = False).reset_index(drop=True)

base_eventos['aux_bloque'] = 1
base_eventos['aux_bloque'] = base_eventos.groupby(['mrun_menor']).cumcount() + 1
base_eventos.loc[(base_eventos['prob_conjunta'] == 0), 'aux_bloque'] = 0

# Reemplazar nº evento
base_eventos.loc[(base_eventos['aux_bloque'] == 1), 'n_evento'] = 1

# Evento 2

base_eventos = base_eventos.sort_values(['mrun_menor','prob_conjunta_sinbloque'], ascending = False).reset_index(drop=True)

base_eventos['aux_sinbloque'] = 1
base_eventos['aux_sinbloque'] = base_eventos.groupby(['mrun_menor']).cumcount() + 1
base_eventos.loc[(base_eventos['prob_conjunta_sinbloque'] == 0), 'aux_sinbloque'] = 0

# Reemplazar nº evento
base_eventos.loc[((base_eventos['aux_sinbloque'] == 1) & (base_eventos['n_evento'] == 0)), 'n_evento'] = 2

# Evento 3

base_eventos.loc[((base_eventos['evento'] == "1.0:1.0") & (base_eventos['n_evento'] == 0)), 'n_evento'] = 3

# Evento 4
base_eventos['evento_cruzado'] = 0
base_eventos.loc[((base_eventos['rbd_menor'] != base_eventos['rbd_mayor']) & (base_eventos['rbd_menor'].notnull()) & (base_eventos['rbd_mayor'].notnull())) , 'evento_cruzado'] = 1

# Mayor del bloque
base_eventos = base_eventos.sort_values(['mrun_menor','evento_cruzado','prob_conjunta'], ascending = False).reset_index(drop=True)

base_eventos['aux_cruzado_bloq'] = 1
base_eventos['aux_cruzado_bloq'] = base_eventos.groupby(['mrun_menor']).cumcount() + 1
base_eventos.loc[((base_eventos['prob_conjunta'] == 0) | (base_eventos['evento_cruzado'] == 0)), 'aux_cruzado_bloq'] = 0

# Mayor sin bloque
base_eventos = base_eventos.sort_values(['mrun_menor','evento_cruzado','prob_conjunta_sinbloque'], ascending = False).reset_index(drop=True)

base_eventos['aux_cruzado_nobloq'] = 1
base_eventos['aux_cruzado_nobloq'] = base_eventos.groupby(['mrun_menor']).cumcount() + 1
base_eventos.loc[((base_eventos['prob_conjunta_sinbloque'] == 0) | (base_eventos['evento_cruzado'] == 0)), 'aux_cruzado_nobloq'] = 0

# Mayor prob. cruzada
base_eventos['prob_cruzada'] = 0
base_eventos.loc[(base_eventos['aux_cruzado_bloq'] == 1), 'prob_cruzada'] = base_eventos['prob_conjunta']
base_eventos.loc[(base_eventos['aux_cruzado_nobloq'] == 1), 'prob_cruzada'] = base_eventos['prob_conjunta_sinbloque']

base_eventos['prob_cruzada_final'] = base_eventos.groupby('mrun_menor')['prob_cruzada'].transform('max')

# Reemplazo variable de interés
base_eventos.loc[((base_eventos['prob_cruzada_final'] == base_eventos['prob_cruzada']) & (base_eventos['prob_cruzada'] != 0) & (base_eventos['n_evento'] == 0)), 'n_evento'] = 4

base_eventos['n_evento'].value_counts()


# ### Eventos agrupados

# In[23]:


# Juntos
juntos = base_eventos[(base_eventos['n_evento'] == 0) & (base_eventos['rbd_menor'] == base_eventos['rbd_mayor'])]
juntos = juntos.groupby(['mrun_menor','mrun_hermano_final']).agg({'prob_conjunta':'sum', 'prob_conjunta_sinbloque' : 'sum'}).reset_index()

juntos['n_evento'] = 5
juntos['evento'] = "Juntos"

# Separados
separados = base_eventos[(base_eventos['n_evento'] == 0) & (base_eventos['rbd_menor'] != base_eventos['rbd_mayor']) & (base_eventos['rbd_menor'].notnull()) & (base_eventos['rbd_mayor'].notnull())]
separados = separados.groupby(['mrun_menor','mrun_hermano_final']).agg({'prob_conjunta':'sum', 'prob_conjunta_sinbloque' : 'sum'}).reset_index()

separados['n_evento'] = 6
separados['evento'] = "Separados"

# Al menos uno no asignado
no_asignados = base_eventos[(base_eventos['n_evento'] == 0) & (base_eventos['rbd_menor'].isnull() | base_eventos['rbd_mayor'].isnull())]
no_asignados = no_asignados.groupby(['mrun_menor','mrun_hermano_final']).agg({'prob_conjunta':'sum', 'prob_conjunta_sinbloque' : 'sum'}).reset_index()

no_asignados['n_evento'] = 7
no_asignados['evento'] = "Al menos uno no asignado"


# ### Todos eventos

# In[24]:


estaticos = base_eventos[base_eventos['n_evento'] != 0]
estaticos = estaticos[['mrun_menor', 'rbd_menor','cod_curso_menor','preferencia_menor','mrun_hermano_final', 'rbd_mayor','cod_curso_mayor', 'preferencia_mayor', 'n_evento', 'evento', 'prob_conjunta', 'prob_conjunta_sinbloque']]

total_eventos = pd.concat([estaticos, juntos, separados, no_asignados], ignore_index=True)
total_eventos = total_eventos.sort_values(['mrun_menor','n_evento']).reset_index(drop=True)

# En % y sin decimales

total_eventos['prob_conjunta'] = total_eventos['prob_conjunta'] * 100
total_eventos['prob_conjunta'] = total_eventos['prob_conjunta'].apply(lambda x: round(x, 0))

total_eventos['prob_conjunta_sinbloque'] = total_eventos['prob_conjunta_sinbloque'] * 100
total_eventos['prob_conjunta_sinbloque'] = total_eventos['prob_conjunta_sinbloque'].apply(lambda x: round(x, 0))


# In[28]:


# Explicación eventos

total_eventos['explicacion'] = ""

# Matrícula asegurada

total_eventos['exp_mat_menor'] = " "
total_eventos['exp_mat_mayor'] = " "


total_eventos.loc[total_eventos['preferencia_menor'] == 'mat_aseg', 'exp_mat_menor'] = " (su establecimiento de origen)"
total_eventos.loc[total_eventos['preferencia_mayor'] == 'mat_aseg', 'exp_mat_mayor'] = " (su establecimiento de origen)"

# Juntos, no en matrícula asegurada

total_eventos.loc[(total_eventos['rbd_menor'] == total_eventos['rbd_mayor']) & (total_eventos['preferencia_menor'] != 'mat_aseg') & (total_eventos['preferencia_mayor'] != 'mat_aseg'), 'explicacion'] = "En este resultado, ambos postulantes quedan asignados en el establecimiento " + total_eventos['rbd_menor'].astype(str) + ", con " + total_eventos['prob_conjunta'].astype(str) + "% de probabilidad si elige la opción familiar y " + total_eventos['prob_conjunta_sinbloque'].astype(str) + "% si elige postulación independiente."

# Juntos, en matrícula asegurada

total_eventos.loc[(total_eventos['rbd_menor'] == total_eventos['rbd_mayor']) & (total_eventos['preferencia_menor'] == 'mat_aseg') & (total_eventos['preferencia_mayor'] == 'mat_aseg'), 'explicacion'] = "En este resultado, ambos postulantes quedan asignados en el establecimiento " + total_eventos['rbd_menor'].astype(str) + total_eventos['exp_mat_menor'] + ", con " + total_eventos['prob_conjunta'].astype(str) + "% de probabilidad si elige la opción familiar y " + total_eventos['prob_conjunta_sinbloque'].astype(str) + "% si elige postulación independiente."

# Separados

total_eventos.loc[total_eventos['rbd_menor'] != total_eventos['rbd_mayor'], 'explicacion'] = "En este resultado, {mayor} queda asignado en " + total_eventos['rbd_mayor'].astype(str) + " y {menor} queda asignado en " + total_eventos['rbd_menor'].astype(str) 


# ## Eventos dinámicos

# In[52]:


# Entre los eventos que se muestran, el con mayor probabilidad (sin bloque) cruzado (separados)

total_eventos['evento_cruzado'] = 0
total_eventos.loc[((total_eventos['rbd_menor'] != total_eventos['rbd_mayor']) & (total_eventos['rbd_menor'].notnull()) & (total_eventos['rbd_mayor'].notnull())) , 'evento_cruzado'] = 1

total_eventos['prob_cruzada'] = total_eventos['evento_cruzado'] * total_eventos['prob_conjunta_sinbloque']
total_eventos['prob_cruzada'] = total_eventos.groupby('mrun_menor')['prob_cruzada'].transform('max')

total_eventos.loc[total_eventos['prob_conjunta_sinbloque'] != total_eventos['prob_cruzada'], 'evento_cruzado'] = 0

total_eventos[['pref_mayor', 'pref_menor']] = total_eventos['evento'].str.split(':', expand=True)

# Variable: hermano que postula el próximo año

total_eventos['hermano_postula'] = 'nan'
total_eventos.loc[(total_eventos['pref_mayor'] > total_eventos['pref_menor']) & (total_eventos['evento_cruzado'] == 1), 'hermano_postula'] = 'mayor'
total_eventos.loc[(total_eventos['pref_mayor'] < total_eventos['pref_menor']) & (total_eventos['evento_cruzado'] == 1), 'hermano_postula'] = 'menor'

# Variable: colegio al que postula

total_eventos['rbd_postula'] = 'nan'
total_eventos.loc[total_eventos['hermano_postula'] == 'mayor', 'rbd_postula'] = total_eventos['rbd_menor']
total_eventos.loc[total_eventos['hermano_postula'] == 'menor', 'rbd_postula'] = total_eventos['rbd_mayor']

# Checking: necesitamos que ese colegio esté en las preferencias (superior) del hermano correspondiente


