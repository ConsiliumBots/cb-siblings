// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Data for Sankey Diagrams
	// Created: 2023
	// Last Modified: June 15, 2023
	// Author: Javi Gazmuri

// -----------------------------------------------------------------------------

// ---------------------------------------------- //
// --------------------- DATA ------------------- //
// ---------------------------------------------- //

// ------ 2021: MAIN STAGE ------ //

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

// ------ 2021: COMP. STAGE ------ //

    import delimited "$pathData/inputs/analysis-2021/SAE_2021/D2_Resultados_etapa_complementaria_2021_Admisión_2022_PUBL.csv", clear
    keep mrun rbd_admitido
    rename rbd_admitido rbd_asignacion_comp_1
    rename mrun mrun_1
    tempfile postulantes_comp_1
    save `postulantes_comp_1', replace
    
    rename (mrun_1 rbd_asignacion_comp_1)(mrun_2 rbd_asignacion_comp_2)
    tempfile postulantes_comp_2
    save `postulantes_comp_2', replace

// ------ 2021: ENROLLMENT ------ //

    import delimited "$pathData/inputs/analysis-2021/Matrícula 2022/20220908_Matrícula_unica_2022_20220430_WEB.CSV", clear
    keep mrun rbd
    rename rbd rbd_enroll_final_1
    rename mrun mrun_1
    tempfile enrollment_1
    save `enrollment_1', replace

    rename (mrun_1 rbd_enroll_final_1)(mrun_2 rbd_enroll_final_2)
    tempfile enrollment_2
    save `enrollment_2', replace

// ------ 2022: MAIN STAGE ------ //

    import delimited "$pathData/inputs/analysis-2021/SAE_2022/B1_Postulantes_etapa_regular_2022_Admisión_2023_PUBL.csv", clear
    keep mrun
    tempfile postulantes_reg_2022
    save `postulantes_reg_2022', replace

    import delimited "$pathData/inputs/analysis-2021/SAE_2022/B2_Postulantes_etapa_complementaria_2022_Admisión_2023_PUBL.csv", clear
    keep mrun
    merge 1:1 mrun using `postulantes_reg_2022', nogen

    rename mrun mrun_1
    tempfile postulantes_2022_1
    save `postulantes_2022_1', replace
    
    rename mrun mrun_2
    tempfile postulantes_2022_2
    save `postulantes_2022_2', replace
 
// ---------------------------------------------- //
// --------------- CREATING THE FLOW ------------ //
// ---------------------------------------------- //

    // 1. Data clean

		// 1.1. Relations with secure enrollment in the same school

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

		// 1.2. Matching assignment with applications

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
	
		// 1.3. Matching with relations
				
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

			keep if mismo_nivel == 0

			gen both_assigned = 0
			replace both_assigned = 1 if rbd_final_1 !=. & rbd_final_2 != .

			gen 	assigned_same_school = 0 
			replace assigned_same_school = 1 if rbd_final_1 == rbd_final_2 

			gen 	mayor_asignado = 0
			replace mayor_asignado = 1 if rbd_final_1 != .
			
			gen 	menor_asignado = 0
			replace menor_asignado = 1 if rbd_final_2 != .

			tempfile relaciones_con_asignaciones
			save `relaciones_con_asignaciones', replace

		// 1.4. Matching with number of schools applied in common

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

				drop if mismo_nivel == 1

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

		drop if n_escuelas_comun == 0

    // 2. Creando categorías y variables

        gen     group_2 = .
        replace group_2 = 1 if rbd_final_1 == rbd_final_2 & rbd_matriculado_1 == rbd_final_1 & rbd_matriculado_2 == rbd_final_2 & rbd_final_1 != . // juntos MA
        replace group_2 = 2 if rbd_final_1 == rbd_final_2 & rbd_matriculado_1 != rbd_final_1 & rbd_matriculado_2 != rbd_final_2 & rbd_final_1 != . // juntos nuevo colegio
        replace group_2 = 3 if rbd_final_1 != rbd_final_2 & rbd_final_1 != . & rbd_final_2 != . // separados
        replace group_2 = 4 if rbd_final_1 == . | rbd_final_2 == . // al menos uno no asignado
        replace group_2 = 5 if group_2 == . // otros: juntos, MA de uno (solo uno)
    
		gen 	acceptance_1 = 0
		replace acceptance_1 = 1 if respuesta_final_1 == 1

		gen 	acceptance_2 = 0
		replace acceptance_2 = 1 if respuesta_final_2 == 1

    // 3. Pegando con la data de etapa complementaria

        merge m:1 mrun_1 using `postulantes_comp_1', keep (1 3) gen(_merge_1)
        merge m:1 mrun_2 using `postulantes_comp_2', keep (1 3) gen(_merge_2)

        gen     postula_comp_1 = 0
        replace postula_comp_1 = 1 if _merge_1 == 3

        gen     postula_comp_2 = 0
        replace postula_comp_2 = 1 if _merge_2 == 3

        destring rbd_asignacion_comp_1 rbd_asignacion_comp_2, replace

        drop _merge_1 _merge_2

    // 4. Pegando con la data de matrícula

        merge m:1 mrun_1 using `enrollment_1', keep (1 3) nogen
        merge m:1 mrun_2 using `enrollment_2', keep (1 3) nogen

        gen     matricula_asignacion_1 = 0 
        replace matricula_asignacion_1 = 1 if (rbd_enroll_final_1 == rbd_final_1 | rbd_enroll_final_1 == rbd_asignacion_comp_1) & rbd_enroll_final_1 != .

        gen     matricula_asignacion_2 = 0 
        replace matricula_asignacion_2 = 1 if (rbd_enroll_final_2 == rbd_final_2 | rbd_enroll_final_2 == rbd_asignacion_comp_2) & rbd_enroll_final_2 != .

    // 5. Postula el próximo año

        merge m:1 mrun_1 using `postulantes_2022_1', keep(1 3) gen(_merge_1)
        merge m:1 mrun_2 using `postulantes_2022_2', keep(1 3) gen(_merge_2)
    
        gen     postula_2022_1 = 0
        replace postula_2022_1 = 1 if _merge_1 == 3

        gen     postula_2022_2 = 0
        replace postula_2022_2 = 1 if _merge_2 == 3

    // 6. Variables finales

        gen     cat_aceptan = .
        replace cat_aceptan = 6 if acceptance_1 == 1 & acceptance_2 == 1
        replace cat_aceptan = 7 if cat_aceptan == . & (acceptance_1 == 1 | acceptance_2 == 1)
        replace cat_aceptan = 8 if acceptance_1 == 0 & acceptance_2 == 0

        gen     cat_post_comp = .
        replace cat_post_comp = 9 if postula_comp_1 == 1 & postula_comp_2 == 1
        replace cat_post_comp = 10 if cat_post_comp == . & (postula_comp_1 == 1 | postula_comp_2 == 1)
        replace cat_post_comp = 11 if postula_comp_1 == 0 & postula_comp_2 == 0

        gen     cat_matricula = .
        replace cat_matricula = 12 if matricula_asignacion_1 == 1 & matricula_asignacion_2 == 1
        replace cat_matricula = 13 if cat_matricula == . & (matricula_asignacion_1 == 1 | matricula_asignacion_2 == 1)
        replace cat_matricula = 14 if matricula_asignacion_1 == 0 & matricula_asignacion_2 == 0
  
        gen     cat_postula_2022 = .
        replace cat_postula_2022 = 15 if postula_2022_1 == 1 & postula_2022_2 == 1
        replace cat_postula_2022 = 16 if postula_2022_1 == 1 & postula_2022_2 == 0
        replace cat_postula_2022 = 17 if postula_2022_1 == 0 & postula_2022_2 == 1
        replace cat_postula_2022 = 18 if postula_2022_1 == 0 & postula_2022_2 == 0
     
        gen aux = 1

        // collapse (sum) aux, by(postula_en_bloque group_2 cat_aceptan cat_post_comp cat_matricula cat_postula_2022)

        preserve
            collapse (sum) aux, by(postula_en_bloque group_2 cat_aceptan cat_post_comp cat_matricula cat_postula_2022)
			keep if postula_en_bloque == 1
            drop postula_en_bloque
            export delimited "$pathData/intermediate/flow_sankey.csv", replace
        restore

        preserve
			collapse (sum) aux, by(postula_en_bloque group_2 cat_aceptan cat_post_comp cat_matricula cat_postula_2022)
            keep if postula_en_bloque == 0
            drop postula_en_bloque
            export delimited "$pathData/intermediate/flow_sankey_regular.csv", replace
        restore

		preserve
			collapse (sum) aux, by(group_2 cat_aceptan cat_post_comp cat_matricula cat_postula_2022)
            keep if group_2 == 1
            export delimited "$pathData/intermediate/group_2_juntos_ma.csv", replace
        restore

		preserve
			collapse (sum) aux, by(group_2 cat_aceptan cat_post_comp cat_matricula cat_postula_2022)
            keep if group_2 == 2
            export delimited "$pathData/intermediate/group_2_juntos_nuevo.csv", replace
        restore

		preserve
			collapse (sum) aux, by(group_2 cat_aceptan cat_post_comp cat_matricula cat_postula_2022)
            keep if group_2 == 3
            export delimited "$pathData/intermediate/separados.csv", replace
        restore

		preserve
			collapse (sum) aux, by(group_2 cat_aceptan cat_post_comp cat_matricula cat_postula_2022)
            keep if group_2 == 4
            export delimited "$pathData/intermediate/uno_no_asignado.csv", replace
        restore

		tab cat_aceptan if group_2 == 1 & postula_en_bloque == 1
		tab cat_aceptan if group_2 == 1 & postula_en_bloque == 0