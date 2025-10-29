// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Preliminar analysis of 2023 online survey
	// Created: Oct 20, 2023
	// Last Modified: Oct 23, 2023
	// Author: Javi Gazmuri

// -----------------------------------------------------------------------------

// ----------------------------------------------------------------
// Data 
// ----------------------------------------------------------------

    import delimited "$pathData_survey/outputs/responses/SAE_survey_2023_responses_Full_sample.csv", clear
    drop if id_apoderado == ""
    tempfile respuestas
    save `respuestas', replace

// ----------------------------------------------------------------
// Knowledge and importance of the problem 
// ----------------------------------------------------------------

    use `respuestas', clear

    // Importancia problema

        gen poca_importancia    = 100 * (sibl01 == "De poca importancia" | sibl01 == "Sin importancia")
        gen media_importancia   = 100 * (sibl01 == "Moderadamente importante")
        gen mucha_importancia   = 100 * (sibl01 == "Importante" | sibl01 == "Muy importante")

        qui tabstat poca_importancia media_importancia mucha_importancia if sibl01 != "", stat(mean)

    // Conocimiento postulación familiar

        qui tab sibl02
        qui tab sibl02 if ensibling == 1
        qui tab sibl02 if ensibling == 1 & sibl11 == "Sí"

    // Nivel conocimiento

        gen     conocimiento = "Cambia preferencias menor"  if sibl03_a == "Cambia las preferencias del postulante menor para poner como primera preferencia el establecimiento al cual el postulante mayor fue asignado"
        replace conocimiento = "Cambia preferencias mayor"  if sibl03_a == "Cambia las preferencias del postulante mayor para poner como primera preferencia el establecimiento al cual el postulante menor fue asignado"
        replace conocimiento = "Prioridad hermano estática" if sibl03_a == "El postulante tiene prioridad de asignación en el establecimiento en el cual algún hermano está matriculado"
        replace conocimiento = "Prioridad hermano dinámica" if sibl03_a == "El postulante tiene prioridad de asignación en el establecimiento en el cual algún hermano fue asignado"
        replace conocimiento = "Asignación automática"      if sibl03_a == "El postulante queda automáticamente asignado en el establecimiento en el cual algún hermano fue asignado"
        replace conocimiento = "No está seguro"             if sibl03_a == "No estoy seguro"

        gen aux = 1

        count if sibl03_a != "" & ensibling == 1
        local N `r(N)'
        qui graph hbar (percent) aux if sibl03_a != "" & ensibling == 1, over(conocimiento) ytitle("Porcentaje") ///
        title("Con 2 postulantes") bar(1, color(red%70)) blabel(bar, position(inside) format(%9.0f) color(white)) ///
        name(general, replace) legend(off) note("N = `N'")

        count if sibl03_a != "" & ensibling == 1 & sibl11 == "Sí"
        local N `r(N)'
        qui graph hbar (percent) aux if sibl03_a != "" & ensibling == 1 & sibl11 == "Sí", over(conocimiento) ytitle("Porcentaje") ///
        title("Con 2 postulantes y revisó la cartilla") bar(1, color(purple%70)) blabel(bar, position(inside) format(%9.0f) color(white)) ///
        name(ven_cartilla, replace) legend(off) note("N = `N'")
 
        grc1leg general ven_cartilla
    
    // Conoce a alguien que sabe

        qui tab sibl03_b
        qui tab sibl03_b if ensibling == 1

// ----------------------------------------------------------------
// Preferences
// ----------------------------------------------------------------

    keep if ensibling == 1

    // Quedan en la misma escuela: más preferido

        gen number_school_joint = substr(sibl04_1,-2,1)
        destring number_school_joint, replace 

        gen comun_mas_preferido = ""

        forvalues x = 1/6 {
            replace comun_mas_preferido = schjoint0`x' if number_school_joint == `x'
        }
  
        gen comun_pref_menor = . 
        gen comun_pref_mayor = .
        gen schmayor08 = ""

        forvalues x = 1/8 {
            replace comun_pref_menor = `x' if comun_mas_preferido == schmenor0`x'
            replace comun_pref_mayor = `x' if comun_mas_preferido == schmayor0`x'
        }

        replace comun_pref_menor = . if sibl04_1 == ""
        replace comun_pref_mayor = . if sibl04_1 == ""

        gen     primera_pref_menor = 0 if comun_pref_menor != .
        replace primera_pref_menor = 1 if comun_pref_menor == 1

        gen     primera_pref_mayor = 0 if comun_pref_mayor != .
        replace primera_pref_mayor = 1 if comun_pref_mayor == 1
        
        tab primera_pref_menor primera_pref_mayor

    // Quedan en la misma escuela: menos preferido

        gen number_school_joint_less = substr(sibl04_2,-2,1)
        destring number_school_joint_less, replace 

        gen comun_menos_preferido = ""

        forvalues x = 1/6 {
            replace comun_menos_preferido = schjoint0`x' if number_school_joint_less == `x'
        }
  
        gen comun_menos_pref_menor = . 
        gen comun_menos_pref_mayor = .

        forvalues x = 1/8 {
            replace comun_menos_pref_menor = `x' if comun_menos_preferido == schmenor0`x'
            replace comun_menos_pref_mayor = `x' if comun_menos_preferido == schmayor0`x'

        }

        replace comun_menos_pref_menor = . if sibl04_2 == ""
        replace comun_menos_pref_mayor = . if sibl04_2 == ""

        gen     ultima_pref_menor = 0 if comun_menos_pref_menor != .
        replace ultima_pref_menor = 1 if comun_menos_pref_menor == total_postulacion_1

        gen     ultima_pref_mayor = 0 if comun_menos_pref_mayor != .
        replace ultima_pref_mayor = 1 if comun_menos_pref_mayor == total_postulacion_2
        
        tab ultima_pref_menor ultima_pref_mayor

    // Quedan en distintas escuelas: más preferido

        gen number_school_sep_menor = substr(sibl05_menor,-2,1)
        gen number_school_sep_mayor = substr(sibl05_mayor,-2,1)

        destring number_school_sep_menor number_school_sep_mayor, replace 

        replace number_school_sep_menor = 10 if number_school_sep_menor == 0
        replace number_school_sep_mayor = 10 if number_school_sep_mayor == 0

        gen     indicador = "Otro" if sibl05_menor != ""
        replace indicador = "Menor 1a, Mayor 2a" if number_school_sep_menor == 1 & number_school_sep_mayor == 2
        replace indicador = "Menor 2a, Mayor 1a" if number_school_sep_menor == 2 & number_school_sep_mayor == 1
        replace indicador = "Ambos en 1a" if number_school_sep_menor == 1 & number_school_sep_mayor == 1

        graph hbar (percent) aux if sibl05_menor != "", over(indicador) ytitle("Porcentaje") ///
        title("") bar(1, color(red%70)) blabel(bar, position(inside) format(%9.0f) color(white)) ///
        name(general, replace) legend(off) 

        drop primera_pref_menor primera_pref_mayor

        gen     primera_pref_menor = 0 if number_school_sep_menor != .
        replace primera_pref_menor = 1 if number_school_sep_menor == 1

        gen     primera_pref_mayor = 0 if number_school_sep_mayor != .
        replace primera_pref_mayor = 1 if number_school_sep_mayor == 1

        tab primera_pref_menor primera_pref_mayor

    // Qué prefieres?

        tab sibl06_mas
        tab sibl06_menos

    // Rechazar asignación más preferida separados

        twoway (histogram sibl07_1, frac color(red%70) bin(10)) (histogram sibl07_2, frac color(purple%70) bin(10)), ///
        legend(order(1 "Menor" 2 "Mayor" ))

    // Rechazar asignación cuando solo uno queda en primera preferencia 

        histogram sibl09_1, frac color(red%70) bin(10) ytitle("Porcentaje") xtitle("Prob. rechazar ambas asignaciones") 
    
    // Mediano plazo

        tab sibl10_mas
        tab sibl10_menos

// ----------------------------------------------------------------
// Cartilla
// ----------------------------------------------------------------

    // Apertura

        tab sibl11
    
    // Por qué no abrió la cartilla?

        tab sibl12

    // Evento más probable

        encode sibl13, gen(sibl13_cat) 

        // Juntos en preferencia

            tab sibl13_cat, nolabel

        // Separados en preferencias

            tab sibl13_cat if total_postulacion_1 > 1 | total_postulacion_2 > 1, nolabel

        // Juntos pero al menos uno en MA

            tab sibl13_cat if igual_ma == 1 | postula_ma_otro == 1, nolabel

        // Separados pero al menos uno en MA

            tab sibl13_cat if ag_cont_1 == 1 | ag_cont_2 == 1, nolabel

        // Al menos uno no asignado

            tab sibl13_cat if ag_cont_1 == 0 | ag_cont_2 == 0, nolabel

    // Probabilidad de asignación en conjunto

        count if opcion_seleccionada == "postulación familiar" & sibl14_1 != . & sibl15_1 != .
        local N `r(N)'
        twoway (histogram sibl14_1 if opcion_seleccionada == "postulación familiar", frac color(red%70) bin(10)) ///
        (histogram sibl15_1 if opcion_seleccionada == "postulación familiar", frac color(purple%70) bin(10)), ///
        legend(order(1 "Seleccionada" 2 "No seleccionada" )) title("Seleccionaron familiar") name(sel_familiar, replace) note("N = `N'")

        count if opcion_seleccionada == "postulación individual" & sibl14_1 != . & sibl15_1 != .
        local N `r(N)'
        twoway (histogram sibl14_1 if opcion_seleccionada == "postulación individual", frac color(red%70) bin(10)) ///
        (histogram sibl15_1 if opcion_seleccionada == "postulación individual", frac color(purple%70) bin(10)), ///
        legend(off) title("Seleccionaron independiente") name(sel_independiente, replace) note("N = `N'")
 
        grc1leg sel_familiar sel_independiente

        gen     dif_prob = sibl14_1 - sibl15_1 if opcion_seleccionada == "postulación familiar"     // familiar - independiente
        replace dif_prob = sibl15_1 - sibl14_1 if opcion_seleccionada == "postulación individual"   // familiar - independiente

        twoway (kdensity dif_prob if opcion_seleccionada == "postulación familiar", color(red%70)) ///
        (kdensity dif_prob if opcion_seleccionada == "postulación individual", color(purple%50) ), ///
        legend(order(1 "Seleccionaron familiar" 2 "Seleccionaron individual" )) xtitle("") ///
        title("Diferencia probabilidades (familiar - independiente)") ytitle("Densidad")

    // Ayudó cartilla

        tab sibl16 
    
    // Antes vs después de la cartilla: prob juntos 

        gen     prob_post_familiar = sibl14_1 if opcion_seleccionada == "postulación familiar"
        replace prob_post_familiar = sibl15_1 if opcion_seleccionada == "postulación individual"

        gen dif_prob_2 = prob_post_familiar - sibl17

        count if sibl17 != . & prob_post_familiar != .
        local N `r(N)'
        twoway (histogram sibl17 if sibl17 != . & prob_post_familiar != ., bin(10) frac color(red%70)) ///
        (histogram prob_post_familiar if sibl17 != . & prob_post_familiar != ., bin(10) frac color(purple%70) ), ///
        legend(order(1 "Prob. antes cartilla" 2 "Prob. después cartilla" )) xtitle("") ///
        title("") name(prob_ind, replace) title("Distribución probabilidades") note("N = `N'")

        kdensity dif_prob_2 if sibl17 != . & prob_post_familiar != ., title("Diferencia probabilidades (Post cartilla - Previo cartilla)") ///
        ytitle("Densidad") name(dif_prob, replace) xtitle("") note("")

        grc1leg prob_ind dif_prob

    // Probabilidad de asignación en evento general

        // Primer evento 

            count if sibl18_1 != . & sibl19_4 != . & opcion_seleccionada == "postulación familiar" & tiene_segundo_evento == 0 
            local N `r(N)'
            twoway (histogram sibl18_1 if opcion_seleccionada == "postulación familiar" & tiene_segundo_evento == 0, frac color(red%70) bin(10)) ///
            (histogram sibl19_4 if opcion_seleccionada == "postulación familiar" & tiene_segundo_evento == 0, frac color(purple%70) bin(10)), ///
            legend(order(1 "Seleccionada" 2 "No seleccionada" )) title("Seleccionaron familiar") name(sel_familiar, replace) note("N = `N'")

            count if sibl18_1 != . & sibl19_4 != . & opcion_seleccionada == "postulación individual" & tiene_segundo_evento == 0 
            local N `r(N)'
            twoway (histogram sibl18_1 if opcion_seleccionada == "postulación individual" & tiene_segundo_evento == 0, frac color(red%70) bin(10)) ///
            (histogram sibl19_4 if opcion_seleccionada == "postulación individual" & tiene_segundo_evento == 0, frac color(purple%70) bin(10)), ///
            legend(off) title("Seleccionaron independiente") name(sel_independiente, replace) note("N = `N'")
    
            grc1leg sel_familiar sel_independiente

        // Segundo evento 

            count if sibl18_1 != . & sibl19_4 != . & opcion_seleccionada == "postulación familiar" & tiene_segundo_evento == 1
            local N `r(N)'
            twoway (histogram sibl18_1 if opcion_seleccionada == "postulación familiar" & tiene_segundo_evento == 1, frac color(red%70) bin(10)) ///
            (histogram sibl19_4 if opcion_seleccionada == "postulación familiar", frac color(purple%70) bin(10)), ///
            legend(order(1 "Seleccionada" 2 "No seleccionada" )) title("Seleccionaron familiar") name(sel_familiar, replace) note("N = `N'")

            count if sibl18_1 != . & sibl19_4 != . & opcion_seleccionada == "postulación individual" & tiene_segundo_evento == 1
            local N `r(N)'
            twoway (histogram sibl18_1 if opcion_seleccionada == "postulación individual" & tiene_segundo_evento == 1, frac color(red%70) bin(10)) ///
            (histogram sibl19_4 if opcion_seleccionada == "postulación individual", frac color(purple%70) bin(10)), ///
            legend(off) title("Seleccionaron independiente") name(sel_independiente, replace) note("N = `N'")
    
            grc1leg sel_familiar sel_independiente

    // Cambio selección post. fam o no cambió

        tab sibl20_a
        tab sibl20_b

    // Por qué no influyó?

        gen     razones = "Mostraba probabilidades muy similares"   if sibl21 == "Mostraba probabilidades muy similares para ambas opciones"
        replace razones = "No vi esa información"                   if sibl21 == "No vi esa información"
        replace razones = "No la entendí"                           if sibl21 == "No la entendí"
        replace razones = "Otra razón"                              if sibl21 == "Otra razón"

        graph hbar (percent) aux if sibl21 != "", over(razones) ytitle("Porcentaje") ///
        title("") bar(1, color(red%70)) blabel(bar, position(inside) format(%9.0f) color(white)) 

    // Considerado comportamiento dinámico

        graph hbar (percent) aux if sibl22 != "", over(sibl22) ytitle("Porcentaje") ///
        title("") bar(1, color(red%70)) blabel(bar, position(inside) format(%9.0f) color(white)) 

    // Efecto cartilla en comportamiento dinámico 

        tab sibl23

// ----------------------------------------------------------------
// Ordenamiento eventos cartilla
// ----------------------------------------------------------------

    keep id_apoderado sibl08_1 sibl08_2 sibl08_3 sibl08_4 sibl08_5 tiene_outside_option_1 outside_option_1 n_eventos ag_cont_1 ag_cont_2
    keep if sibl08_1 != .

    tempfile ordenamiento_eventos
    save `ordenamiento_eventos', replace

    // Usamos tabla con todos los eventos que se cargaron en la cartilla 
        
        import delimited "$main_sae/cartillas/cartillas_postulación/1_etapa_regular/4_research_tables/siblings/tabla_auxiliar_eventos.csv", clear
        keep if n_evento < 5
        keep orden_menor orden_mayor evento prob_conjunta_bloque prob_conjunta_sinbloque id_apoderado n_evento

        merge m:1 id_apoderado using `ordenamiento_eventos', keep(3) nogen

        gen valoracion_evento = .

        forvalues x = 1/4 {
            replace valoracion_evento = sibl08_`x' if n_evento == `x'
        }

        gen lugar_relativo = valoracion_evento / n_eventos

    // Falta agregar outside option como evento

        bys id_apoderado: gen aux = _n
        expand 2 if aux == 1, gen(expandidas)
        drop if tiene_outside_option_1 == 0 & expandidas == 1

        replace evento = "mat_aseg:mat_aseg" if outside_option_1 == "Ambos postulantes se mantienen en su actual establecimiento" & expandidas == 1        
        replace evento = "no_asig:no_asig" if outside_option_1 == "Los postulantes no quedan asignados en ningún establecimiento" & expandidas == 1

        replace evento = "no_asig:mat_aseg" if outside_option_1 == "Un postulante se mantiene en su actual establecimiento y el otro no queda asignado" & expandidas == 1 & ag_cont_1 == 1 & ag_cont_2 == 0
        replace evento = "mat_aseg:no_asig" if outside_option_1 == "Un postulante se mantiene en su actual establecimiento y el otro no queda asignado" & expandidas == 1 & ag_cont_1 == 0 & ag_cont_2 == 1

        replace lugar_relativo = sibl08_5/n_eventos if expandidas == 1

    bys evento: gen n_veces = _N
    replace evento = subinstr(evento, ":", "/", .) 

    joyplot lugar_relativo if n_veces > 200, by(evento) droplow bwid(0.1) alpha(50) lw(0.2) norm(local) yline ytitle("Evento (Mayor/Menor)") ///
    xtitle("Lugar relativo") title("Distribución eventos") xline(0 1) ylabpos(right) 

// ----------------------------------------------------------------
// Comparación probabilidades previo, post cartilla y probabilidad real
// ----------------------------------------------------------------

    // Probabilidad quedar juntos

        // Probabilidades reales (mostradas en la cartilla)

            import delimited "$main_sae/cartillas/cartillas_postulación/1_etapa_regular/4_research_tables/siblings/tabla_auxiliar_eventos.csv", clear

            gen     evento_juntos = 0 
            replace evento_juntos = 1 if n_evento < 5 & rbd_menor == rbd_mayor 
            replace evento_juntos = 1 if n_evento == 5

            keep if evento_juntos == 1

            collapse (sum) prob_conjunta_bloque prob_conjunta_sinbloque (firstnm) postula_en_bloque, by(id_apoderado)
            tempfile probabilidades_reales
            save `probabilidades_reales', replace

        // Respuestas

            import delimited "$pathData_survey/outputs/responses/SAE_survey_2023_responses_Full_sample.csv", clear
            drop if id_apoderado == ""

            keep id_apoderado sibl14 sibl15 sibl16 sibl17 opcion_seleccionada sibl11

            gen     prob_post_familiar_post = sibl14_1 if opcion_seleccionada == "postulación familiar"
            replace prob_post_familiar_post = sibl15_1 if opcion_seleccionada == "postulación individual"

            rename sibl17 prob_post_familiar_previo

        // Estadística 

            merge 1:1 id_apoderado using `probabilidades_reales', keep(3) nogen
            
            replace prob_conjunta_bloque = prob_conjunta_bloque * 100
            replace prob_conjunta_sinbloque = prob_conjunta_sinbloque * 100

            gen dif_real_previo = prob_conjunta_bloque - prob_post_familiar_previo
            gen dif_real_post   = prob_conjunta_bloque - prob_post_familiar_post

            gen ab_dif_real_previo  = abs(dif_real_previo)
            gen ab_dif_real_post    = abs(dif_real_post)

            preserve
                drop if prob_post_familiar_previo == .

                twoway (kdensity dif_real_previo, color(red%70) bwidth(15)) (kdensity dif_real_post, color(purple%70) bwidth(15)),  ///
                legend(order(1 "Previo cartilla" 2 "Post cartilla" )) xtitle("Prob. cartilla - prob. auto-reportada") 

                twoway (kdensity ab_dif_real_previo, color(red%70) bwidth(15)) (kdensity ab_dif_real_post, color(purple%70) bwidth(15)),  ///
                legend(order(1 "Previo cartilla" 2 "Post cartilla" )) xtitle("Valor absoluto(Prob. cartilla - prob. auto-reportada)") title("Probabilidad de ser asignados juntos") subtitle("Usando la postulación familiar") 
            restore

            gen     vio_cartilla = 0
            replace vio_cartilla = 1 if sibl11 == "Sí"

            gen     prob_post_ind_post = sibl14_1 if opcion_seleccionada == "postulación individual"
            replace prob_post_ind_post = sibl15_1 if opcion_seleccionada == "postulación familiar"

            gen ab_dif_real_ind = abs(prob_conjunta_sinbloque - prob_post_ind_post)

            twoway (kdensity ab_dif_real_post if vio_cartilla == 0, color(red%70) bwidth(15)) (kdensity ab_dif_real_post if vio_cartilla == 1, color(purple%70) bwidth(15)),  ///
            legend(order(1 "No vio cartilla" 2 "Vio cartilla")) title("Probabilidad de ser asignados juntos") xtitle("Valor absoluto(Prob. cartilla - prob. auto-reportada)") ///
            subtitle("Usando la postulación familiar") ytitle("Densidad") name(bloque_juntos, replace)
 
            twoway (kdensity ab_dif_real_ind if vio_cartilla == 0, color(red%70) bwidth(15)) (kdensity ab_dif_real_ind if vio_cartilla == 1, color(purple%70) bwidth(15)),  ///
            legend(off) title("Probabilidad de ser asignados juntos") xtitle("Valor absoluto(Prob. cartilla - prob. auto-reportada)") ///
            subtitle("Usando la postulación individual") ytitle("Densidad") name(no_bloque_juntos, replace)

            grc1leg bloque_juntos no_bloque_juntos

    // Prob. evento general

        // Probabilidades reales (mostradas en la cartilla)

            import delimited "$main_sae/cartillas/cartillas_postulación/1_etapa_regular/4_research_tables/siblings/tabla_auxiliar_eventos.csv", clear
            keep if n_evento == 1 | n_evento == 2

            bys id_apoderado: egen max_evento = max(n_evento)

            drop if n_evento == 1 & max_evento == 2

            keep id_apoderado n_evento evento prob_conjunta_bloque prob_conjunta_sinbloque postula_en_bloque
            tempfile probabilidades_reales
            save `probabilidades_reales', replace

        // Respuestas

            import delimited "$pathData_survey/outputs/responses/SAE_survey_2023_responses_Full_sample.csv", clear
            drop if id_apoderado == ""

            keep id_apoderado sibl18 sibl19 opcion_seleccionada sibl11

            gen     prob_post_fam_evento = sibl18 if opcion_seleccionada == "postulación familiar"
            replace prob_post_fam_evento = sibl19 if opcion_seleccionada == "postulación individual"

            gen     prob_ind_fam_evento = sibl18 if opcion_seleccionada == "postulación individual"
            replace prob_ind_fam_evento = sibl19 if opcion_seleccionada == "postulación familiar"
   
        // Estadística 

            merge 1:1 id_apoderado using `probabilidades_reales', keep(3) nogen

            drop if sibl18 == .

            replace prob_conjunta_bloque    = prob_conjunta_bloque * 100
            replace prob_conjunta_sinbloque = prob_conjunta_sinbloque * 100

            gen ab_dif_bloque       = abs(prob_conjunta_bloque - prob_post_fam_evento)
            gen ab_dif_sinbloque    = abs(prob_conjunta_sinbloque - prob_ind_fam_evento)

            gen     vio_cartilla = 0
            replace vio_cartilla = 1 if sibl11 == "Sí"

            twoway (kdensity ab_dif_bloque if n_evento == 1 & vio_cartilla == 0, color(red%70) bwidth(15)) (kdensity ab_dif_bloque if n_evento == 1 & vio_cartilla == 1, color(purple%70) bwidth(15)),  ///
            legend(order(1 "No vio cartilla" 2 "Vio cartilla")) title("Evento: ambos en 1a preferencia") xtitle("") ///
            subtitle("Probabilidad usando la postulación familiar") ytitle("Densidad") name(bloque_primer_evento, replace)
 
            twoway (kdensity ab_dif_sinbloque if n_evento == 1 & vio_cartilla == 0, color(red%70) bwidth(15)) (kdensity ab_dif_sinbloque if n_evento == 1 & vio_cartilla == 1, color(purple%70) bwidth(15)),  ///
            legend(off) title("Evento: ambos en 1a preferencia") xtitle("") ///
            subtitle("Probabilidad usando la postulación individual") ytitle("") name(no_bloque_primer_evento, replace)

            twoway (kdensity ab_dif_bloque if n_evento == 2 & vio_cartilla == 0, color(red%70) bwidth(15)) (kdensity ab_dif_bloque if n_evento == 2 & vio_cartilla == 1, color(purple%70) bwidth(15)),  ///
            legend(off) title("Evento: más probable con post. fam.") xtitle("Valor absoluto(Prob. cartilla - prob. auto-reportada)") ///
            subtitle("Probabilidad usando la postulación familiar") ytitle("Densidad") name(bloque_segundo_evento, replace)
 
            twoway (kdensity ab_dif_sinbloque if n_evento == 2 & vio_cartilla == 0, color(red%70) bwidth(15)) (kdensity ab_dif_sinbloque if n_evento == 2 & vio_cartilla == 1, color(purple%70) bwidth(15)),  ///
            legend(off) xtitle("Valor absoluto(Prob. cartilla - prob. auto-reportada)") title("Evento: más probable con post. fam.") ///
            subtitle("Probabilidad usando la postulación individual") ytitle("") name(no_bloque_segundo_evento, replace)

            grc1leg bloque_primer_evento no_bloque_primer_evento bloque_segundo_evento no_bloque_segundo_evento

            * MA 

            twoway (kdensity ab_dif_bloque if n_evento == 2 & evento == "mat_aseg:mat_aseg" & prob_conjunta_bloque > 50 & vio_cartilla == 0, color(red%70) bwidth(15)) (kdensity ab_dif_bloque if n_evento == 2 & evento == "mat_aseg:mat_aseg" & prob_conjunta_bloque > 50 & vio_cartilla == 1, color(purple%70) bwidth(15)),  ///
            xtitle("Valor absoluto(Prob. cartilla - prob. auto-reportada)") title("Evento: más probable con post. fam - ambos en MA") ///
            legend(order(1 "No vio cartilla" 2 "Vio cartilla")) subtitle("Probabilidad usando la postulación familiar") ytitle("Densidad") 
