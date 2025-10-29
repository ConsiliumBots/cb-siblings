// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Cleaning mixpanel data and others
	// Created: March 20, 2024
	// Last Modified: March 20, 2024
	// Author: Javi Gazmuri
// -----------------------------------------------------------------------------

// ---------------------------------------------- //
// ------------------ MIXPANEL ------------------ //
// ---------------------------------------------- //

    // -------------------------------------------------
    // Open feedback
    // -------------------------------------------------

        import delimited "$pathData_feedback_comp/1_inputs/mixpanel/2023-11-22_2023-11-23_fbin_open_feedback.csv", clear
        tempfile open_1 
        save `open_1', replace 

        import delimited "$pathData_feedback_comp/1_inputs/mixpanel/2023-11-23_2023-11-24_fbin_open_feedback.csv", clear
        tempfile open_2 
        save `open_2', replace 
     
        use `open_1', clear 
        append using `open_2'

        keep distinct_id 
        rename distinct_id user
        duplicates drop

        gen apertura_cartilla = 1

        tempfile aperturas_cartilla
        save `aperturas_cartilla', replace 

    // -------------------------------------------------
    // Open fam. app.
    // -------------------------------------------------

        import delimited "$pathData_feedback_comp/1_inputs/mixpanel/2023-11-22_2023-11-23_fbin_postfam_open.csv", clear
        tempfile fam_1 
        save `fam_1', replace 

        import delimited "$pathData_feedback_comp/1_inputs/mixpanel/2023-11-23_2023-11-24_fbin_postfam_open.csv", clear
        tempfile fam_2 
        save `fam_2', replace 

        use `fam_1', clear 
        append using `fam_2'

        keep distinct_id 
        rename distinct_id user
        duplicates drop

        gen apertura_post_fam = 1

        tempfile aperturas_postulacion_fam
        save `aperturas_postulacion_fam', replace 

    // -------------------------------------------------
    // Open video
    // -------------------------------------------------

        import delimited "$pathData_feedback_comp/1_inputs/mixpanel/2023-11-22_2023-11-23_click_feedbackchile_postfam_video.csv", clear 
        tempfile video_1
        save `video_1', replace

        import delimited "$pathData_feedback_comp/1_inputs/mixpanel/2023-11-23_2023-11-24_click_feedbackchile_postfam_video.csv", clear // 0 obs, no one see the intervention the next day

        use `video_1', clear 

        keep distinct_id 
        rename distinct_id user
        duplicates drop

        gen apertura_video = 1

        tempfile aperturas_video
        save `aperturas_video', replace 

    // -------------------------------------------------
    // Open dynamic info
    // -------------------------------------------------

        import delimited "$pathData_feedback_comp/1_inputs/mixpanel/2023-11-22_2023-11-23_fbin_postfam_resultadosseparados.csv", clear 
        tempfile dynamic_1
        save `dynamic_1', replace

        import delimited "$pathData_feedback_comp/1_inputs/mixpanel/2023-11-23_2023-11-24_fbin_postfam_resultadosseparados.csv", clear // 0 obs

        use `dynamic_1', clear 

        keep distinct_id 
        rename distinct_id user
        duplicates drop

        gen apertura_dynamic = 1

        tempfile aperturas_dynamic
        save `aperturas_dynamic', replace 


    // -------------------------------------------------
    // Merge and export
    // -------------------------------------------------

        use `aperturas_cartilla', clear
        merge 1:1 user using `aperturas_video', nogen // no _merge = 2
        merge 1:1 user using `aperturas_postulacion_fam', keep(1 3) nogen // 1 obs _merge = 2
        merge 1:1 user using `aperturas_dynamic', nogen // no _merge = 2

        export delimited "$pathData/intermediate/feedback/2023/mixpanel/aperturas_periodo_complementario.csv", replace

// ---------------------------------------------- //
// ---------------- APPLICATIONS ---------------- //
// ---------------------------------------------- //

    // -------------------------------------------------
    // Schools applied in common
    // -------------------------------------------------

        // End of applications 

            // Creating nº schools applied in common

                import delimited "$main_sae/datos_SAE/1_Source/2_Complementario/postulaciones/datos_jpal_2023-11-25.csv", clear
                keep id_apoderado id_postulante rbd orden
                duplicates drop id_postulante rbd, force

                bys id_postulante: egen preferencia = rank(orden)
                drop orden

                bys id_postulante: gen auxiliar = _N
                sum auxiliar
                local n_pref = `r(max)'
                dis(`n_pref')

                rename rbd rbd_
                reshape wide rbd_,i(id_postulante) j(preferencia)

                preserve
                    foreach x of varlist _all {
                        rename `x' `x'_1
                    }

                    tempfile postulaciones_1
                    save `postulaciones_1', replace
                restore

                foreach x of varlist _all {
                    rename `x' `x'_2
                }

                tempfile postulaciones_2
                save `postulaciones_2', replace

                import delimited "$main_sae/datos_SAE/1_Source/2_Complementario/relaciones/F1_2023-11-25.csv", clear
                merge m:1 id_postulante_1 using `postulaciones_1', keep(3) nogen
                merge m:1 id_postulante_2 using `postulaciones_2', keep(3) nogen

            // Indicator nº schools applied in common

                forvalues x = 1/`n_pref' {
                    gen is_rbd_`x'_1 = 0
                    forvalues y = 1/`n_pref' {
                        replace is_rbd_`x'_1 = `y' if rbd_`x'_1 == rbd_`y'_2
                    }
                    replace is_rbd_`x'_1 = . if rbd_`x'_1 == .  // is_rbd_1_x == . means sibling 1 has no postulation in the preference x.
                    // is_rbd_1_x = 0 means sibling 1 has a postulation in the preference x, but there is no match with sibling 2.
                }

                gen n_escuelas_comun = 0
                forvalues x = 1/`n_pref' {
                    replace n_escuelas_comun = n_escuelas_comun + (( is_rbd_`x'_1 != . ) & ( is_rbd_`x'_1 != 0 ))
                }

            // Id_apoderado

                drop if id_apoderado_1 != id_apoderado_2
                drop id_apoderado_2
                rename id_apoderado_1 id_apoderado

                unique id_apoderado
                bys id_apoderado: gen n_repite = _N
                drop if n_repite > 1

                keep id_apoderado n_escuelas_comun
                rename n_escuelas_comun n_escuelas_comun_post

            // Tempfile

                tempfile datos_post
                save `datos_post', replace 

        // Pre-feedback

            // Creating nº schools applied in common

                import delimited "$main_sae/datos_SAE/1_Source/2_Complementario/postulaciones/datos_jpal_2023-11-21.csv", clear
                keep id_apoderado id_postulante rbd orden
                duplicates drop id_postulante rbd, force

                bys id_postulante: egen preferencia = rank(orden)
                drop orden

                bys id_postulante: gen auxiliar = _N
                sum auxiliar
                local n_pref = `r(max)'
                dis(`n_pref')

                rename rbd rbd_
                reshape wide rbd_,i(id_postulante) j(preferencia)

                preserve
                    foreach x of varlist _all {
                        rename `x' `x'_1
                    }

                    tempfile postulaciones_1
                    save `postulaciones_1', replace
                restore

                foreach x of varlist _all {
                    rename `x' `x'_2
                }

                tempfile postulaciones_2
                save `postulaciones_2', replace


                import delimited "$main_sae/datos_SAE/1_Source/2_Complementario/relaciones/F1_2023-11-21.csv", clear
                merge m:1 id_postulante_1 using `postulaciones_1', keep(3) nogen
                merge m:1 id_postulante_2 using `postulaciones_2', keep(3) nogen

            // Indicator nº schools applied in common

                forvalues x = 1/`n_pref' {
                    gen is_rbd_`x'_1 = 0
                    forvalues y = 1/`n_pref' {
                        replace is_rbd_`x'_1 = `y' if rbd_`x'_1 == rbd_`y'_2
                    }
                    replace is_rbd_`x'_1 = . if rbd_`x'_1 == .  // is_rbd_1_x == . means sibling 1 has no postulation in the preference x.
                    // is_rbd_1_x = 0 means sibling 1 has a postulation in the preference x, but there is no match with sibling 2.
                }

                gen n_escuelas_comun = 0
                forvalues x = 1/`n_pref' {
                    replace n_escuelas_comun = n_escuelas_comun + (( is_rbd_`x'_1 != . ) & ( is_rbd_`x'_1 != 0 ))
                }

            // Id_apoderado

                drop if id_apoderado_1 != id_apoderado_2
                drop id_apoderado_2
                rename id_apoderado_1 id_apoderado

                unique id_apoderado
                bys id_apoderado: gen n_repite = _N
                drop if n_repite > 1

                keep id_apoderado n_escuelas_comun
                rename n_escuelas_comun n_escuelas_comun_previo

        // Merge and export

            merge 1:1 id_apoderado using `datos_post', nogen
            export delimited "$pathData/intermediate/feedback/2023/applications/schools_in_common_comp.csv", replace
