// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Cleaning mixpanel data and others
	// Created: Feb 1, 2024
	// Last Modified: Feb 2, 2024
	// Author: Javi Gazmuri
// -----------------------------------------------------------------------------

// ---------------------------------------------- //
// ------------------ MIXPANEL ------------------ //
// ---------------------------------------------- //

    // -------------------------------------------------
    // Open feedback
    // -------------------------------------------------

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-08-30_2023-08-31_fbin_open_feedback.csv", clear
        tempfile open_1 
        save `open_1', replace 

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-08-31_2023-09-01_fbin_open_feedback.csv", clear
        tempfile open_2 
        save `open_2', replace 
     
        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-09-01_2023-09-02_fbin_open_feedback.csv", clear
        tempfile open_3 
        save `open_3', replace 

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-09-02_2023-09-03_fbin_open_feedback.csv", clear
        tempfile open_4 
        save `open_4', replace 

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-09-03_2023-09-04_fbin_open_feedback.csv", clear
        tempfile open_5 
        save `open_5', replace 

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-09-04_2023-09-05_fbin_open_feedback.csv", clear
        tempfile open_6 
        save `open_6', replace 

        use `open_1', clear 
        append using `open_2' `open_3' `open_4' `open_5' `open_6'

        keep time distinct_id 
        rename distinct_id user

        gen time_2 = time * 1000 + mdyhms(1,1,1970,0,0,0)
        format time_2 %tc
        sort time_2 

        generate aux = string(time_2,"%tc")
        split aux, gen(aux_)

        gen dia = substr(aux_1,1,2)
        gen hora = substr(aux_2,1,2)
        gen minuto = substr(aux_2,4,2)

        destring dia hora minuto, replace

        * Hora envío: 30 agosto, 19:20.
        drop if dia == 30 & hora < 19
        drop if dia == 30 & hora == 19 & minuto < 20

        collapse (min) time_2, by(user)

        // Checking time variable

            preserve 
                gen auxiliar = 1
                collapse (count) auxiliar, by(time_2)

                generate aux = string(time_2,"%tc")
                split aux, gen(aux_)

                gen dia = substr(aux_1,1,2)
                gen hora = substr(aux_2,1,2)
                gen minuto = substr(aux_2,4,2)

                destring dia hora minuto, replace

                graph twoway line auxiliar hora if dia == 30 // Peak calza con mixpanel
            restore
 
        keep user
        gen apertura_cartilla = 1

        tempfile aperturas_cartilla
        save `aperturas_cartilla', replace 

    // -------------------------------------------------
    // Open fam. app.
    // -------------------------------------------------

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-08-30_2023-08-31_click_feedbackchile_postfam_open.csv", clear
        tempfile fam_1 
        save `fam_1', replace 

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-08-31_2023-09-01_click_feedbackchile_postfam_open.csv", clear
        tempfile fam_2 
        save `fam_2', replace 

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-09-01_2023-09-02_click_feedbackchile_postfam_open.csv", clear
        tempfile fam_3
        save `fam_3', replace 

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-09-02_2023-09-03_click_feedbackchile_postfam_open.csv", clear
        tempfile fam_4 
        save `fam_4', replace 

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-09-03_2023-09-04_click_feedbackchile_postfam_open.csv", clear
        tempfile fam_5 
        save `fam_5', replace 

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-09-04_2023-09-05_click_feedbackchile_postfam_open.csv", clear
        tempfile fam_6 
        save `fam_6', replace 

        use `fam_1', clear 
        append using `fam_2' `fam_3' `fam_4' `fam_5' `fam_6', force 

        keep time distinct_id 
        rename distinct_id user

        gen time_2 = time * 1000 + mdyhms(1,1,1970,0,0,0)
        format time_2 %tc
        sort time_2 

        generate aux = string(time_2,"%tc")
        split aux, gen(aux_)

        gen dia = substr(aux_1,1,2)
        gen hora = substr(aux_2,1,2)
        gen minuto = substr(aux_2,4,2)

        destring dia hora minuto, replace

        * Hora envío: 30 agosto, 19:20.
        drop if dia == 30 & hora < 19
        drop if dia == 30 & hora == 19 & minuto < 20

        collapse (min) time_2, by(user)
 
        keep user
        gen apertura_post_fam = 1

        tempfile aperturas_postulacion_fam
        save `aperturas_postulacion_fam', replace 

    // -------------------------------------------------
    // Open video
    // -------------------------------------------------

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-08-30_2023-08-31_click_feedbackchile_postfam_video.csv", clear
        tempfile video_1
        save `video_1', replace

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-08-31_2023-09-01_click_feedbackchile_postfam_video.csv", clear
        tempfile video_2
        save `video_2', replace

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-09-01_2023-09-02_click_feedbackchile_postfam_video.csv", clear
        tempfile video_3
        save `video_3', replace

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-09-02_2023-09-03_click_feedbackchile_postfam_video.csv", clear
        tempfile video_4
        save `video_4', replace

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-09-03_2023-09-04_click_feedbackchile_postfam_video.csv", clear
        tempfile video_5
        save `video_5', replace

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-09-04_2023-09-05_click_feedbackchile_postfam_video.csv", clear
        tempfile video_6
        save `video_6', replace

        use `video_1', clear 
        append using `video_2' `video_3' `video_4' `video_5' `video_6'

        keep time distinct_id 
        rename distinct_id user

        gen time_2 = time * 1000 + mdyhms(1,1,1970,0,0,0)
        format time_2 %tc
        sort time_2 

        generate aux = string(time_2,"%tc")
        split aux, gen(aux_)

        gen dia = substr(aux_1,1,2)
        gen hora = substr(aux_2,1,2)
        gen minuto = substr(aux_2,4,2)

        destring dia hora minuto, replace

        * Hora envío: 30 agosto, 19:20.
        drop if dia == 30 & hora < 19
        drop if dia == 30 & hora == 19 & minuto < 20

        collapse (min) time_2, by(user)
 
        keep user
        gen apertura_video = 1

        tempfile aperturas_video
        save `aperturas_video', replace 

    // -------------------------------------------------
    // Open dynamic info
    // -------------------------------------------------

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-08-30_2023-08-31_click_feedbackchile_postfam_resultadosseparados.csv", clear
        tempfile dynamic_1 
        save `dynamic_1', replace 

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-08-31_2023-09-01_click_feedbackchile_postfam_resultadosseparados.csv", clear
        tempfile dynamic_2 
        save `dynamic_2', replace 

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-09-01_2023-09-02_click_feedbackchile_postfam_resultadosseparados.csv", clear
        tempfile dynamic_3 
        save `dynamic_3', replace 

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-09-02_2023-09-03_click_feedbackchile_postfam_resultadosseparados.csv", clear
        tempfile dynamic_4 
        save `dynamic_4', replace 

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-09-03_2023-09-04_click_feedbackchile_postfam_resultadosseparados.csv", clear
        tempfile dynamic_5 
        save `dynamic_5', replace 

        import delimited "$pathData_feedback_reg/1_inputs/mixpanel/by_event/2023-09-04_2023-09-05_click_feedbackchile_postfam_resultadosseparados.csv", clear
        tempfile dynamic_6 
        save `dynamic_6', replace 

        use `dynamic_1', clear 
        append using `dynamic_2' `dynamic_3' `dynamic_4' `dynamic_5' `dynamic_6', force

        keep time distinct_id 
        rename distinct_id user

        gen time_2 = time * 1000 + mdyhms(1,1,1970,0,0,0)
        format time_2 %tc
        sort time_2 

        generate aux = string(time_2,"%tc")
        split aux, gen(aux_)

        gen dia = substr(aux_1,1,2)
        gen hora = substr(aux_2,1,2)
        gen minuto = substr(aux_2,4,2)

        destring dia hora minuto, replace

        * Hora envío: 30 agosto, 19:20.
        drop if dia == 30 & hora < 19
        drop if dia == 30 & hora == 19 & minuto < 20

        collapse (min) time_2, by(user)
 
        keep user
        gen apertura_dynamic = 1

        tempfile aperturas_bloque_dinamico
        save `aperturas_bloque_dinamico', replace 

    // -------------------------------------------------
    // Merge and export
    // -------------------------------------------------

        use `aperturas_cartilla', clear
        merge 1:1 user using `aperturas_video', nogen // no _merge = 2
        merge 1:1 user using `aperturas_bloque_dinamico', nogen // no _merge = 2
        merge 1:1 user using `aperturas_postulacion_fam', keep(1 3) nogen // 22 obs _merge = 2

        export delimited "$pathData/intermediate/feedback/2023/mixpanel/aperturas_periodo_regular.csv", replace

// ---------------------------------------------- //
// ---------------- APPLICATIONS ---------------- //
// ---------------------------------------------- //

    // -------------------------------------------------
    // Schools applied in common
    // -------------------------------------------------

        // End of applications 

            // Creating nº schools applied in common

                import delimited "$main_sae/datos_SAE/1_Source/1_Principal/postulaciones/datos_jpal_2023-09-20.csv", clear
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


                import delimited "$main_sae/datos_SAE/1_Source/1_Principal/relaciones/F1_2023-09-20.csv", clear
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

                import delimited "$main_sae/datos_SAE/1_Source/1_Principal/postulaciones/datos_jpal_2023-08-28.csv", clear
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


                import delimited "$main_sae/datos_SAE/1_Source/1_Principal/relaciones/F1_2023-08-28.csv", clear
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
            export delimited "$pathData/intermediate/feedback/2023/applications/schools_in_common_reg.csv", replace
