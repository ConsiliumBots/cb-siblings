// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Stats for implementation report: results - Yale deliverable
	// Created: May 9, 2024
	// Last Modified: May 9, 2024
	// Author: Javi Gazmuri
// -----------------------------------------------------------------------------

    // -------------------------------------------------
    // Effectiveness of the intervention
    // -------------------------------------------------

        import delimited "$pathData/intermediate/feedback/2023/clean_data/consolidated_data_reg.csv", clear
        gen abrio_cartilla = apertura_post_fam * 100

        // Knowledge of the system

            gen aux = 1
            graph bar (sum) aux, over(sibl03_a, relabel (1 "Change pref. youngest" 2 "Change pref. oldest" 3 "Automatically assigned" 4 "Sibling priority (static)" 5 "Sibling priority (dynamic)" 6 "Not sure")) over(abrio_cartilla, relabel(1 "Opened" 2 "Not opened")) asyvars percentages ytitle("Percentage") blabel(bar, format(%6.0f)) bar(1, color(blue%100)) bar(2, color(blue%70)) bar(3, color(purple%100)) bar(4, color(purple%70)) bar(5, color(red%70)) bar(6, color(red%100))

        // Change in fam. app.

            preserve
                import delimited "$main_sae/cartillas/cartillas_postulación/1_etapa_regular/4_research_tables/siblings/tabla_auxiliar_eventos.csv", clear

                gen     evento_juntos = 0 
                replace evento_juntos = 1 if n_evento < 5 & rbd_menor == rbd_mayor 
                replace evento_juntos = 1 if n_evento == 5

                gen     evento_ma = regexm(evento,"mat_aseg")

                keep if evento_juntos == 1 & evento_ma == 0

                rename (prob_conjunta_bloque prob_conjunta_sinbloque) (prob_juntos_fam_cartilla prob_juntos_ind_cartilla)

                collapse (sum) prob_juntos_fam_cartilla prob_juntos_ind_cartilla (firstnm) postula_en_bloque, by(id_apoderado)
                tempfile probabilidades_cartilla
                save `probabilidades_cartilla', replace
            restore 

            merge 1:1 id_apoderado using `probabilidades_cartilla', keep(3) nogen // a few where _merge = 2, 0 _merge = 1

            replace prob_juntos_fam_cartilla = prob_juntos_fam_cartilla * 100
            replace prob_juntos_ind_cartilla = prob_juntos_ind_cartilla * 100

            gen     should = 0
            replace should = 1 if postulacion_familiar_28 == "Familiar (28 ago)" & prob_juntos_fam_cartilla < prob_juntos_ind_cartilla
            replace should = 1 if postulacion_familiar_28 == "Individual (28 ago)" & prob_juntos_fam_cartilla > prob_juntos_ind_cartilla
            replace should = 2 if prob_juntos_fam_cartilla == prob_juntos_ind_cartilla

            label def should_what 0 "Should maintain" 1 "Should change" 2 "Indifferent"
            label values should should_what

            gen     change = 0
            replace change = 100 if postulacion_familiar_28 == "Individual (28 ago)" & postulacion_familiar_post == 1
            replace change = 100 if postulacion_familiar_28 == "Familiar (28 ago)" & postulacion_familiar_post == 0

            gen     change_open = change if apertura_post_fam == 1
            gen     change_not_open = change if apertura_post_fam == 0

            replace postulacion_familiar_28 = "Individual (pre-intervention)" if postulacion_familiar_28 == "Individual (28 ago)"
            replace postulacion_familiar_28 = "Linking (pre-intervention)" if postulacion_familiar_28 == "Familiar (28 ago)"

            encode sibl06_menos, gen(sibl06_encode)
            gen strong_for_joint = sibl06_encode == 2 if sibl06_encode != .

            graph bar change_open change_not_open if strong_for_joint == 1, over(should) over(postulacion_familiar_28) bar(1, color(blue%50)) bar(2, color(red%50)) ytitle("Percentage") blabel(bar, format(%6.1f)) ///
            legend(label(1 "Opened") label(2 "Not opened")) nofill

        // Beliefs

            gen     prob_juntos_ind_enc = sibl14_1 if opcion_seleccionada == "postulación individual"
            replace prob_juntos_ind_enc = sibl15_1 if opcion_seleccionada == "postulación familiar"

            gen     prob_juntos_fam_enc = sibl14_1 if opcion_seleccionada == "postulación familiar"
            replace prob_juntos_fam_enc = sibl15_1 if opcion_seleccionada == "postulación individual"

            gen     prob_juntos_fam_enc_pre = sibl17_1 

            gen bias_before = prob_juntos_fam_enc_pre - prob_juntos_fam_cartilla
            gen bias_after = prob_juntos_fam_enc - prob_juntos_fam_cartilla

            preserve
                keep if apertura_post_fam == 1
                drop if bias_before == . | bias_after == .
                reshape long bias_ , i(id_apoderado) j(time) string
                rename bias_ bias

                replace time = "Pre-feedback" if time == "after"
                replace time = "Post-feedback" if time == "before"

                tab bias if strong_for_joint == 1 & change == 100

                graph hbox bias if strong_for_joint == 1 & change == 100, over(time) box(1, color(red)) ytitle("Bias") 
            restore

        // Change in nº schools applied

            gen aumenta_common = 100 * (n_escuelas_comun_previo < n_escuelas_comun_post) if n_escuelas_comun_previo != . & n_escuelas_comun_post != .

            graph bar aumenta_common if strong_for_joint == 1, over(abrio_cartilla, relabel(1 "No abrió" 2 "Abrió")) bar(1, color(red%50)) ytitle("Porcentaje") title("Porcentaje de relaciones que aumentan los colegios postulados en común")
            