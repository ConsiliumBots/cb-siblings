// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Stats for implementation report - Yale deliverable
	// Created: March 20, 2024
	// Last Modified: March 20, 2024
	// Author: Javi Gazmuri
// -----------------------------------------------------------------------------

    // -------------------------------------------------
    // Interventions
    // -------------------------------------------------

		// % of total applicants 

			// Main round 

				import delimited "$pathData_feedback_reg/3_outputs/2_tablas_auxiliares/modulo_hermanos/reports_family_simulation_2023-08-28.csv", clear 
				tempfile cartilla_regular
				save `cartilla_regular', replace 

				import delimited "$main_sae/datos_SAE/1_Source/1_Principal/postulaciones/datos_jpal_2023-08-28.csv", clear
				keep id_apoderado
				duplicates drop 

				merge 1:1 id_apoderado using `cartilla_regular', keep(1 3)
				tab _merge 

			// Comp. round

				import delimited "$pathData_feedback_comp/3_outputs/2_tablas_auxiliares/modulo_hermanos/reports_family_simulation_2023-11-21.csv", clear
				tempfile cartilla_comp
				save `cartilla_comp', replace 

				import delimited "$main_sae/datos_SAE/1_Source/2_Complementario/postulaciones/datos_jpal_2023-11-21.csv", clear
				keep id_apoderado
				duplicates drop 

				merge 1:1 id_apoderado using `cartilla_comp', keep(1 3)
				tab _merge 

		// Opened the website

			// Main round

				import delimited "$pathData/intermediate/feedback/2023/clean_data/consolidated_data_reg.csv", clear
				tab apertura_cartilla
				tab apertura_post_fam 
				tab apertura_video
				tab apertura_dynamic if tiene_dinamico == 1

			// Comp. round

				import delimited "$pathData/intermediate/feedback/2023/clean_data/consolidated_data_comp.csv", clear
				tab apertura_cartilla
				tab apertura_post_fam 
				tab apertura_video
				tab apertura_dynamic if tiene_dinamico == 1

		// Mean of number of events 

			import delimited "$pathData/intermediate/feedback/2023/clean_data/consolidated_data_reg.csv", clear
			
			gen n_eventos_prin = 1 + tiene_segundo_evento + tiene_tercer_evento + tiene_cuarto_evento
			tabstat n_eventos_prin

			gen n_eventos_agrup = tiene_juntos + tiene_separados + tiene_no_asignados
			tabstat n_eventos_agrup

    // -------------------------------------------------
    // Online survey
    // -------------------------------------------------

		import delimited "$pathData/intermediate/feedback/2023/clean_data/consolidated_data_reg.csv", clear
		tab con_encuesta

    // -------------------------------------------------
    // Phone survey
    // -------------------------------------------------

		import delimited "$pathData/outputs/telephone_survey/inputs_encuesta.csv", clear 
		count // target population