// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Create a unique database for the rest of the analysis
	// Created: March 20, 2024
	// Last Modified: March 20, 2024
	// Author: Javi Gazmuri
// -----------------------------------------------------------------------------

// ---------------------------------------------- //
// --------------------- DATA ------------------- //
// ---------------------------------------------- //

    // Openings - Mixpanel

        import delimited "$pathData/intermediate/feedback/2023/mixpanel/aperturas_periodo_complementario.csv", clear
        tempfile aperturas
        save `aperturas', replace 

    // Relaciones posterior al envío de cartilla

        import delimited "$main_sae/datos_SAE/1_Source/2_Complementario/relaciones/F1_2023-11-25.csv", clear
        keep id_postulante_1 id_postulante_2 postula_en_bloque
        rename postula_en_bloque postulacion_familiar_post
        * Hay que pegarle el id_apoderado

        preserve
            import delimited "$main_sae/datos_SAE/1_Source/2_Complementario/postulaciones/datos_jpal_2023-11-25.csv", clear
            keep id_postulante id_apoderado
            collapse (firstnm) id_apoderado, by(id_postulante)

            rename (id_postulante id_apoderado) (id_postulante_1 id_apoderado_1)
            tempfile postulantes_final_1
            save `postulantes_final_1', replace

            rename (id_postulante_1 id_apoderado_1) (id_postulante_2 id_apoderado_2)
            tempfile postulantes_final_2
            save `postulantes_final_2', replace
        restore

        merge m:1 id_postulante_1 using `postulantes_final_1', keep(3) nogen
        merge m:1 id_postulante_2 using `postulantes_final_2', keep(3) nogen

        keep if id_apoderado_1 == id_apoderado_2
        drop id_apoderado_2
        rename id_apoderado_1 id_apoderado

        gen n_relaciones_apoderado = 1
        collapse (sum) n_relaciones_apoderado postulacion_familiar_post (firstnm) id_postulante_1 id_postulante_2, by(id_apoderado)

        tempfile apoderados_post
        save `apoderados_post', replace

    // Cartilla 

        import delimited "$pathData_feedback_comp/3_outputs/2_tablas_auxiliares/modulo_hermanos/reports_family_simulation_2023-11-21.csv", clear 
        tempfile cartilla
        save `cartilla', replace

        // Pegamos id estudiantes

            import delimited "$pathData_feedback_comp/4_research_tables/siblings/tabla_auxiliar_eventos.csv", clear
            collapse (firstnm) id_menor id_hermano, by(id_apoderado)

            merge 1:1 id_apoderado using `cartilla', keep(3) nogen
            tempfile cartilla
            save `cartilla', replace

    // Crosswalk id-postulante mrun 

        import delimited "$main_sae/datos_SAE/1_Source/Crosswalk_mrun/20240509postulantes_SAE_2022_2023.csv", clear
        keep if año_proceso == 2023
        drop año_proceso
        rename * *_1
        tempfile crosswalk_1
        save `crosswalk_1', replace

        rename *_1 *_2
        tempfile crosswalk_2
        save `crosswalk_2', replace

    // Nº schools applied in common

        import delimited "$pathData/intermediate/feedback/2023/applications/schools_in_common_comp.csv", clear
        tempfile schools_in_common
        save `schools_in_common', replace


// ---------------------------------------------- //
// --------------------- MERGE ------------------ //
// ---------------------------------------------- //

    use `cartilla', clear
    *keep user id_apoderado id_menor id_hermano postulacion_familiar tiene_dinamico tiene_segundo_evento tiene_tercer_evento e1_prob_familiar e1_prob_independiente e2_prob_familiar e2_prob_independiente e3_prob_familiar e3_prob_independiente e4_prob_familiar e4_prob_independiente e2_explicacion
    rename postulacion_familiar postulacion_familiar_21

    label def post_fam 0 "Individual (21 nov)" 1 "Familiar (21 nov)"
    label values postulacion_familiar_21 post_fam

    // Aperturas

        merge 1:1 user using `aperturas', keep(1 3) nogen

        replace apertura_cartilla = 0   if apertura_cartilla == .
        replace apertura_video = 0      if apertura_video == .
        replace apertura_post_fam = 0   if apertura_post_fam == .
        replace apertura_dynamic = 0   if apertura_dynamic == .

    // Relaciones

        merge 1:1 id_apoderado using `apoderados_post', keep(1 3) nogen // pocos en _merge == 1
        tab n_relaciones_apoderado // pocos tienen más de una relación

        gen     relaciones_mantienen = 0
        replace relaciones_mantienen = 1 if n_relaciones_apoderado == 1 & id_menor == id_postulante_2 & id_hermano == id_postulante_1

        keep if relaciones_mantienen == 1
        drop id_menor id_hermano

    // Colegios postulados en común 

        merge 1:1 id_apoderado using `schools_in_common', keep(1 3) nogen

    // Crosswalk 

        merge 1:1 id_postulante_1 using `crosswalk_1', keep(1 3) nogen // 0 obs in _merge == 1
        merge 1:1 id_postulante_2 using `crosswalk_2', keep(1 3) nogen // 0 obs in _merge == 1. 

    // Export 

        export delimited "$pathData/intermediate/feedback/2023/clean_data/consolidated_data_comp.csv", replace
