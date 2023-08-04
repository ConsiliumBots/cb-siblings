// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Limpieza para obtener las probabilidades de asignación,  
    // para ver los elementos que mostraremos en la cartilla
	// Created: 2023
	// Last Modified: August 3, 2023
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

        // Postulantes de interés

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

    // Variables de interés

        keep mrun hermano_mayor prioritario alto_rendimiento mismo_nivel postula_en_bloque mrun_hermano_final
        tempfile postulantes_final 
        save `postulantes_final', replace

    // Postulaciones

        use `postulaciones', clear 
        merge m:1 mrun using `postulantes_final', keep(3) nogen
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

