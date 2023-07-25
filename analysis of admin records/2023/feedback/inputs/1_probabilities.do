// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Datos para ver los elementos que mostraremos en la cartilla
	// Created: 2023
	// Last Modified: July 18, 2023
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
/*
    import delimited "$pathData/inputs/analysis-2021/Matrícula 2022/20220908_Matrícula_unica_2022_20220430_WEB.CSV", clear
    keep mrun rbd
    rename rbd rbd_enroll_final_1
    rename mrun mrun_1
    tempfile enrollment_1
    save `enrollment_1', replace

    rename (mrun_1 rbd_enroll_final_1)(mrun_2 rbd_enroll_final_2)
    tempfile enrollment_2
    save `enrollment_2', replace
*/
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
// --------------------- CLEAN ------------------ //
// ---------------------------------------------- //

	// First, we need to eliminate rbd duplicates (and preferences aggregated by continuity) from the students' preferences

		use  `postulaciones_reg', clear

		bys mrun: egen tiene_mat_aseg = max(prioridad_matriculado)

		gen 	rbd_matriculado = 0
		replace rbd_matriculado = rbd if prioridad_matriculado == 1
		bys mrun: ereplace rbd_matriculado = max(rbd_matriculado)

        gen indicador_postula_actual = 0
        replace indicador_postula_actual = 1 if rbd_matriculado == rbd & agregada_por_continuidad == 0

        bys mrun: egen postula_mat_asegurada = max(indicador_postula_actual)

		drop if agregada_por_continuidad == 1

		keep mrun rbd preferencia_postulante cod_nivel tiene_mat_aseg rbd_matriculado postula_mat_asegurada

		collapse (min) preferencia_postulante cod_nivel (max) tiene_mat_aseg rbd_matriculado postula_mat_asegurada, by(mrun rbd)
		bys mrun: egen order = rank(preferencia_postulante)

		unique mrun order // unique obs
		drop preferencia_postulante
		rename order preferencia_postulante

        tempfile preferencias_ordenadas
        save `preferencias_ordenadas', replace
        
		rename rbd rbd_1_

	// Then, we need the wide form of preferences

		reshape wide rbd_1_ , i(mrun) j(preferencia_postulante)
		rename (mrun cod_nivel tiene_mat_aseg rbd_matriculado postula_mat_asegurada) (mrun_1 cod_nivel_1 tiene_mat_aseg_1 rbd_matriculado_1 postula_mat_asegurada_1)

		tempfile postulaciones_wide
		save  `postulaciones_wide', replace

		forvalues x = 1/78 {
			rename rbd_1_`x' rbd_2_`x'
		}

		rename (mrun_1 cod_nivel_1 tiene_mat_aseg_1 rbd_matriculado_1 postula_mat_asegurada_1)(mrun_2 cod_nivel_2 tiene_mat_aseg_2 rbd_matriculado_2 postula_mat_asegurada_2)
		tempfile postulaciones_wide_hno
		save  `postulaciones_wide_hno', replace

	// Merging with relationship data

		use  `relaciones_reg', clear
		merge m:1 mrun_1 using `postulaciones_wide', keep(3) nogen
		merge m:1 mrun_2 using `postulaciones_wide_hno', keep(3) nogen

		forvalues x = 1/78 {
			gen is_rbd_1_`x' = 0
			forvalues y = 1/78 {
				replace is_rbd_1_`x' = `y' if rbd_1_`x' == rbd_2_`y' 
			}
			replace is_rbd_1_`x' = . if rbd_1_`x' == .  // is_rbd_1_x == . means sibling 1 has no postulation in the preference x.
			// is_rbd_1_x = 0 means sibling 1 has a postulation in the preference x, but there is no match with sibling 2.
		}

        tempfile relaciones_final
        save `relaciones_final', replace

    // Merging with assignment 

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
        keep mrun rbd_final preferencia_postulante

        rename (mrun rbd_final preferencia_postulante)(mrun_1 rbd_final_1 pref_asig_1)
        tempfile asig_reg_1
        save `asig_reg_1', replace

        rename (mrun_1 rbd_final_1 pref_asig_1)(mrun_2 rbd_final_2 pref_asig_2)
        tempfile asig_reg_2
        save `asig_reg_2', replace

        use `relaciones_final', clear        
        merge m:1 mrun_1 using `asig_reg_1', keep(3) nogen
        merge m:1 mrun_2 using `asig_reg_2', keep(3) nogen

	// Nº schools applied in common

		gen n_escuelas_comun = 0
		gen n_postulaciones_mayor = 0
		gen n_postulaciones_menor = 0
		forvalues x = 1/78 {
			replace n_escuelas_comun = n_escuelas_comun + (( is_rbd_1_`x' != . ) & ( is_rbd_1_`x' != 0 ))
			replace n_postulaciones_mayor = n_postulaciones_mayor + ( rbd_1_`x' != . )
			replace n_postulaciones_menor = n_postulaciones_menor + ( rbd_2_`x' != . )
		}

	// Drop excluded relationships

		drop if n_escuelas_comun == 0
		drop if mismo_nivel == 1

// ---------------------------------------------- //
// ------------------ ANALYSIS ------------------ //
// ---------------------------------------------- //

    // 1. Distribución nº rbds postulados en común

        histogram n_escuelas_comun, d xtitle("Número de establecimientos postulados en común") xlabel(1 2 3 4 5 6 7 8 9 10)

    // 2. Nº de relaciones asignadas

        // Hermano mayor (pref = 1)

        * Arreglar: variable pref_asig para que refleje la primera vez que aparece el colegio.



            gen aux_1 = 0
            gen aux_2 = 0
            gen aux_3 = 0
            gen aux_4 = 0
            gen aux_5 = 0
            gen aux_6 = 0
            
            replace aux_1 = 1 if rbd_1_1 == rbd_final_1 & rbd_final_2 == rbd_2_1 & rbd_final_1 != . & rbd_final_2 != .
            replace aux_2 = 1 if rbd_1_1 == rbd_final_1 & rbd_final_2 == rbd_2_2 & rbd_final_1 != . & rbd_final_2 != .
            replace aux_3 = 1 if rbd_1_1 == rbd_final_1 & rbd_final_2 == rbd_2_3 & rbd_final_1 != . & rbd_final_2 != .

            replace aux_4 = 1 if rbd_1_1 == rbd_final_1 & rbd_final_2 == rbd_matriculado_2 & rbd_final_1 != . & rbd_final_2 != . & postula_mat_asegurada_2 == 0
            replace aux_5 = 1 if rbd_1_1 == rbd_final_1 & rbd_final_2 == . & rbd_final_1 != .

            replace aux_6 = 1 if rbd_1_1 == rbd_final_1 & pref_asig_2 >= 4 & rbd_final_1 != . & rbd_final_2 != .

            count if rbd_1_1 == rbd_final_1 & rbd_final_1 != .



            count if rbd_1_1 == rbd_final_1 & rbd_final_2 == rbd_2_1 & rbd_final_1 != . & rbd_final_2 != .
            count if rbd_1_1 == rbd_final_1 & rbd_final_2 == rbd_2_2 & rbd_final_1 != . & rbd_final_2 != .
            count if rbd_1_1 == rbd_final_1 & rbd_final_2 == rbd_2_3 & rbd_final_1 != . & rbd_final_2 != .

            count if rbd_1_1 == rbd_final_1 & rbd_final_2 == rbd_matriculado_2 & rbd_final_1 != . & rbd_final_2 != . & postula_mat_asegurada_2 == 0
            count if rbd_1_1 == rbd_final_1 & rbd_final_2 == . & rbd_final_1 != .

            count if rbd_1_1 == rbd_final_1 & rbd_final_1 != .



            count if rbd_1_2 == rbd_final_1 & rbd_final_2 == rbd_2_1 & rbd_final_1 != . & rbd_final_2 != .
            count if rbd_1_2 == rbd_final_1 & rbd_final_2 == rbd_2_2 & rbd_final_1 != . & rbd_final_2 != .
            count if rbd_1_2 == rbd_final_1 & rbd_final_2 == rbd_2_3 & rbd_final_1 != . & rbd_final_2 != .

            count if rbd_1_2 == rbd_final_1 & rbd_final_2 == rbd_matriculado_2 & rbd_final_1 != . & rbd_final_2 != . & postula_mat_asegurada_2 == 0
            count if rbd_1_2 == rbd_final_1 & rbd_final_2 == . & rbd_final_1 != .

            count if rbd_1_2 == rbd_final_1 & rbd_final_1 != .




            count if rbd_1_3 == rbd_final_1 & rbd_final_2 == rbd_2_1 & rbd_final_1 != . & rbd_final_2 != .
            count if rbd_1_3 == rbd_final_1 & rbd_final_2 == rbd_2_2 & rbd_final_1 != . & rbd_final_2 != .
            count if rbd_1_3 == rbd_final_1 & rbd_final_2 == rbd_2_3 & rbd_final_1 != . & rbd_final_2 != .

            count if rbd_1_3 == rbd_final_1 & rbd_final_2 == rbd_matriculado_2 & rbd_final_1 != . & rbd_final_2 != . & postula_mat_asegurada_2 == 0
            count if rbd_1_3 == rbd_final_1 & rbd_final_2 == . & rbd_final_1 != .

            count if rbd_1_3 == rbd_final_1 & rbd_final_1 != .


            count if pref_asig_1 >= 4 & rbd_1_4 != . & rbd_final_2 == rbd_2_1 & rbd_final_1 != . & rbd_final_2 != .
            count if pref_asig_1 >= 4 & rbd_1_4 != . & rbd_final_2 == rbd_2_2 & rbd_final_1 != . & rbd_final_2 != .
            count if pref_asig_1 >= 4 & rbd_1_4 != . & rbd_final_2 == rbd_2_3 & rbd_final_1 != . & rbd_final_2 != .

            count if pref_asig_1 >= 4 & rbd_1_4 != . & rbd_final_2 == rbd_matriculado_2 & rbd_final_1 != . & rbd_final_2 != . & postula_mat_asegurada_2 == 0
            count if pref_asig_1 >= 4 & rbd_1_4 != . & rbd_final_2 == . & rbd_final_1 != .

            count if pref_asig_1 >= 4 & rbd_1_4 != . & rbd_final_1 != .



            count if rbd_final_1 == . & rbd_final_2 == rbd_2_1 & rbd_final_2 != .
            count if rbd_final_1 == . & rbd_final_2 == rbd_2_2 & rbd_final_2 != .
            count if rbd_final_1 == . & rbd_final_2 == rbd_2_3 & rbd_final_2 != .

            count if rbd_final_1 == . & rbd_final_2 == rbd_matriculado_2 & rbd_final_2 != . & postula_mat_asegurada_2 == 0
            count if rbd_final_1 == . & rbd_final_2 == .

            count if rbd_final_1 == .


            count if rbd_final_1 == rbd_matriculado_1 & rbd_final_2 == rbd_2_1 & rbd_final_1 != . & postula_mat_asegurada_1 == 0 & rbd_final_2 != .
            count if rbd_final_1 == rbd_matriculado_1 & rbd_final_2 == rbd_2_2 & rbd_final_1 != . & postula_mat_asegurada_1 == 0 & rbd_final_2 != .
            count if rbd_final_1 == rbd_matriculado_1 & rbd_final_2 == rbd_2_3 & rbd_final_1 != . & postula_mat_asegurada_1 == 0 & rbd_final_2 != .

            count if rbd_final_1 == rbd_matriculado_1 & rbd_final_2 == rbd_matriculado_2 & rbd_final_1 != . & rbd_final_2 != . & postula_mat_asegurada_1 == 0 & postula_mat_asegurada_2 == 0
            count if rbd_final_1 == rbd_matriculado_1 & rbd_final_1 != . & postula_mat_asegurada_1 == 0 & rbd_final_2 == .

            count if rbd_final_1 == rbd_matriculado_1 & rbd_final_1 != . & postula_mat_asegurada_1 == 0