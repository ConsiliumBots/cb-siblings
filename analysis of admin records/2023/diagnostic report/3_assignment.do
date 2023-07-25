// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Analysis of assignments
	// Created: 2022
	// Last Modified: May 31, 2023
	// Author: Javi Gazmuri

// -----------------------------------------------------------------------------

// ---------------------------------------------- //
// --------------------- DATA ------------------- //
// ---------------------------------------------- //

// ------ MAIN STAGE ------ //

	import delimited "$pathData/inputs/analysis-2021/SAE_2021/D1_Resultados_etapa_regular_2021_Admisión_2022_PUBL.csv", clear
	tempfile asig_reg
	save  `asig_reg', replace

	import delimited "$pathData/inputs/analysis-2021/SAE_2021/C1_Postulaciones_etapa_regular_2021_Admisión_2022_PUBL.csv", clear 
	tempfile postulaciones_reg
	save  `postulaciones_reg', replace

	import delimited "$pathData/inputs/analysis-2021/SAE_2021/F1_Relaciones_entre_postulantes_etapa_regular_2021_Admisión_2022_PUBL.csv", clear
	duplicates report mrun_1 mrun_2
	gen relacion = _n
	tempfile relaciones_reg
	save  `relaciones_reg', replace  // this data has no duplicate relationships. Eg: if mrun_1 = 1 & mrun_2 = 2, there is no observation with mrun_1 = 2 & mrun_2 = 1

	import delimited "$pathData/inputs/analysis-2021/SAE_2021/B1_Postulantes_etapa_regular_2021_Admisión_2022_PUBL.csv", clear
	keep mrun prioritario
	tempfile prioritario
	save  `prioritario', replace

// ---------------------------------------------- //
// --------------- 0. DATA CLEAN ---------------- //
// ---------------------------------------------- //

	// 0.1. Relations with secure enrollment in the same school

		use `postulaciones_reg', clear
		keep if prioridad_matriculado == 1
		unique mrun  								// is unique
		keep mrun rbd prioridad_matriculado agregada_por_continuidad
		rename agregada_por_continuidad continuidad

		rename (mrun prioridad_matriculado rbd continuidad) (mrun_1 prioridad_matriculado_1 rbd_matriculado_1 continuidad_1)
		tempfile asegurada_1
		save `asegurada_1', replace

		rename (mrun_1 prioridad_matriculado_1 rbd_matriculado_1 continuidad_1) (mrun_2 prioridad_matriculado_2 rbd_matriculado_2 continuidad_2)
		tempfile asegurada_2
		save `asegurada_2', replace

		use `relaciones_reg', clear
		merge m:1 mrun_1 using `asegurada_1', keep(1 3)
		replace prioridad_matriculado_1 = 0 if _merge == 1
		drop _merge

		merge m:1 mrun_2 using `asegurada_2', keep(1 3)
		replace prioridad_matriculado_2 = 0 if _merge == 1
		drop _merge

		gen 	mat_asegurada_same_school = 0
		replace mat_asegurada_same_school = 1 if prioridad_matriculado_1 == 1 & prioridad_matriculado_2 == 1 & rbd_matriculado_1 == rbd_matriculado_2

		tempfile relaciones_more_info
		save `relaciones_more_info', replace

	// 0.2. Matching assignment with applications

		use `asig_reg', clear
		destring rbd_admitido cod_curso_admitido rbd_admitido_post_resp cod_curso_admitido_post_resp respuesta_postulante_post_lista_, replace
		gen rbd_final = rbd_admitido
		replace rbd_final = rbd_admitido_post_resp if respuesta_postulante == 2 | respuesta_postulante == 6

		gen double cod_curso_final = cod_curso_admitido
		replace cod_curso_final = cod_curso_admitido_post_resp if respuesta_postulante == 2 | respuesta_postulante == 6

		gen respuesta_final = respuesta_postulante_post_lista_
		replace respuesta_final = respuesta_postulante if respuesta_postulante == 1 |  respuesta_postulante == 3  |  respuesta_postulante == 5

		rename (rbd_final cod_curso_final) (rbd cod_curso)
		merge 1:1 mrun rbd cod_curso using `postulaciones_reg'
		tab respuesta_final if _merge == 1 // Los _merge == 1 son aquellos no asignados (respuesta_final = 6)
		drop if _merge == 2
		drop _merge
		rename (rbd cod_curso)(rbd_final cod_curso_final)
		keep mrun rbd_final cod_curso_final respuesta_final respuesta_postulante preferencia_postulante rbd_admitido

		tempfile asig_post_reg
		save  `asig_post_reg', replace

	// 0.3. Matching with relations
			
		use  `relaciones_more_info', clear

		rename mrun_1 mrun
		merge m:1 mrun using `asig_post_reg', keep(3) nogen // 0 obs _merge == 1

		foreach x in mrun rbd_final cod_curso_final respuesta_final respuesta_postulante preferencia_postulante rbd_admitido {
			rename `x' `x'_1
		}

		rename mrun_2 mrun
		merge m:1 mrun using `asig_post_reg', keep(3) nogen // 0 obs _merge == 1

		foreach x in mrun rbd_final cod_curso_final respuesta_final respuesta_postulante preferencia_postulante rbd_admitido {
			rename `x' `x'_2
		}

		gen both_assigned = 0
		replace both_assigned = 1 if rbd_final_1 !=. & rbd_final_2 != .

		gen 	acceptance_1 = 0 if rbd_final_1 !=.
		replace acceptance_1 = 1 if rbd_final_1 !=. & respuesta_final_1 == 1

		gen 	acceptance_2 = 0 if rbd_final_2 !=.
		replace acceptance_2 = 1 if rbd_final_2 !=. & respuesta_final_2 == 1

		gen 	assigned_same_school = 0 
		replace assigned_same_school = 1 if rbd_final_1 == rbd_final_2 

		gen 	mayor_asignado = 0
		replace mayor_asignado = 1 if rbd_final_1 != .
		
		gen 	menor_asignado = 0
		replace menor_asignado = 1 if rbd_final_2 != .

		gen both_accept = 0
		replace both_accept = 1 if acceptance_1 == 1 & acceptance_2 == 1

		tempfile relaciones_con_asignaciones
		save `relaciones_con_asignaciones', replace

	// 0.4. Matching with number of schools applied in common

		// First, we need to eliminate rbd duplicates (and preferences aggregated by continuity) from the students' preferences
			use  `postulaciones_reg', clear

			drop if agregada_por_continuidad == 1

			keep mrun rbd preferencia_postulante cod_nivel

			collapse (min) preferencia_postulante cod_nivel, by(mrun rbd)
			bys mrun: egen order = rank(preferencia_postulante)

			unique mrun order // unique obs
			drop preferencia_postulante
			rename order preferencia_postulante

			rename rbd rbd_1_
		
		// Then, we need the wide form of preferences
			reshape wide rbd_1_ , i(mrun) j(preferencia_postulante)
			rename (mrun cod_nivel) (mrun_1 cod_nivel_1)

			tempfile postulaciones_wide
			save  `postulaciones_wide', replace

			forvalues x = 1/78 {
				rename rbd_1_`x' rbd_2_`x'
			}

			rename (mrun_1 cod_nivel_1)(mrun_2 cod_nivel_2)
			tempfile postulaciones_wide_hno
			save  `postulaciones_wide_hno', replace

		// Merging with relationship data
			use  `relaciones_reg', clear
			merge m:1 mrun_1 using `postulaciones_wide', keep(3) nogen
			merge m:1 mrun_2 using `postulaciones_wide_hno', keep(3) nogen

		// Indicator: number of schools applied in common
			forvalues x = 1/78 {
				gen is_rbd_1_`x' = 0
				forvalues y = 1/78 {
					replace is_rbd_1_`x' = `y' if rbd_1_`x' == rbd_2_`y' 
				}
				replace is_rbd_1_`x' = . if rbd_1_`x' == .  // is_rbd_1_x == . means sibling 1 has no postulation in the preference x.
				// is_rbd_1_x = 0 means sibling 1 has a postulation in the preference x, but there is no match with sibling 2.
			}

			gen n_escuelas_comun = 0
			forvalues x = 1/78 {
				replace n_escuelas_comun = n_escuelas_comun + (( is_rbd_1_`x' != . ) & ( is_rbd_1_`x' != 0 ))
			}

			tab n_escuelas_comun postula_en_bloque

			keep mrun_1 mrun_2 n_escuelas_comun
			
		merge 1:1 mrun_1 mrun_2 using `relaciones_con_asignaciones', nogen // all obs _merge == 3

	// 0.5 Drop excluded relationships

		drop if n_escuelas_comun == 0
		drop if mismo_nivel == 1

// ---------------------------------------------- //
// --------------- 1. STATISTICS ---------------- //
// ---------------------------------------------- //
		
		// 1.1. Types of relationships

			gen 	group = 1 if rbd_matriculado_1 == . & rbd_matriculado_2 == .
			replace group = 2 if rbd_matriculado_1 != . & rbd_matriculado_2 == .  
			replace group = 3 if rbd_matriculado_1 == . & rbd_matriculado_2 != .
			replace group = 4 if rbd_matriculado_1 != . & rbd_matriculado_2 != . & rbd_matriculado_1 != rbd_matriculado_2
			replace group = 5 if rbd_matriculado_1 != . & rbd_matriculado_2 != . & rbd_matriculado_1 == rbd_matriculado_2

			gen 	group_2 = 1 if group == 5
			replace group_2 = 2 if group == 1
			replace group_2 = 3 if group == 2 | group == 3 | group == 4

		// 1.2. Total and assignment rate

			tab group postula_en_bloque 
			tab group_2 postula_en_bloque

			tabstat both_assigned if postula_en_bloque == 0, stat(count) by(group)
			tabstat both_assigned if postula_en_bloque == 1, stat(count) by(group)

			tabstat both_assigned if postula_en_bloque == 0, stat(mean) by(group)
			tabstat both_assigned if postula_en_bloque == 1, stat(mean) by(group)

			tabstat both_assigned if postula_en_bloque == 0, stat(mean) by(group_2)
			tabstat both_assigned if postula_en_bloque == 1, stat(mean) by(group_2)
		
		// 1.3. Assignment distribution

			tab postula_en_bloque if both_assigned == 1 & group_2 == 2 & rbd_final_1 == rbd_final_2 
			tab postula_en_bloque if both_assigned == 1 & group_2 == 2

			tab postula_en_bloque if both_assigned == 1 & group_2 == 2 & rbd_final_1 != rbd_final_2 
			tab postula_en_bloque if both_assigned == 1 & group_2 == 2

			tab postula_en_bloque if both_assigned == 1 & group_2 == 3 & rbd_final_1 == rbd_final_2 
			tab postula_en_bloque if both_assigned == 1 & group_2 == 3

			tab postula_en_bloque if both_assigned == 1 & group_2 == 3 & rbd_final_1 != rbd_final_2 
			tab postula_en_bloque if both_assigned == 1 & group_2 == 3

			tab postula_en_bloque if both_assigned == 1 & group_2 == 1 & rbd_final_1 == rbd_final_2 & rbd_final_1 == rbd_matriculado_1
			tab postula_en_bloque if both_assigned == 1 & group_2 == 1

			tab postula_en_bloque if both_assigned == 1 & group_2 == 1 & rbd_final_1 == rbd_final_2 & rbd_final_1 != rbd_matriculado_1
			tab postula_en_bloque if both_assigned == 1 & group_2 == 1

			tab postula_en_bloque if both_assigned == 1 & group_2 == 1 & rbd_final_1 != rbd_final_2 
			tab postula_en_bloque if both_assigned == 1 & group_2 == 1

		// 2.2. Acceptances


			// 2.2.0. Number of observations

				tab group postula_en_bloque if both_assigned == 1

			// 2.2.1. Total

				tabstat both_accept if postula_en_bloque == 0 & both_assigned == 1, stat(mean) by(group)
				tabstat both_accept if postula_en_bloque == 1 & both_assigned == 1, stat(mean) by(group)

			// 2.2.2. Together: assigned to MA

				tabstat both_accept if both_assigned == 1 & group == 2 & rbd_matriculado_1 == rbd_final_1 & rbd_matriculado_1 == rbd_final_2, stat(mean) by(postula_en_bloque)
				tabstat both_accept if both_assigned == 1 & group == 3 & rbd_matriculado_2 == rbd_final_1 & rbd_matriculado_2 == rbd_final_2, stat(mean) by(postula_en_bloque)
				tabstat both_accept if both_assigned == 1 & group == 4 & ((rbd_matriculado_1 == rbd_final_1 & rbd_matriculado_1 == rbd_final_2) | (rbd_matriculado_2 == rbd_final_1 & rbd_matriculado_2 == rbd_final_2)), stat(mean) by(postula_en_bloque)
				tabstat both_accept if both_assigned == 1 & group == 5 & rbd_matriculado_2 == rbd_final_1 & rbd_matriculado_2 == rbd_final_2, stat(mean) by(postula_en_bloque)

			// 2.2.3. Together: assigned to a new school

				tabstat both_accept if both_assigned == 1 & group == 1 & rbd_final_1 == rbd_final_2, stat(mean) by(postula_en_bloque)
				tabstat both_accept if both_assigned == 1 & group == 2 & rbd_final_1 == rbd_final_2 & rbd_final_1 != rbd_matriculado_1, stat(mean) by(postula_en_bloque)
				tabstat both_accept if both_assigned == 1 & group == 3 & rbd_final_1 == rbd_final_2 & rbd_final_2 != rbd_matriculado_2, stat(mean) by(postula_en_bloque)
				tabstat both_accept if both_assigned == 1 & group == 4 & rbd_final_1 == rbd_final_2 & rbd_final_1 != rbd_matriculado_1 & rbd_final_2 != rbd_matriculado_2, stat(mean) by(postula_en_bloque)
				tabstat both_accept if both_assigned == 1 & group == 5 & rbd_final_1 == rbd_final_2 & rbd_final_1 != rbd_matriculado_1, stat(mean) by(postula_en_bloque)

			// 2.2.4. Separated: assigned to MA

				tabstat both_accept if both_assigned == 1 & group == 2 & rbd_final_1 != rbd_final_2 & rbd_final_1 == rbd_matriculado_1, stat(mean) by(postula_en_bloque)
				tabstat both_accept if both_assigned == 1 & group == 3 & rbd_final_1 != rbd_final_2 & rbd_final_2 == rbd_matriculado_2, stat(mean) by(postula_en_bloque)
				tabstat both_accept if both_assigned == 1 & group == 4 & rbd_final_1 != rbd_final_2 & (rbd_final_1 == rbd_matriculado_1 | rbd_final_2 == rbd_matriculado_2), stat(mean) by(postula_en_bloque)
				tabstat both_accept if both_assigned == 1 & group == 5 & rbd_final_1 != rbd_final_2 & (rbd_final_1 == rbd_matriculado_1 | rbd_final_2 == rbd_matriculado_2), stat(mean) by(postula_en_bloque)

			// 2.2.5. Separated: new schools

				tabstat both_accept if both_assigned == 1 & group == 1 & rbd_final_1 != rbd_final_2, stat(mean) by(postula_en_bloque)
				tabstat both_accept if both_assigned == 1 & group == 2 & rbd_final_1 != rbd_final_2 & rbd_final_1 != rbd_matriculado_1, stat(mean) by(postula_en_bloque)
				tabstat both_accept if both_assigned == 1 & group == 3 & rbd_final_1 != rbd_final_2 & rbd_final_2 != rbd_matriculado_2, stat(mean) by(postula_en_bloque)
				tabstat both_accept if both_assigned == 1 & group == 4 & rbd_final_1 != rbd_final_2 & rbd_final_1 != rbd_matriculado_1 & rbd_final_2 != rbd_matriculado_2, stat(mean) by(postula_en_bloque)
				tabstat both_accept if both_assigned == 1 & group == 5 & rbd_final_1 != rbd_final_2 & rbd_final_1 != rbd_matriculado_1 & rbd_final_2 != rbd_matriculado_2, stat(mean) by(postula_en_bloque)

	// 4. Simulations

		// 4.1 Cases 

			// 4.1.0 Applications data base with program_id

				import delimited "$pathData/inputs/analysis-2021/SAE_2021/Simulaciones/applications.csv", clear 
				collapse (mean) ranking_program, by(applicant_id institution_id program_id)
				tempfile applications
				save `applications'

			// 4.1.1 Dynamic priority = Yes, Fam app = Yes

				import delimited "$pathData/inputs/analysis-2021/SAE_2021/Simulaciones/results_true_true.csv", clear
				merge 1:1 applicant_id institution_id program_id using `applications', keep (1 3)
				count if _merge == 1 & institution_id != . // 0 obs

				keep applicant_id institution_id ranking_program

				preserve
					rename (applicant_id institution_id ranking_program) (mrun_1 rbd_1_sim1 ranking_program_1_sim1)
					tempfile simulacion_1_mayor
					save  `simulacion_1_mayor', replace
				restore

				rename (applicant_id institution_id ranking_program) (mrun_2 rbd_2_sim1 ranking_program_2_sim1)
				tempfile simulacion_1_menor
				save  `simulacion_1_menor', replace

				use  `relaciones_con_asignaciones', replace
				merge m:1 mrun_1 using `simulacion_1_mayor', keep(3) nogen
				merge m:1 mrun_2 using `simulacion_1_menor', keep(3) nogen

				tempfile relaciones_sim1
				save `relaciones_sim1', replace

			// 4.1.2 Dynamic priority = No, Fam app = Yes

				import delimited "$pathData/inputs/analysis-2021/SAE_2021/Simulaciones/results_false_true.csv", clear
				merge 1:m applicant_id institution_id program_id using `applications', keep (1 3)
				count if _merge == 1 & institution_id != . // 0 obs				
				
				keep applicant_id institution_id ranking_program

				preserve
					rename (applicant_id institution_id ranking_program) (mrun_1 rbd_1_sim2 ranking_program_1_sim2)
					tempfile simulacion_2_mayor
					save  `simulacion_2_mayor', replace
				restore

				rename (applicant_id institution_id ranking_program) (mrun_2 rbd_2_sim2 ranking_program_2_sim2)
				tempfile simulacion_2_menor
				save  `simulacion_2_menor', replace

				use  `relaciones_sim1', replace
				merge m:1 mrun_1 using `simulacion_2_mayor', keep(3) nogen
				merge m:1 mrun_2 using `simulacion_2_menor', keep(3) nogen

				tempfile relaciones_sim2
				save `relaciones_sim2', replace

			// 4.1.3 Dynamic priority = Yes, Fam app = No

				import delimited "$pathData/inputs/analysis-2021/SAE_2021/Simulaciones/results_true_false.csv", clear
				merge 1:m applicant_id institution_id program_id using `applications', keep (1 3)
				count if _merge == 1 & institution_id != . // 0 obs		
								
				keep applicant_id institution_id ranking_program

				preserve
					rename (applicant_id institution_id ranking_program) (mrun_1 rbd_1_sim3 ranking_program_1_sim3)
					tempfile simulacion_3_mayor
					save  `simulacion_3_mayor', replace
				restore

				rename (applicant_id institution_id ranking_program) (mrun_2 rbd_2_sim3 ranking_program_2_sim3)
				tempfile simulacion_3_menor
				save  `simulacion_3_menor', replace

				use  `relaciones_sim2', replace
				merge m:1 mrun_1 using `simulacion_3_mayor', keep(3) nogen
				merge m:1 mrun_2 using `simulacion_3_menor', keep(3) nogen

				tempfile relaciones_sim3
				save `relaciones_sim3', replace

			// 4.1.4 Dynamic priority = No, Fam app = No

				import delimited "$pathData/inputs/analysis-2021/SAE_2021/Simulaciones/results_false_false.csv", clear
				merge 1:m applicant_id institution_id program_id using `applications', keep (1 3)
				count if _merge == 1 & institution_id != . // 0 obs						
				keep applicant_id institution_id ranking_program

				preserve
					rename (applicant_id institution_id ranking_program) (mrun_1 rbd_1_sim4 ranking_program_1_sim4)
					tempfile simulacion_4_mayor
					save  `simulacion_4_mayor', replace
				restore

				rename (applicant_id institution_id ranking_program) (mrun_2 rbd_2_sim4 ranking_program_2_sim4)
				tempfile simulacion_4_menor
				save  `simulacion_4_menor', replace

				use  `relaciones_sim3', replace
				merge m:1 mrun_1 using `simulacion_4_mayor', keep(3) nogen
				merge m:1 mrun_2 using `simulacion_4_menor', keep(3) nogen

			// 4.1.5 Paste with secure enrollment data

				merge m:1 mrun_1 using `asegurada_1', keep(1 3) nogen
				merge m:1 mrun_2 using `asegurada_2', keep(1 3) nogen

		// 4.2 Analysis

			// Assigned
				count if rbd_1_sim1 != . & rbd_2_sim1 != .
				count if rbd_1_sim2 != . & rbd_2_sim2 != .
				count if rbd_1_sim3 != . & rbd_2_sim3 != .
				count if rbd_1_sim4 != . & rbd_2_sim4 != .

			// Assigned same school

				// Secure enrollment school

					count if rbd_1_sim1 == rbd_2_sim1 & rbd_1_sim1 != . & rbd_2_sim1 != . & (rbd_1_sim1 == rbd_matriculado_1 | rbd_1_sim1 == rbd_matriculado_2)
					count if rbd_1_sim2 == rbd_2_sim2 & rbd_1_sim2 != . & rbd_2_sim2 != . & (rbd_1_sim2 == rbd_matriculado_1 | rbd_1_sim2 == rbd_matriculado_2)
					count if rbd_1_sim3 == rbd_2_sim3 & rbd_1_sim3 != . & rbd_2_sim3 != . & (rbd_1_sim3 == rbd_matriculado_1 | rbd_1_sim3 == rbd_matriculado_2)
					count if rbd_1_sim4 == rbd_2_sim4 & rbd_1_sim4 != . & rbd_2_sim4 != . & (rbd_1_sim4 == rbd_matriculado_1 | rbd_1_sim4 == rbd_matriculado_2)


				// Not the a secure enrollment school

					count if rbd_1_sim1 == rbd_2_sim1 & rbd_1_sim1 != . & rbd_2_sim1 != . & rbd_1_sim1 != rbd_matriculado_1 & rbd_1_sim1 != rbd_matriculado_2
					count if rbd_1_sim2 == rbd_2_sim2 & rbd_1_sim2 != . & rbd_2_sim2 != . & rbd_1_sim2 != rbd_matriculado_1 & rbd_1_sim2 != rbd_matriculado_2
					count if rbd_1_sim3 == rbd_2_sim3 & rbd_1_sim3 != . & rbd_2_sim3 != . & rbd_1_sim3 != rbd_matriculado_1 & rbd_1_sim3 != rbd_matriculado_2
					count if rbd_1_sim4 == rbd_2_sim4 & rbd_1_sim4 != . & rbd_2_sim4 != . & rbd_1_sim4 != rbd_matriculado_1 & rbd_1_sim4 != rbd_matriculado_2

			// Mean of ranking place of the assignment
				tabstat ranking_program_1_sim1 ranking_program_1_sim2 ranking_program_1_sim3 ranking_program_1_sim4, stat(mean)  // older sibling
				tabstat ranking_program_2_sim1 ranking_program_2_sim2 ranking_program_2_sim3 ranking_program_2_sim4, stat(mean)  // younger sibling

			// Ones assigned thanks to fam app
				gen 	benefited_fam_app = 0 if postula_en_bloque == 1
				replace benefited_fam_app = 1 if postula_en_bloque == 1 & rbd_1_sim3 != rbd_2_sim3 & rbd_1_sim3 != . & rbd_2_sim3 != . & rbd_1_sim1 == rbd_2_sim1 & rbd_1_sim1 != . & rbd_2_sim1 != .

				tab respuesta_postulante_1 if benefited_fam_app == 1  // older
				tab respuesta_postulante_2 if benefited_fam_app == 1  // younger

				tab respuesta_postulante_1 if postula_en_bloque == 1 & rbd_1_sim1 == rbd_2_sim1 & rbd_1_sim1 != . & rbd_2_sim1 != .  // comparison group, assigned together
				tab respuesta_postulante_2 if postula_en_bloque == 1 & rbd_1_sim1 == rbd_2_sim1 & rbd_1_sim1 != . & rbd_2_sim1 != .  // comparison group, assigned together
				tab respuesta_postulante_1 if postula_en_bloque == 1 & rbd_1_sim1 != rbd_2_sim1 & rbd_1_sim1 != . & rbd_2_sim1 != .  // comparison group, not assigned together
				tab respuesta_postulante_2 if postula_en_bloque == 1 & rbd_1_sim1 != rbd_2_sim1 & rbd_1_sim1 != . & rbd_2_sim1 != .  // comparison group, not assigned together

				tabstat ranking_program_2_sim3 if benefited_fam_app == 1, stat(mean) 	// preference without fam app of younger sibling
				tabstat ranking_program_2_sim1 if benefited_fam_app == 1, stat(mean) 	// preference with fam app of younger sibling

