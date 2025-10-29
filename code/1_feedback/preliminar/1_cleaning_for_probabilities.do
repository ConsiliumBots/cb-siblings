// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Limpieza para obtener las probabilidades de asignación,  
    // para ver los elementos que mostraremos en la cartilla
	// Created: 2023
	// Last Modified: August 9, 2023
	// Author: Javi Gazmuri

// -----------------------------------------------------------------------------

// ---------------------------------------------- //
// --------------------- DATA ------------------- //
// ---------------------------------------------- //

// ------ 2022: MAIN STAGE ------ //

    import delimited "$pathData/inputs/analysis-2021/SAE_2022/B1_Postulantes_etapa_regular_2022_Admisión_2023_PUBL.csv", clear
    tempfile postulantes
    save `postulantes', replace

    import delimited "$pathData/inputs/analysis-2021/SAE_2022/F1_Relaciones_entre_postulantes_etapa_regular_2022_Admisión_2023_PUBL.csv", clear
    tempfile relaciones
    save `relaciones', replace 

	import delimited "$pathData/inputs/analysis-2021/SAE_2022/C1_Postulaciones_etapa_regular_2022_Admisión_2023_PUBL.csv", clear 
	tempfile postulaciones
	save  `postulaciones', replace

// ---------------------------------------------- //
// --------------------- CLEAN ------------------ //
// ---------------------------------------------- //

    // Supuesto: por simplicidad, nos quedaremos con los postulantes que no repiten un colegio dentro de sus postulaciones

        use  `postulaciones', clear
        bys mrun rbd: gen aux = _N 

        bys mrun: ereplace aux = max(aux)

        gen     flag = 0
        replace flag = 1 if aux > 1

        keep mrun flag
        collapse (firstnm) flag, by(mrun)

        tempfile info_colegios_repetidos
        save `info_colegios_repetidos', replace

    // Supuesto: por simplicidad, nos quedaremos con los hermanos que solo se encuentran en una relación

        // Relaciones

            use `relaciones', clear

            bys mrun_1: gen n_mrun_1 = _N
            bys mrun_2: gen n_mrun_2 = _N

            tab n_mrun_1
            tab n_mrun_2

            preserve
                keep mrun_1 n_mrun_1
                collapse (max) n_mrun_1, by(mrun_1) 
                rename mrun_1 mrun
                tempfile hermanos_1
                save `hermanos_1', replace
            restore

            preserve
                keep mrun_2 n_mrun_2
                collapse (max) n_mrun_2, by(mrun_2) 
                rename mrun_2 mrun
                tempfile hermanos_2
                save `hermanos_2', replace
            restore

            use `postulantes', clear
            merge 1:1 mrun using `info_colegios_repetidos', nogen // all obs _merge == 3

            merge 1:1 mrun using `hermanos_1', nogen
            merge 1:1 mrun using `hermanos_2', nogen

            replace n_mrun_1 = 0 if n_mrun_1 == .
            replace n_mrun_2 = 0 if n_mrun_2 == .

            gen     tiene_hermanos = 0
            replace tiene_hermanos = 1 if n_mrun_1 != 0 | n_mrun_2 != 0

            tab n_mrun_1 n_mrun_2 if tiene_hermanos == 1

        // Si me quedo solo con los 0,1 o 1,0: sería el 80% de los que postulantes que tienen al menos un hermano.

            gen     seleccionado = 0
            replace seleccionado = 1 if n_mrun_1 == 1 & n_mrun_2 == 0 & flag == 0
            replace seleccionado = 1 if n_mrun_1 == 0 & n_mrun_2 == 1 & flag == 0

            keep mrun seleccionado

            preserve
                rename mrun mrun_1
                rename seleccionado seleccionado_1
                tempfile seleccionado_1 
                save `seleccionado_1', replace
            restore

            preserve
                rename mrun mrun_2
                rename seleccionado seleccionado_2
                tempfile seleccionado_2 
                save `seleccionado_2', replace
            restore

            use `relaciones', clear
            merge m:1 mrun_1 using `seleccionado_1', keep(3) nogen
            merge m:1 mrun_2 using `seleccionado_2', keep(3) nogen

            tab seleccionado_1 seleccionado_2 

        // Nos quedamos con las relaciones donde ambos son seleccionados

            keep if seleccionado_1 == 1 & seleccionado_2 == 1 // 60% de las relaciones

            unique mrun_1
            unique mrun_2
            tempfile grupos_postulaciones 
            save `grupos_postulaciones', replace

    // Supuesto: nos quedamos con las relaciones que postulan a algún establecimiento en común

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

            forvalues x = 1/104 {
                rename rbd_1_`x' rbd_2_`x'
            }

            rename (mrun_1 cod_nivel_1)(mrun_2 cod_nivel_2)
            tempfile postulaciones_wide_hno
            save  `postulaciones_wide_hno', replace

        // Merging with relationship data
            use  `relaciones', clear
            merge m:1 mrun_1 using `postulaciones_wide', keep(3) nogen
            merge m:1 mrun_2 using `postulaciones_wide_hno', keep(3) nogen

        // Indicator: number of schools applied in common
            forvalues x = 1/104 {
                gen is_rbd_1_`x' = 0
                forvalues y = 1/104 {
                    replace is_rbd_1_`x' = `y' if rbd_1_`x' == rbd_2_`y' 
                }
                replace is_rbd_1_`x' = . if rbd_1_`x' == .  // is_rbd_1_x == . means sibling 1 has no postulation in the preference x.
                // is_rbd_1_x = 0 means sibling 1 has a postulation in the preference x, but there is no match with sibling 2.
            }

            gen n_escuelas_comun = 0
            forvalues x = 1/104 {
                replace n_escuelas_comun = n_escuelas_comun + (( is_rbd_1_`x' != . ) & ( is_rbd_1_`x' != 0 ))
            }

            keep mrun_1 mrun_2 n_escuelas_comun
            rename mrun_1 mrun
            rename mrun_2 mrun_hermano_final
            tempfile relaciones_postulacion_comun_1
            save `relaciones_postulacion_comun_1', replace

            rename mrun aux
            rename mrun_hermano_final mrun
            rename aux mrun_hermano_final

            tempfile relaciones_postulacion_comun_2
            save `relaciones_postulacion_comun_2', replace

    // Postulantes de interés

        // Ambos seleccionados
            
            use `postulantes', clear
            rename mrun mrun_1
            merge 1:1 mrun_1 using `grupos_postulaciones', gen(_merge_mrun_1)

            rename mrun_2 mrun_hermano
            rename mrun_1 mrun_2
            merge 1:1 mrun_2 using `grupos_postulaciones', gen(_merge_mrun_2) update
            rename mrun_2 mrun 

            keep if _merge_mrun_1 == 3 | _merge_mrun_2 == 4

            gen double  mrun_hermano_final = mrun_hermano   if _merge_mrun_1 == 3
            replace     mrun_hermano_final = mrun_1         if _merge_mrun_2 == 4

            gen     hermano_mayor = 0
            replace hermano_mayor = 1 if _merge_mrun_1 == 3

            drop _merge_* mrun_hermano mrun_1

            keep mrun hermano_mayor prioritario alto_rendimiento mismo_nivel postula_en_bloque mrun_hermano_final

        // Con n_postulaciones_comun > 0

            merge 1:1 mrun mrun_hermano_final using `relaciones_postulacion_comun_1', keep(1 3) nogen
            merge 1:1 mrun mrun_hermano_final using `relaciones_postulacion_comun_2', keep(1 4) nogen update

            drop if n_escuelas_comun == 0

    // Variables de interés

        // Postulaciones

            merge 1:m mrun using `postulaciones', keep(3) nogen
            rename cod_curso codcurso

            gen     criterioprioridad = 1        
            replace criterioprioridad = 6 if criterioprioridad == 1 & prioridad_matriculado == 1
            replace criterioprioridad = 5 if criterioprioridad == 1 & prioridad_hermano == 1
            //      criterioprioridad = 4 es la prioridad hermano dinámica
            replace criterioprioridad = 3 if criterioprioridad == 1 & prioridad_hijo_funcionario == 1
            replace criterioprioridad = 2 if criterioprioridad == 1 & prioridad_exalumno == 1

            keep mrun hermano_mayor rbd codcurso preferencia_postulante criterioprioridad prioritario alto_rendimiento mismo_nivel postula_en_bloque mrun_hermano_final

            // Tipo de postulación

                preserve
                    import delimited "$pathData/intermediate/simulation_probabilities/tipos_data-_oficialEqSAEAnterior_500r_exp0.csv", clear
                    drop criterioprioridad_label tipo_label
                    tempfile tipos 
                    save `tipos', replace
                restore

                merge m:1 criterioprioridad prioritario alto_rendimiento using `tipos', keep(3) nogen

        export delimited "$pathData/intermediate/simulation_probabilities/inputs_for_joint_probabilities.csv", replace

