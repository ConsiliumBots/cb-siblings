// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Analyzing effects of feedback on beliefs on allocation probs.
	// Created: April 24, 2024
	// Last Modified: April 24, 2024
	// Author: Javi Gazmuri
// -----------------------------------------------------------------------------

// -------------------------------------------------------------------------
//  Prob. de ser asignados juntos (sin considerar su establecimiento actual)
// -------------------------------------------------------------------------

    import delimited "$pathData/intermediate/feedback/2023/clean_data/consolidated_data_reg.csv", clear

    // Probabilidades reales (mostradas en la cartilla)

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

    // Probabilidades encuesta

        gen     prob_juntos_ind_enc = sibl14_1 if opcion_seleccionada == "postulación individual"
        replace prob_juntos_ind_enc = sibl15_1 if opcion_seleccionada == "postulación familiar"

        gen     prob_juntos_fam_enc = sibl14_1 if opcion_seleccionada == "postulación familiar"
        replace prob_juntos_fam_enc = sibl15_1 if opcion_seleccionada == "postulación individual"

        gen     prob_juntos_fam_enc_pre = sibl17_1 

    // Graphs

        // Scatter 

            twoway (scatter prob_juntos_fam_cartilla prob_juntos_fam_enc, msize(vtiny) mcolor(red%50)) (scatter prob_juntos_ind_cartilla prob_juntos_ind_enc, msize(vtiny) mcolor(blue%50)) ///
            (lfit prob_juntos_fam_cartilla prob_juntos_fam_enc, color(red%50))(lfit prob_juntos_ind_cartilla prob_juntos_ind_enc, color(blue%50)) (function y = x, color(black%50) range(0 100)), ///
            title("Prob. quedar juntos (sin considerar MA)") ytitle("Prob. cartilla") xtitle("Prob. encuesta") legend(label(1 "") label(2 "") label(3 "Familiar") label(4 "Individual") label(5 "y = x"))
    

        // Histogram of differences

            gen dif_fam = prob_juntos_fam_cartilla - prob_juntos_fam_enc
            gen dif_ind = prob_juntos_ind_cartilla - prob_juntos_ind_enc

            twoway (histogram dif_fam, frac color(blue%50))(histogram dif_ind, frac color(red%50)), legend(label(1 "Familiar") label(2 "Individual")) ///
            title("Diferencia en prob. de ser asignados juntos") subtitle("Cartilla - Encuesta") ytitle("Fracción")

        // Distribution of prob. assigned together with fam. app.

            preserve 
                keep if apertura_post_fam == 1
                keep if prob_juntos_fam_enc_pre != .
                twoway (kdensity prob_juntos_fam_cartilla, color(red%50)) (kdensity prob_juntos_fam_enc, color(blue%50))  (kdensity prob_juntos_fam_enc_pre, color(green%50)), ///
                legend(label(1 "Cartilla") label(2 "Encuesta - post cartilla") label(3 "Encuesta - previo cartilla")) title("Distribución prob. asignación juntos usando post. fam.") ///
                xtitle("Probabilidad")
            restore 

        // Bias before the intervention

            gen bias_before = prob_juntos_fam_enc_pre - prob_juntos_fam_cartilla

            preserve
                keep if apertura_post_fam == 1
                keep if prob_juntos_fam_enc_pre != .
                violinplot bias_before, split(postulacion_familiar_28) colors(blue red) xtitle("Prob. encuesta ('antes' de la cartilla) - Prob. cartilla") ///
                title("Sesgo en la probabilidad de ser asignados juntos usando post. fam.") note("Sesgo positivo = optimistas. Sesgo negativo = pesimistas") horizontal
            restore 

        // Change in bias

            gen bias_after = prob_juntos_fam_enc - prob_juntos_fam_cartilla

            preserve
                keep if apertura_post_fam == 1
                drop if bias_before == . | bias_after == .
                reshape long bias_ , i(id_apoderado) j(time) string
                rename bias_ bias

                replace time = "After feedback" if time == "after"
                replace time = "Before feedback" if time == "before"

                violinplot bias if prob_juntos_fam_cartilla != 100 & prob_juntos_fam_cartilla != 0, split(time) colors(blue red) horizontal xtitle("Prob. survey - Prob. feedback") title("Bias in the probability of being assigned together using fam. app.") ///
                note("Positive bias = optimistics. Negative bias = pesimistics.") 
            restore 

            scatter bias_after bias_before if apertura_post_fam == 1, msize(tiny) mcolor(blue%50) ytitle("Bias after feedback") xtitle("Bias before feedback") ///
            title("Relationship between bias") note("Positive bias = optimistics. Negative bias = pesimistics.")

            gen     should = 0
            replace should = 1 if postulacion_familiar_28 == "Familiar (28 ago)" & prob_juntos_fam_cartilla < prob_juntos_ind_cartilla
            replace should = 1 if postulacion_familiar_28 == "Individual (28 ago)" & prob_juntos_fam_cartilla > prob_juntos_ind_cartilla
            replace should = 2 if prob_juntos_fam_cartilla == prob_juntos_ind_cartilla

            label def should_what 0 "Debe mantener" 1 "Debe cambiar" 2 "Indiferente"
            label values should should_what

            gen     change = 0
            replace change = 100 if postulacion_familiar_28 == "Individual (28 ago)" & postulacion_familiar_post == 1
            replace change = 100 if postulacion_familiar_28 == "Familiar (28 ago)" & postulacion_familiar_post == 0

            encode sibl06_menos, gen(sibl06_encode)
            gen strong_for_joint = sibl06_encode == 2 if sibl06_encode != .

            preserve
                keep if apertura_post_fam == 1
                drop if bias_before == . | bias_after == .
                reshape long bias_ , i(id_apoderado) j(time) string
                rename bias_ bias

                replace time = " Después cartilla" if time == "after"
                replace time = " 'Antes' cartilla" if time == "before"

                tab bias if strong_for_joint == 1 & change == 100

                graph hbox bias if strong_for_joint == 1 & change == 100, over(time) box(1, color(red)) ytitle("Sesgo = Prob. encuesta - Prob. cartilla") title("Distribución sesgos en la prob. de ser asignados juntos usando la post. fam.") ///
                note("Sesgo positivo = optimistas. Sesgo negativo = pesimistas.") subtitle("Grupo con alta preferencia por asignación conjunta y que cambia su opción")
            restore 

            tab sibl16 if change == 100 & strong_for_joint == 1


