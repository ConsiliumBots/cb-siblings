// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Cálculos que sirven como insumo para los eventos dinámicos
	// Created: 2023
	// Last Modified: August 7, 2023
	// Author: Javi Gazmuri

// -----------------------------------------------------------------------------

// ---------------------------------------------- //
// --------------------- DATA ------------------- //
// ---------------------------------------------- //

// ------------- 2021: MAIN STAGE --------------- //

    import delimited "$pathData/inputs/analysis-2021/SAE_2021/D1_Resultados_etapa_regular_2021_Admisión_2022_PUBL.csv", clear
    tempfile asignaciones
    save  `asignaciones', replace

    import delimited "$pathData/inputs/analysis-2021/SAE_2021/C1_Postulaciones_etapa_regular_2021_Admisión_2022_PUBL.csv", clear 
    tempfile postulaciones
    save  `postulaciones', replace

    import delimited "$pathData/inputs/analysis-2021/SAE_2021/F1_Relaciones_entre_postulantes_etapa_regular_2021_Admisión_2022_PUBL.csv", clear
    duplicates report mrun_1 mrun_2
    gen relacion = _n
    tempfile relaciones
    save  `relaciones', replace  // this data has no duplicate relationships. Eg: if mrun_1 = 1 & mrun_2 = 2, there is no observation with mrun_1 = 2 & mrun_2 = 1

// ------------- 2021: ENROLLMENT --------------- //

    import delimited "$pathData/inputs/analysis-2021/Matrícula 2022/20220908_Matrícula_unica_2022_20220430_WEB.CSV", clear
    keep mrun rbd
    rename rbd rbd_enroll_final_1
    rename mrun mrun_1
    tempfile enrollment_1
    save `enrollment_1', replace

    rename (mrun_1 rbd_enroll_final_1)(mrun_2 rbd_enroll_final_2)
    tempfile enrollment_2
    save `enrollment_2', replace

// ---------------------------------------------- //
// ----------------- DATA CLEAN ----------------- //
// ---------------------------------------------- //

    // 1. Matching assignment with applications

        use `asignaciones', clear
        destring rbd_admitido cod_curso_admitido rbd_admitido_post_resp cod_curso_admitido_post_resp respuesta_postulante_post_lista_, replace
        gen rbd_final = rbd_admitido
        replace rbd_final = rbd_admitido_post_resp if respuesta_postulante == 2 | respuesta_postulante == 6

        gen double cod_curso_final = cod_curso_admitido
        replace cod_curso_final = cod_curso_admitido_post_resp if respuesta_postulante == 2 | respuesta_postulante == 6

        gen respuesta_final = respuesta_postulante_post_lista_
        replace respuesta_final = respuesta_postulante if respuesta_postulante == 1 |  respuesta_postulante == 3  |  respuesta_postulante == 5

        rename (rbd_final cod_curso_final) (rbd cod_curso)
        merge 1:m mrun rbd cod_curso using `postulaciones'
        tab respuesta_final if _merge == 1 // Los _merge == 1 son aquellos no asignados (respuesta_final = 6)
        drop if _merge == 2
        drop _merge
        rename (rbd cod_curso)(rbd_final cod_curso_final)
        keep mrun rbd_final cod_curso_final respuesta_final respuesta_postulante preferencia_postulante rbd_admitido

        tempfile asig_post
        save  `asig_post', replace

    // 2. Matching with relations
            
        use  `relaciones', clear

        rename mrun_1 mrun
        merge m:1 mrun using `asig_post', keep(3) nogen // 0 obs _merge == 1

        foreach x in mrun rbd_final cod_curso_final respuesta_final respuesta_postulante preferencia_postulante rbd_admitido {
            rename `x' `x'_1
        }

        rename mrun_2 mrun
        merge m:1 mrun using `asig_post', keep(3) nogen // 0 obs _merge == 1

        foreach x in mrun rbd_final cod_curso_final respuesta_final respuesta_postulante preferencia_postulante rbd_admitido {
            rename `x' `x'_2
        }

        tempfile relaciones_con_asignaciones
        save `relaciones_con_asignaciones', replace

    // 3. Matching with number of schools applied in common

        // First, we need to eliminate rbd duplicates (and preferences aggregated by continuity) from the students' preferences
            use  `postulaciones', clear

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
            use  `relaciones_con_asignaciones', clear
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

    // 4. Dropping some relations

        drop if n_escuelas_comun == 0

// ---------------------------------------------- //
// ------------------ ANALYSIS ------------------ //
// ---------------------------------------------- //

    // 1. Grupo objetivo 

        // Primer rbd en común: rbd_1_n cuando is_rbd_1_n == 1

            gen primer_rbd_comun = .

            forvalues x = 1/78 {
                replace primer_rbd_comun = rbd_1_`x' 	if is_rbd_1_`x' != 0 & is_rbd_1_`x' != . & primer_rbd_comun == .
            }

        // Relaciones que nos interesan

            gen     relaciones_interesan = 0
            replace relaciones_interesan = 1 if rbd_final_1 == primer_rbd_comun & rbd_final_2 != primer_rbd_comun 
            replace relaciones_interesan = 1 if rbd_final_2 == primer_rbd_comun & rbd_final_1 != primer_rbd_comun 

            tab relaciones_interesan // 7,995 con relaciones_interesan == 1
        
        // Hermano correspondiente acepta la asignación. 

            count if rbd_final_1 == primer_rbd_comun & rbd_final_2 != primer_rbd_comun & respuesta_final_1 == 1
            count if rbd_final_2 == primer_rbd_comun & rbd_final_1 != primer_rbd_comun & respuesta_final_2 == 1
            // 6.281 en total (79%)

            drop relaciones_interesan

            gen     relaciones_interesan = 0
            replace relaciones_interesan = 1 if rbd_final_1 == primer_rbd_comun & rbd_final_2 != primer_rbd_comun & respuesta_final_1 == 1
            replace relaciones_interesan = 1 if rbd_final_2 == primer_rbd_comun & rbd_final_1 != primer_rbd_comun & respuesta_final_2 == 1

    // 2. Cuántas de esas se matriculan en el mismo rbd (primer rbd)

        merge m:1 mrun_1 using `enrollment_1', keep(1 3) nogen
        merge m:1 mrun_2 using `enrollment_2', keep(1 3) nogen
   
        // Ambos
        count if relaciones_interesan == 1 & rbd_enroll_final_1 == rbd_enroll_final_2 & rbd_enroll_final_1 == primer_rbd_comun // 1,298  (20%)
        // Solo el asignado
        count if relaciones_interesan == 1 & rbd_enroll_final_1 != rbd_enroll_final_2 & rbd_enroll_final_1 == primer_rbd_comun // 1,226  (20%)
        //

    // 3. Tasa de asignación años anteriores

        // Nos quedamos con los colegios de interés

            keep if (rbd_final_1 == primer_rbd_comun & rbd_final_2 != primer_rbd_comun) | (rbd_final_2 == primer_rbd_comun & rbd_final_1 != primer_rbd_comun)
            keep primer_rbd_comun

            gen aux = 1
            collapse(firstnm) aux, by(primer_rbd_comun)
            drop aux
            rename primer_rbd_comun rbd

            tempfile colegios_interes
            save `colegios_interes', replace

        // Datos años anteriores

            import delimited "$pathData/inputs/analysis-2021/SAE_2021/D1_Resultados_etapa_regular_2021_Admisión_2022_PUBL.csv", clear
            destring rbd_admitido cod_curso_admitido rbd_admitido_post_resp cod_curso_admitido_post_resp respuesta_postulante_post_lista_, replace
            gen rbd_final = rbd_admitido
            replace rbd_final = rbd_admitido_post_resp if respuesta_postulante == 2 | respuesta_postulante == 6

            gen double cod_curso_final = cod_curso_admitido
            replace cod_curso_final = cod_curso_admitido_post_resp if respuesta_postulante == 2 | respuesta_postulante == 6

            keep mrun rbd_final cod_curso_final
            rename (rbd_final cod_curso_final) (rbd cod_curso)
            tempfile asignaciones 
            save `asignaciones', replace

            import delimited "$pathData/inputs/analysis-2021/SAE_2021/C1_Postulaciones_etapa_regular_2021_Admisión_2022_PUBL.csv", clear 
            keep if preferencia_postulante == 1 & prioridad_hermano == 1
    
            merge m:1 mrun rbd cod_curso using `asignaciones', keep(1 3)

            gen     asignado = 0 
            replace asignado = 100 if _merge == 3

            collapse (mean) asignado, by(rbd)
            merge 1:1 rbd using `colegios_interes', keep(3)

            histogram asignado, frac title("SAE 2021") xtitle("Tasa asignación") ytitle("Fracción")
