// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Preliminar analysis of 2023 feedback intervention
	// Created: Oct 25, 2023
	// Last Modified: Feb 2, 2024
	// Author: Javi Gazmuri
// -----------------------------------------------------------------------------

    import delimited "$pathData/intermediate/feedback/2023/clean_data/consolidated_data_reg.csv", clear

// ---------------------------------------------- //
// ------------------ STATISTICS ---------------- //
// ---------------------------------------------- //

    gen abrio_cartilla = apertura_post_fam * 100

// ----------------------------------------------------------------
// Openings - Mixpanel
// ----------------------------------------------------------------

    graph bar (mean) abrio_cartilla, over(postulacion_familiar_28) ytitle("Porcentaje del total") bar(1, color(purple%70)) title("Abre cartilla")

    tab apertura_video
    tab apertura_post_fam

    // Apertura módulo intertemporal

        tab apertura_dynamic if tiene_dinamico == 1

// ----------------------------------------------------------------
// Elicitación preferencias
// ----------------------------------------------------------------

    tab sibl06_menos

    gen multip_prob_rechazo = (sibl07_1/100)*(sibl07_2/100)

    gen multip_alta = multip_prob_rechazo > 0.5 if multip_prob_rechazo != .

    tab multip_alta

    gen multip_alta_2 = sibl09_1/100 > 0.5 if  sibl09_1 != .

    tab multip_alta_2

// ----------------------------------------------------------------
// Cambia opción seleccionada
// ----------------------------------------------------------------

    gen     post_fam_28 = 0 if postulacion_familiar_28 == "Individual (28 ago)"
    replace post_fam_28 = 1 if postulacion_familiar_28 == "Familiar (28 ago)"

    drop postulacion_familiar_28
    rename post_fam_28 postulacion_familiar_28

    gen     cambia_post_fam = 0
    replace cambia_post_fam = 100   if postulacion_familiar_28 != postulacion_familiar_post & postulacion_familiar_post != . 

    gen cambia_post_fam_abre    = cambia_post_fam if abrio_cartilla == 100
    gen cambia_post_fam_noabre  = cambia_post_fam if abrio_cartilla == 0

    graph bar (mean) cambia_post_fam_abre cambia_post_fam_noabre, ///
    over(postulacion_familiar_28, relabel(1 "Individual a familiar" 2 "Familiar a individual")) ///
    ytitle("Porcentaje del total") bar(1, color(purple%70)) bar(2, color(red%70)) title("Cambia opción") ///
    legend(order(1 "Abrió cartilla" 2 "No abrió cartilla")) 

    tab abrio_cartilla postulacion_familiar_28 if cambia_post_fam == 100

    reg postulacion_familiar_post i.apertura_post_fam 
    reg postulacion_familiar_post i.apertura_post_fam i.postulacion_familiar_28

    // Respuesta encuesta

        tab sibl20_a if cambia_post_fam == 100 

    // Más probables de cambiar

        // General:

            // Al menos un evento en donde prob_familiar != prob_individual

            gen     con_dif_profs = 0
            replace con_dif_profs = 1 if e1_prob_familiar != e1_prob_independiente | e2_prob_familiar != e2_prob_independiente | e3_prob_familiar != e3_prob_independiente | e4_prob_familiar != e4_prob_independiente

            tab con_dif_profs

            graph bar (mean) cambia_post_fam_abre cambia_post_fam_noabre if con_dif_profs == 1, ///
            over(postulacion_familiar_28, relabel(1 "Individual a familiar" 2 "Familiar a individual")) ///
            ytitle("Porcentaje del total") bar(1, color(purple%70)) bar(2, color(red%70)) title("Cambia opción") ///
            legend(order(1 "Abrió post. fam." 2 "No abrió")) 

            // Aquellos con baja probabilidad de quedar en el 1:1 

            replace e1_prob_familiar = "100%"       if e1_prob_familiar == "más de 95%"
            replace e1_prob_familiar = "0%"         if e1_prob_familiar == "menos de 5%"

            destring e1_prob_familiar, replace ignore("%")

            gen     intervalo_prob_1 = 1 if e1_prob_familiar < 20
            replace intervalo_prob_1 = 2 if e1_prob_familiar >= 20 & e1_prob_familiar < 40
            replace intervalo_prob_1 = 3 if e1_prob_familiar >= 40 & e1_prob_familiar < 60
            replace intervalo_prob_1 = 4 if e1_prob_familiar >= 60 & e1_prob_familiar < 80
            replace intervalo_prob_1 = 5 if e1_prob_familiar >= 80 
            replace intervalo_prob_1 = . if e1_prob_familiar == .

            label def intervalo_def 1 "< 20%" 2 "20% - 40%" 3 "40% - 60%" 4 "60% - 80%" 5 "> 80%" 
            label values intervalo_prob_1 intervalo_def

            graph bar (mean) cambia_post_fam_abre cambia_post_fam_noabre,  ///
            over(intervalo_prob_1) ytitle("Porcentaje") bar(1, color(purple%70)) bar(2, color(red%70)) legend(order(1 "Abrió cartilla" 2 "No abrió cartilla")) ///
            title("Cambia opción") b1title("Probabilidad de asignación al 1:1")

        // Individual a bloque:
            // prob bloque > prob individual en evento mayor prob. post. fam. 
            // Saco casos que incluye mat. asegurada

            replace e2_prob_familiar = "100%"       if e2_prob_familiar == "más de 95%"
            replace e2_prob_independiente = "100%"  if e2_prob_independiente == "más de 95%"

            replace e2_prob_familiar = "0%"         if e2_prob_familiar == "menos de 5%"
            replace e2_prob_independiente = "0%"    if e2_prob_independiente == "menos de 5%"

            destring e2_prob_familiar e2_prob_independiente, replace ignore("%")

            gen     grupo_interes = 0 
            replace grupo_interes = 1 if postulacion_familiar_28 == 0 & tiene_segundo_evento == 1 & e2_prob_familiar > e2_prob_independiente & regexm(e2_explicacion,"(su establecimiento de origen)") == 0
            replace grupo_interes = 2 if postulacion_familiar_28 == 1 & tiene_segundo_evento == 1 & e2_prob_familiar > e2_prob_independiente & regexm(e2_explicacion,"(su establecimiento de origen)") == 1

            label def grupos_intereses 1 "Individual a familiar" 2 "Familiar a individual"
            label values grupo_interes grupos_intereses

            gen     intervalo_prob_2 = 1 if e2_prob_familiar < 20
            replace intervalo_prob_2 = 2 if e2_prob_familiar >= 20 & e2_prob_familiar < 40
            replace intervalo_prob_2 = 3 if e2_prob_familiar >= 40 & e2_prob_familiar < 60
            replace intervalo_prob_2 = 4 if e2_prob_familiar >= 60 & e2_prob_familiar < 80
            replace intervalo_prob_2 = 5 if e2_prob_familiar >= 80 
            replace intervalo_prob_2 = . if e2_prob_familiar == .

            label values intervalo_prob_2 intervalo_def

            gen aux_vio_cartilla    = 1 if abrio_cartilla == 100
            gen aux_no_vio_cartilla = 1 if abrio_cartilla == 0

            graph bar (mean) cambia_post_fam_abre cambia_post_fam_noabre if grupo_interes == 1,  ///
            over(intervalo_prob_2) ytitle("Porcentaje") bar(1, color(purple%70)) bar(2, color(red%70)) legend(order(1 "Abrió cartilla" 2 "No abrió cartilla")) ///
            title("Cambia de individual a familiar") b1title("Probabilidad de asignación a 2º evento con post. fam.")

        // Bloque a individual:
            // Segundo evento es matrícula asegurada
            // prob. bloque > prob. individual

            // A medida que aumenta la probabilidad con postulación familiar (y prob_fam > prob_ind), más deberían cambiarse de familiar a individual

            graph bar (mean) cambia_post_fam_abre cambia_post_fam_noabre if grupo_interes == 2,  ///
            over(intervalo_prob_2) ytitle("Porcentaje") bar(1, color(purple%70)) bar(2, color(red%70)) legend(order(1 "Abrió cartilla" 2 "No abrió cartilla")) ///
            title("Cambia de familiar a individual") b1title("Probabilidad de asignación a MA con post. fam.")

        // Según info de la encuesta 

            // Preferencia por quedar juntos siempre 

                graph bar (mean) cambia_post_fam_abre cambia_post_fam_noabre if regexm(sibl06_menos,"Ambos") == 1, ///
                over(postulacion_familiar_28, relabel(1 "Individual a familiar" 2 "Familiar a individual")) ///
                ytitle("Porcentaje del total") bar(1, color(purple%70)) bar(2, color(red%70)) title("Cambia opción") ///
                legend(order(1 "Abrió cartilla" 2 "No abrió cartilla")) subtitle("Alta preferencia porque queden juntos")

            // 2o evento > 3er evento

                graph bar (mean) cambia_post_fam_abre cambia_post_fam_noabre if sibl08_2 > sibl08_3 & tiene_segundo_evento == 1 & tiene_tercer_evento == 1, ///
                over(postulacion_familiar_28, relabel(1 "Individual a familiar" 2 "Familiar a individual")) ///
                ytitle("Porcentaje del total") bar(1, color(purple%70)) bar(2, color(red%70)) title("Cambia opción") ///
                legend(order(1 "Abrió cartilla" 2 "No abrió cartilla")) subtitle("Preferencia por la postulación familiar")

            // 3er evento > 2o evento

                graph bar (mean) cambia_post_fam_abre cambia_post_fam_noabre if sibl08_2 < sibl08_3 & tiene_segundo_evento == 1 & tiene_tercer_evento == 1, ///
                over(postulacion_familiar_28, relabel(1 "Individual a familiar" 2 "Familiar a individual")) ///
                ytitle("Porcentaje del total") bar(1, color(purple%70)) bar(2, color(red%70)) title("Cambia opción") ///
                legend(order(1 "Abrió cartilla" 2 "No abrió cartilla")) subtitle("Preferencia por la postulación individual")

// ----------------------------------------------------------------
// Cambio postulaciones
// ----------------------------------------------------------------

        tempfile base_grande
        save `base_grande', replace

    // Algún tipo de cambio en las postulaciones

        import delimited "$main_sae/datos_SAE/1_Source/1_Principal/postulaciones/datos_jpal_2023-09-20.csv", clear
        keep id_postulante rbd cod_curso orden
        bys id_postulante: egen largo_final = max(orden)

        tempfile postulaciones_finales
        save `postulaciones_finales', replace

        import delimited "$main_sae/datos_SAE/1_Source/1_Principal/postulaciones/datos_jpal_2023-08-28.csv", clear
        keep id_postulante rbd cod_curso orden
        bys id_postulante: egen largo_inicial = max(orden)

        merge 1:1 id_postulante rbd cod_curso orden using `postulaciones_finales'

        bys id_postulante: egen min_merge = min(_merge)
        bys id_postulante: egen max_merge = max(_merge)

        * min_merge = 1 & max_merge = 1: dejó de postular
        * min_merge = 1 & & max_merge = 2: cambió su postulación completa
        * min_merge = 2 & max_merge = 2: nuevo postulante (no recibió cartilla)
        * min_merge = 1 & max_merge = 3: sacó algunos programas y puede haber agregado o no programas
        * min_merge = 2 & max_merge = 3: agregó postulaciones
        * min_merge = 3 & max_merge = 3: mantuvo su postulación igual

        gen     persona_cambio = 0
        replace persona_cambio = 1 if min_merge == 1 & max_merge == 2
        replace persona_cambio = 1 if min_merge == 1 & max_merge == 3
        replace persona_cambio = 1 if min_merge == 2 & max_merge == 3

        collapse (firstnm) persona_cambio largo_inicial largo_final, by(id_postulante)

        preserve
            foreach x of varlist _all {
                rename `x' `x'_1
            }

            tempfile cambios_1
            save `cambios_1', replace
        restore

        foreach x of varlist _all {
            rename `x' `x'_2
        }

        tempfile cambios_2
        save `cambios_2', replace

        use `base_grande', clear
        merge 1:1 id_postulante_1 using `cambios_1', keep(3) nogen
        merge 1:1 id_postulante_2 using `cambios_2', keep(3) nogen

        // Estadística

            gen     relaciones_con_cambios = 0
            replace relaciones_con_cambios = 1 if persona_cambio_1 == 1 | persona_cambio_2 == 1

            tabstat relaciones_con_cambios, by(abrio_cartilla)

            gen relaciones_con_cambios_abre     = relaciones_con_cambios * 100 if abrio_cartilla == 100
            gen relaciones_con_cambios_noabre   = relaciones_con_cambios * 100 if abrio_cartilla == 0

            graph bar (mean) relaciones_con_cambios_abre relaciones_con_cambios_noabre, ytitle("Porcentaje del total") ///
            bar(1, color(purple%70)) bar(2, color(red%70)) title("Relaciones que ven cambios en sus postulaciones") ///
            legend(order(1 "Abrió cartilla" 2 "No abrió cartilla")) 

            gen mayor_cambio_abre   = persona_cambio_1 * 100  if abrio_cartilla == 100
            gen mayor_cambio_noabre = persona_cambio_1 * 100  if abrio_cartilla == 0

            gen menor_cambio_abre   = persona_cambio_2 * 100  if abrio_cartilla == 100
            gen menor_cambio_noabre = persona_cambio_2 * 100  if abrio_cartilla == 0

            graph bar (mean) mayor_cambio_abre mayor_cambio_noabre, ytitle("Porcentaje del total") ///
            bar(1, color(purple%70)) bar(2, color(red%70)) title("Mayor cambia sus postulaciones") ///
            legend(order(1 "Abrió post. fam." 2 "No abrió")) name(mayor,replace)

            graph bar (mean) menor_cambio_abre menor_cambio_noabre, ytitle("Porcentaje del total") ///
            bar(1, color(purple%70)) bar(2, color(red%70)) title("Menor cambia sus postulaciones") ///
            legend(off) name(menor,replace)

            grc1leg mayor menor

    // Largo postulaciones

        gen     mayor_cambio_largo = 1 if largo_final_1 > largo_inicial_1 
        replace mayor_cambio_largo = 2 if largo_final_1 == largo_inicial_1 
        replace mayor_cambio_largo = 3 if largo_final_1 < largo_inicial_1 
        replace mayor_cambio_largo = . if largo_final_1 == . | largo_inicial_1 == .

        gen     menor_cambio_largo = 1 if largo_final_2 > largo_inicial_2
        replace menor_cambio_largo = 2 if largo_final_2 == largo_inicial_2 
        replace menor_cambio_largo = 3 if largo_final_2 < largo_inicial_2 
        replace menor_cambio_largo = . if largo_final_2 == . | largo_inicial_2 == .

        label def cambio_largo 1 "Aumenta" 2 "Mantiene" 3 "Disminuye"
        label values mayor_cambio_largo cambio_largo
        label values menor_cambio_largo cambio_largo

        graph bar (percent) aux_vio_cartilla aux_no_vio_cartilla,  ///
        over(mayor_cambio_largo) ytitle("Porcentaje") bar(1, color(purple%70)) bar(2, color(red%70)) legend(order(1 "Abrió post. fam." 2 "No abrió")) ///
        title("Cambios en el largo de la lista") subtitle("Hermano mayor") name(mayor_largo, replace)

        graph bar (percent) aux_vio_cartilla aux_no_vio_cartilla,  ///
        over(menor_cambio_largo) ytitle("Porcentaje") bar(1, color(purple%70)) bar(2, color(red%70)) legend(off) ///
        title("Cambios en el largo de la lista") subtitle("Hermano menor") name(menor_largo, replace)

        grc1leg mayor_largo menor_largo

        gen at_least_one_increase = menor_cambio_largo == 1 | mayor_cambio_largo == 1

        tabstat at_least_one_increase, by(abrio_cartilla)

// ----------------------------------------------------------------
// Colegios postulados en común
// ----------------------------------------------------------------

    gen     tipo_cambio_largo = 1 if n_escuelas_comun_post > n_escuelas_comun_previo 
    replace tipo_cambio_largo = 2 if n_escuelas_comun_post == n_escuelas_comun_previo 
    replace tipo_cambio_largo = 3 if n_escuelas_comun_post < n_escuelas_comun_previo
    replace tipo_cambio_largo = . if n_escuelas_comun_post == . | n_escuelas_comun_previo == .

    label values tipo_cambio_largo cambio_largo

    proportion tipo_cambio_largo, over(abrio_cartilla)

    graph bar (percent) aux_vio_cartilla aux_no_vio_cartilla,  ///
    over(tipo_cambio_largo) ytitle("Porcentaje") bar(1, color(purple%70)) bar(2, color(red%70)) legend(order(1 "Abrió post. fam." 2 "No abrió cartilla")) ///
    title("Cambios en el nº establecimientos postulados en común")

// ----------------------------------------------------------------
// Beliefs
// ----------------------------------------------------------------

    // Probabilidades reales (mostradas en la cartilla)

        preserve

            import delimited "$main_sae/cartillas/cartillas_postulación/1_etapa_regular/4_research_tables/siblings/tabla_auxiliar_eventos.csv", clear

            gen     evento_juntos = 0 
            replace evento_juntos = 1 if n_evento < 5 & rbd_menor == rbd_mayor 
            replace evento_juntos = 1 if n_evento == 5

            keep if evento_juntos == 1

            collapse (sum) prob_conjunta_bloque prob_conjunta_sinbloque (firstnm) postula_en_bloque, by(id_apoderado)
            tempfile probabilidades_reales
            save `probabilidades_reales', replace

        restore 

        merge 1:1 id_apoderado using `probabilidades_reales', keep(3) nogen // a few where _merge = 2, 0 _merge = 1

        replace prob_conjunta_bloque = prob_conjunta_bloque * 100
        replace prob_conjunta_sinbloque = prob_conjunta_sinbloque * 100

        gen     prob_post_ind_post = sibl14_1 if opcion_seleccionada == "postulación individual"
        replace prob_post_ind_post = sibl15_1 if opcion_seleccionada == "postulación familiar"

    // Diferencia de probabilidades (declarada vs real)

        gen ab_dif_real_ind = abs(prob_conjunta_sinbloque - prob_post_ind_post)

        rename sibl17 prob_post_familiar_previo

        gen     prob_post_familiar_post = sibl14_1 if opcion_seleccionada == "postulación familiar"
        replace prob_post_familiar_post = sibl15_1 if opcion_seleccionada == "postulación individual"

        gen ab_dif_real_previo  = abs(prob_conjunta_bloque - prob_post_familiar_previo)
        gen ab_dif_real_post    = abs(prob_conjunta_bloque - prob_post_familiar_post)

    // Gráficos 

        count if ab_dif_real_post != .
        local N `r(N)'
        twoway (kdensity ab_dif_real_post if abrio_cartilla == 0, color(red%70) bwidth(15)) (kdensity ab_dif_real_post if abrio_cartilla == 100, color(purple%70) bwidth(15)),  ///
        legend(order(1 "No vio cartilla" 2 "Vio cartilla")) title("Probabilidad de ser asignados juntos") xtitle("Valor absoluto(Prob. cartilla - prob. auto-reportada)") ///
        subtitle("Usando la postulación familiar") ytitle("Densidad") name(bloque_juntos, replace) note("N = `N'")

        *ksmirnov ab_dif_real_post, by(apertura_cartilla)

        count if ab_dif_real_ind != . 
        local N `r(N)'
        twoway (kdensity ab_dif_real_ind if abrio_cartilla == 0, color(red%70) bwidth(15)) (kdensity ab_dif_real_ind if abrio_cartilla == 100, color(purple%70) bwidth(15)),  ///
        legend(off) title("Probabilidad de ser asignados juntos") xtitle("Valor absoluto(Prob. cartilla - prob. auto-reportada)") ///
        subtitle("Usando la postulación individual") ytitle("Densidad") name(no_bloque_juntos, replace) note("N = `N'")

        *ksmirnov ab_dif_real_ind, by(apertura_cartilla)

        grc1leg bloque_juntos no_bloque_juntos

        twoway (kdensity ab_dif_real_previo, color(red%70) bwidth(15)) (kdensity ab_dif_real_post, color(purple%70) bwidth(15)),  ///
        legend(order(1 "Previo cartilla" 2 "Post cartilla" )) xtitle("Valor absoluto(Prob. cartilla - prob. auto-reportada)") title("Probabilidad de ser asignados juntos") subtitle("Usando la postulación familiar") 

    // Lo que dice la encuesta sobre el rol de la cartilla 

        tab sibl16

// ----------------------------------------------------------------
// Módulo intertemporal
// ----------------------------------------------------------------

    gen     prob_quedar_2022 = quedaron_2022/postularon_2022
    replace prob_quedar_2022 = 1 if postularon_2022 == 0 & quedaron_2022 != 0

    gen prob_quedar_alta = prob_quedar_2022 >= 0.5

    tab prob_quedar_alta if tiene_dinamico == 1

    // encuesta

        tab sibl10_menos

        tab sibl22

        tab sibl23
    
// ----------------------------------------------------------------
// Postula complementario
// ----------------------------------------------------------------
    preserve 
        import delimited "$main_sae/datos_SAE/1_Source/2_Complementario/relaciones/F1_2023-11-25.csv", clear
        drop mismo_nivel es_hermano
        rename postula_en_bloque post_fam_complementario
        tempfile relaciones_complementario
        save `relaciones_complementario', replace 
    restore

    merge 1:1 id_postulante_1 id_postulante_2 using `relaciones_complementario', keep(1 3)

    gen reapply = _merge == 3

    drop _merge

    tabstat reapply, by(abrio_cartilla)
    tabstat post_fam_complementario, by(abrio_cartilla)

// ----------------------------------------------------------------
// Conocimiento del sistema
// ----------------------------------------------------------------

    tab sibl02 if abrio_cartilla == 0
    tab sibl02 if abrio_cartilla == 100
    
    gen aux = 1

    graph bar (sum) aux  if cambia_post_fam == 100 , over(sibl03_a, relabel (1 "Cambia pref. menor" 2 "Cambia pref. mayor" 3 "Automáticamente asignado" 4 "Prioridad hermano estática" 5 "Prioridad hermano dinámica" 6 "No está seguro")) over(abrio_cartilla, relabel(1 "Abrió post. fam." 2 "No abrió")) asyvars percentages ytitle("Porcentaje") blabel(bar, format(%6.0f)) bar(1, color(blue%100)) bar(2, color(blue%70)) bar(3, color(purple%100)) bar(4, color(purple%70)) bar(5, color(red%70)) bar(6, color(red%100))

    *graph bar (sum) aux, over(sibl03_a, relabel (1 "Cambia pref. menor" 2 "Cambia pref. mayor" 3 "Automáticamente asignado" 4 "Prioridad hermano estática" 5 "Prioridad hermano dinámica" 6 "No está seguro")) over(apertura_video, relabel(1 "Vio video" 2 "No vio video")) asyvars percentages ytitle("Porcentaje") blabel(bar, format(%6.0f))