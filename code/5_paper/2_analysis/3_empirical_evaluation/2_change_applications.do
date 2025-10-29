// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Analyze change in family app.
	// Created: April 25, 2024
	// Last Modified: April 25, 2024
	// Author: Javi Gazmuri
// -----------------------------------------------------------------------------

// -------------------------------------------------------------------------
// Change in applications
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

        gen     should = 0
        replace should = 1 if postulacion_familiar_28 == "Familiar (28 ago)" & prob_juntos_fam_cartilla < prob_juntos_ind_cartilla
        replace should = 1 if postulacion_familiar_28 == "Individual (28 ago)" & prob_juntos_fam_cartilla > prob_juntos_ind_cartilla
        replace should = 2 if prob_juntos_fam_cartilla == prob_juntos_ind_cartilla

        label def should_what 0 "Debe mantener" 1 "Debe cambiar" 2 "Indiferente"
        label values should should_what

        gen     change = 0
        replace change = 100 if postulacion_familiar_28 == "Individual (28 ago)" & postulacion_familiar_post == 1
        replace change = 100 if postulacion_familiar_28 == "Familiar (28 ago)" & postulacion_familiar_post == 0

        replace postulacion_familiar_28 = "Individual (previo cartilla)" if postulacion_familiar_28 == "Individual (28 ago)"
        replace postulacion_familiar_28 = "Familiar (previo cartilla)" if postulacion_familiar_28 == "Familiar (28 ago)"

        graph bar change if apertura_post_fam == 1, over(should) over(postulacion_familiar_28) bar(1, color(blue%50)) ytitle("Porcentaje que cambia") blabel(bar, format(%6.1f)) title("Porcentaje de relaciones que cambian entre familiar e individual")

        encode sibl06_menos, gen(sibl06_encode)
        gen strong_for_joint = sibl06_encode == 2 if sibl06_encode != .

        graph bar change if apertura_post_fam == 1 & strong_for_joint == 1, over(should) over(postulacion_familiar_28) bar(1, color(blue%50)) ytitle("Porcentaje que cambia") blabel(bar, format(%6.1f)) title("Porcentaje de relaciones que cambian entre familiar e individual") ///
        subtitle("Grupo con alta preferencia por asignación conjunta")

        gen     change_open = change if apertura_post_fam == 1
        gen     change_not_open = change if apertura_post_fam == 0

        gen     new_should = 1 if should == 0 & postulacion_familiar_28 == "Familiar (previo cartilla)"
        replace new_should = 2 if should == 2 & postulacion_familiar_28 == "Familiar (previo cartilla)"
        replace new_should = 3 if should == 1 & postulacion_familiar_28 == "Individual (previo cartilla)"
        replace new_should = 4 if should == 2 & postulacion_familiar_28 == "Individual (previo cartilla)"

        label def should_v2 1 "Debe mantener" 2 "Indiferente" 3 "Debe cambiar" 4 "Indiferente"
        label values new_should should_v2

        graph bar change_open change_not_open if strong_for_joint == 1, over(should) over(postulacion_familiar_28) bar(1, color(blue%50)) bar(2, color(red%50)) ytitle("Porcentaje que cambia") blabel(bar, format(%6.1f)) title("Porcentaje de relaciones que cambian entre familiar e individual") ///
        subtitle("Grupo con alta preferencia por asignación conjunta") legend(label(1 "Abre cartilla") label(2 "No abre cartilla")) nofill

        tab sibl20_a if apertura_post_fam == 1
        tab sibl20_b if apertura_post_fam == 1

    // Número de colegios postulados en común

        gen     alarga_lista = 0
        replace alarga_lista = 100 if n_escuelas_comun_post > n_escuelas_comun_previo

        tabstat alarga_lista if apertura_post_fam == 1 & strong_for_joint == 1

        graph bar alarga_lista if apertura_post_fam == 1 & strong_for_joint == 1, over(should) over(postulacion_familiar_28) bar(1, color(blue%50)) ytitle("Porcentaje") blabel(bar, format(%6.1f)) title("Porcentaje de relaciones que aumentan a más colegios en común") ///
        subtitle("Grupo con alta preferencia por asignación conjunta")

        gen alarga_lista_open = alarga_lista if apertura_post_fam == 1
        gen alarga_lista_not_open = alarga_lista if apertura_post_fam == 0
        
        tabstat alarga_lista_open alarga_lista_not_open if strong_for_joint == 1
