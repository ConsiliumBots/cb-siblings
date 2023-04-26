// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Analysis of assignments
	// Created: 2022
	// Last Modified: Mar 23, 2023
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

// ------------------------------------------------------- //
// -------------- ASSIGNMENT AND RESPONSES --------------- //
// ------------------------------------------------------- //

	// 1. Data clean

		// 1.1 Matching assignment with applications

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
	
		// 1.2 Matching with relations
				
			use  `relaciones_reg', clear

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

			keep if mismo_nivel == 0

			tempfile relaciones_con_asignaciones
			save `relaciones_con_asignaciones', replace

/*
	// 2. Analysis

		// # Assigned
			count if both_assigned == 1 & postula_en_bloque == 1
			count if postula_en_bloque == 1

			count if both_assigned == 1 & postula_en_bloque == 0
			count if postula_en_bloque == 0

		// # Assigned same school
			count if rbd_final_1 == rbd_final_2 & both_assigned == 1 & postula_en_bloque == 1
			count if postula_en_bloque == 1

			count if rbd_final_1 == rbd_final_2 & both_assigned == 1 & postula_en_bloque == 0
			count if postula_en_bloque == 0
			
		// Acceptance rate regarding preferences and assignment to the same school (_1 older sibling, _2 younger).

			// Fam app + assigned to the same school

				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 1 & preferencia_postulante_2 == 1, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 1 & preferencia_postulante_2 == 2, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 1 & preferencia_postulante_2 == 3, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 1 & preferencia_postulante_2 == 4, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 1 & preferencia_postulante_2 >= 5, stat(mean)

				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 2 & preferencia_postulante_2 == 1, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 2 & preferencia_postulante_2 == 2, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 2 & preferencia_postulante_2 == 3, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 2 & preferencia_postulante_2 == 4, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 2 & preferencia_postulante_2 >= 5, stat(mean)

				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 3 & preferencia_postulante_2 == 1, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 3 & preferencia_postulante_2 == 2, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 3 & preferencia_postulante_2 == 3, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 3 & preferencia_postulante_2 == 4, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 3 & preferencia_postulante_2 >= 5, stat(mean)

				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 4 & preferencia_postulante_2 == 1, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 4 & preferencia_postulante_2 == 2, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 4 & preferencia_postulante_2 == 3, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 4 & preferencia_postulante_2 == 4, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 4 & preferencia_postulante_2 >= 5, stat(mean)

				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 >= 5 & preferencia_postulante_2 == 1, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 >= 5 & preferencia_postulante_2 == 2, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 >= 5 & preferencia_postulante_2 == 3, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 >= 5 & preferencia_postulante_2 == 4, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 >= 5 & preferencia_postulante_2 >= 5, stat(mean)

			// Fam app + not assigned to the same school

				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 1 & preferencia_postulante_2 == 1, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 1 & preferencia_postulante_2 == 2, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 1 & preferencia_postulante_2 == 3, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 1 & preferencia_postulante_2 == 4, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 1 & preferencia_postulante_2 >= 5, stat(mean)

				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 2 & preferencia_postulante_2 == 1, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 2 & preferencia_postulante_2 == 2, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 2 & preferencia_postulante_2 == 3, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 2 & preferencia_postulante_2 == 4, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 2 & preferencia_postulante_2 >= 5, stat(mean)

				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 3 & preferencia_postulante_2 == 1, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 3 & preferencia_postulante_2 == 2, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 3 & preferencia_postulante_2 == 3, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 3 & preferencia_postulante_2 == 4, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 3 & preferencia_postulante_2 >= 5, stat(mean)

				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 4 & preferencia_postulante_2 == 1, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 4 & preferencia_postulante_2 == 2, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 4 & preferencia_postulante_2 == 3, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 4 & preferencia_postulante_2 == 4, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 4 & preferencia_postulante_2 >= 5, stat(mean)

				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 >= 5 & preferencia_postulante_2 == 1, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 >= 5 & preferencia_postulante_2 == 2, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 >= 5 & preferencia_postulante_2 == 3, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 >= 5 & preferencia_postulante_2 == 4, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 1 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 >= 5 & preferencia_postulante_2 >= 5, stat(mean)

			// No fam app + assigned to the same school

				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 1 & preferencia_postulante_2 == 1, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 1 & preferencia_postulante_2 == 2, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 1 & preferencia_postulante_2 == 3, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 1 & preferencia_postulante_2 == 4, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 1 & preferencia_postulante_2 >= 5, stat(mean)

				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 2 & preferencia_postulante_2 == 1, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 2 & preferencia_postulante_2 == 2, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 2 & preferencia_postulante_2 == 3, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 2 & preferencia_postulante_2 == 4, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 2 & preferencia_postulante_2 >= 5, stat(mean)

				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 3 & preferencia_postulante_2 == 1, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 3 & preferencia_postulante_2 == 2, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 3 & preferencia_postulante_2 == 3, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 3 & preferencia_postulante_2 == 4, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 3 & preferencia_postulante_2 >= 5, stat(mean)

				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 4 & preferencia_postulante_2 == 1, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 4 & preferencia_postulante_2 == 2, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 4 & preferencia_postulante_2 == 3, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 4 & preferencia_postulante_2 == 4, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 == 4 & preferencia_postulante_2 >= 5, stat(mean)

				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 >= 5 & preferencia_postulante_2 == 1, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 >= 5 & preferencia_postulante_2 == 2, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 >= 5 & preferencia_postulante_2 == 3, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 >= 5 & preferencia_postulante_2 == 4, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 == rbd_final_2 & preferencia_postulante_1 >= 5 & preferencia_postulante_2 >= 5, stat(mean)

			// No fam app + not assigned to the same school

				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 1 & preferencia_postulante_2 == 1, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 1 & preferencia_postulante_2 == 2, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 1 & preferencia_postulante_2 == 3, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 1 & preferencia_postulante_2 == 4, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 1 & preferencia_postulante_2 >= 5, stat(mean)

				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 2 & preferencia_postulante_2 == 1, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 2 & preferencia_postulante_2 == 2, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 2 & preferencia_postulante_2 == 3, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 2 & preferencia_postulante_2 == 4, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 2 & preferencia_postulante_2 >= 5, stat(mean)

				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 3 & preferencia_postulante_2 == 1, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 3 & preferencia_postulante_2 == 2, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 3 & preferencia_postulante_2 == 3, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 3 & preferencia_postulante_2 == 4, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 3 & preferencia_postulante_2 >= 5, stat(mean)

				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 4 & preferencia_postulante_2 == 1, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 4 & preferencia_postulante_2 == 2, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 4 & preferencia_postulante_2 == 3, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 4 & preferencia_postulante_2 == 4, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 == 4 & preferencia_postulante_2 >= 5, stat(mean)

				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 >= 5 & preferencia_postulante_2 == 1, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 >= 5 & preferencia_postulante_2 == 2, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 >= 5 & preferencia_postulante_2 == 3, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 >= 5 & preferencia_postulante_2 == 4, stat(mean)
				tabstat acceptance_1 acceptance_2 if both_assigned == 1 & postula_en_bloque == 0 & rbd_final_1 != rbd_final_2 & preferencia_postulante_1 >= 5 & preferencia_postulante_2 >= 5, stat(mean)

		// Regresions

			gen 	assigned_same_school = 0 
			replace assigned_same_school = 1 if rbd_final_1 == rbd_final_2 

			gen 	mayor_asignado = 0
			replace mayor_asignado = 1 if rbd_final_1 != .
			
			gen 	menor_asignado = 0
			replace menor_asignado = 1 if rbd_final_2 != .

			reg acceptance_1 preferencia_postulante_1 if postula_en_bloque == 1
			reg acceptance_1 preferencia_postulante_1 i.menor_asignado if postula_en_bloque == 1
			reg acceptance_1 preferencia_postulante_1 i.assigned_same_school if both_assigned == 1 & postula_en_bloque == 1
			reg acceptance_1 preferencia_postulante_1 i.assigned_same_school preferencia_postulante_2 if both_assigned == 1 & postula_en_bloque == 1

			reg acceptance_2 preferencia_postulante_2 if postula_en_bloque == 1
			reg acceptance_2 preferencia_postulante_2 i.mayor_asignado if postula_en_bloque == 1
			reg acceptance_2 preferencia_postulante_2 i.assigned_same_school if both_assigned == 1 & postula_en_bloque == 1
			reg acceptance_2 preferencia_postulante_2 i.assigned_same_school preferencia_postulante_1 if both_assigned == 1 & postula_en_bloque == 1

			reg acceptance_1 preferencia_postulante_1 if postula_en_bloque == 0
			reg acceptance_1 preferencia_postulante_1 i.menor_asignado if postula_en_bloque == 0
			reg acceptance_1 preferencia_postulante_1 i.assigned_same_school if both_assigned == 1 & postula_en_bloque == 0
			reg acceptance_1 preferencia_postulante_1 i.assigned_same_school preferencia_postulante_2 if both_assigned == 1 & postula_en_bloque == 0

			reg acceptance_2 preferencia_postulante_2 if postula_en_bloque == 0
			reg acceptance_2 preferencia_postulante_2 i.mayor_asignado if postula_en_bloque == 0
			reg acceptance_2 preferencia_postulante_2 i.assigned_same_school if both_assigned == 1 & postula_en_bloque == 0
			reg acceptance_2 preferencia_postulante_2 i.assigned_same_school preferencia_postulante_1 if both_assigned == 1 & postula_en_bloque == 0


*/


	// 3. Simulations

		// 3.1 Cases 

			// 3.1.0 Applications data base with program_id

				import delimited "$pathData/inputs/analysis-2021/SAE_2021/Simulaciones/applications.csv", clear 
				collapse (mean) ranking_program, by(applicant_id institution_id program_id)
				tempfile applications
				save `applications'

			// 3.1.1 Dynamic priority = Yes, Fam app = Yes

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

			// 3.1.2 Dynamic priority = No, Fam app = Yes

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

			// 3.1.3 Dynamic priority = Yes, Fam app = No

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

			// 3.1.4 Dynamic priority = No, Fam app = No

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
		
		// 3.2 Analysis

			// Assigned
				count if rbd_1_sim1 != . & rbd_2_sim1 != .
				count if rbd_1_sim2 != . & rbd_2_sim2 != .
				count if rbd_1_sim3 != . & rbd_2_sim3 != .
				count if rbd_1_sim4 != . & rbd_2_sim4 != .

			// Assigned same school
				count if rbd_1_sim1 == rbd_2_sim1 & rbd_1_sim1 != . & rbd_2_sim1 != .
				count if rbd_1_sim2 == rbd_2_sim2 & rbd_1_sim2 != . & rbd_2_sim2 != .
				count if rbd_1_sim3 == rbd_2_sim3 & rbd_1_sim3 != . & rbd_2_sim3 != .
				count if rbd_1_sim4 == rbd_2_sim4 & rbd_1_sim4 != . & rbd_2_sim4 != .

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

