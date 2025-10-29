// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Analyze simulations (compare pre with post-feedback)
	// Created: Feb 2, 2024
	// Last Modified: Feb 5, 2024
	// Author: Javi Gazmuri
// -----------------------------------------------------------------------------

    import delimited "$pathData/intermediate/feedback/2023/data_simulations_reg.csv", clear encoding("utf-8")
    tempfile data_simulations 
    save `data_simulations', replace 


    import delimited "$pathData/intermediate/feedback/2023/clean_data/consolidated_data_reg.csv", clear
    merge 1:m id_apoderado using `data_simulations', nogen 

// ---------------------------------------------- //
// ------------------ STATISTICS ---------------- //
// ---------------------------------------------- //

    gen abrio_cartilla = apertura_post_fam * 100

    // Assigned together 

        gen     together = 0
        replace together = 1 if rbd_1 == rbd_2
        
        foreach x in pre post {
            gen `x'_prob_joint      = `x'_prob_assignment_1 * `x'_prob_assignment_2
            gen `x'_prob_juntos     = `x'_prob_joint                                    if together == 1        
            gen `x'_prob_juntos_ma  = `x'_prob_joint                                    if together == 1 & mat_asegurada_1 == 1 & mat_asegurada_2 == 1
        }

    // Together, not in first preference 

        foreach x in pre post {

            gen     `x'_together_1_1 = together * (`x'_ranking_1 == 1) * (`x'_ranking_2 == 1)

            gen     `x'_prob_juntos_not1 = `x'_prob_juntos 
            replace `x'_prob_juntos_not1 = .                if `x'_together_1_1 == 1
        }

    // Younger assigned to the MA 

        foreach x in pre post {
            *bys id_postulante_2 `x'_ranking_2: gen `x'_auxiliar = _n
            
            gen `x'_prob_menor_ma = `x'_prob_assignment_2 if mat_asegurada_2 == 1
        }

    // Most prefered common school

        gen number_school_joint = substr(sibl04_1,-2,1)
        destring number_school_joint, replace 

        gen comun_mas_preferido = ""

        forvalues x = 1/6 {
            replace comun_mas_preferido = schjoint0`x' if number_school_joint == `x'
        }

        preserve 
			import delimited "$main_sae/datos_SAE/1_Source/1_Principal/oferta/oferta_jpal_j_2023-08-22.csv", clear encoding("utf-8")
            keep rbd establecimiento
            duplicates drop
            bys establecimiento: gen aux = _n
            rename rbd rbd_pref_

            reshape wide rbd, i(establecimiento) j(aux)
			gen comun_mas_preferido = ustrtitle(establecimiento)
            drop establecimiento
            
            tempfile nombre_colegios
            save `nombre_colegios', replace
        restore

        merge m:1 comun_mas_preferido using `nombre_colegios', keep(1 3)
        tab comun_mas_preferido if _merge == 1 // no obs. We are ok!

        gen most_prefered = 0

        forvalues x = 1/18 {
            replace most_prefered = 1 if most_prefered == 0 & rbd_pref_`x' == rbd_1 & rbd_pref_`x' == rbd_2
        }

        foreach x in pre post {
            gen `x'_prob_most_pref = `x'_prob_joint if most_prefered == 1            
        }

        gen     en_encuesta = 0
        replace en_encuesta = 1 if sibl04_1 != ""

    // Collapsing data 

        collapse (sum) together pre_together_1_1 post_together_1_1 pre_prob_juntos post_prob_juntos pre_prob_menor_ma post_prob_menor_ma pre_prob_juntos_ma post_prob_juntos_ma pre_prob_most_pref post_prob_most_pref pre_prob_juntos_not1 post_prob_juntos_not1 (max) mat_asegurada_2 en_encuesta (firstnm) n_escuelas_comun_previo n_escuelas_comun_post abrio_cartilla postulacion_familiar_28 postulacion_familiar_post id_postulante_1 id_postulante_2 sibl06_menos, by(id_apoderado)


        foreach x in pre post {
            replace `x'_prob_juntos = .         if together == 0

            replace `x'_prob_juntos_not1 = .    if together == 0
            replace `x'_prob_juntos_not1 = .    if together == 1 & `x'_together_1_1 == 1

            replace `x'_prob_menor_ma = .       if mat_asegurada_2 == 0

            replace `x'_prob_most_pref = .      if together == 0
            replace `x'_prob_most_pref = .      if en_encuesta == 0
        }

    // Probabilidades reales (mostradas en la cartilla)

        preserve

            import delimited "$main_sae/cartillas/cartillas_postulación/1_etapa_regular/4_research_tables/siblings/tabla_auxiliar_eventos.csv", clear

            gen     evento_juntos = 0 
            replace evento_juntos = 1 if n_evento < 5 & rbd_menor == rbd_mayor 
            replace evento_juntos = 1 if n_evento == 5

            gen     evento_ma = regexm(evento,"mat_aseg")

            keep if evento_juntos == 1 & evento_ma == 0

            rename (prob_conjunta_bloque prob_conjunta_sinbloque) (prob_juntos_fam_cartilla prob_juntos_ind_cartilla)

            collapse (sum) prob_juntos_fam_cartilla prob_juntos_ind_cartilla, by(id_apoderado)
            tempfile prob_juntos_cartilla
            save `prob_juntos_cartilla', replace

            import delimited "$main_sae/cartillas/cartillas_postulación/1_etapa_regular/4_research_tables/siblings/tabla_auxiliar_eventos.csv", clear

            gen     juntos_ambos_ma = evento == "mat_aseg:mat_aseg" & rbd_menor == rbd_mayor

            keep if juntos_ambos_ma == 1

            rename (prob_conjunta_bloque prob_conjunta_sinbloque) (prob_juntos_ma_fam_cartilla prob_juntos_ma_ind_cartilla)
            collapse (sum) prob_juntos_ma_fam_cartilla prob_juntos_ma_ind_cartilla, by(id_apoderado)
            tempfile prob_juntos_ma_cartilla
            save `prob_juntos_ma_cartilla', replace



        restore 

        merge 1:1 id_apoderado using `prob_juntos_cartilla', keep(1 3) nogen // a few where _merge = 2, 0 _merge = 1
        merge 1:1 id_apoderado using `prob_juntos_ma_cartilla', keep(1 3) nogen
    // Other vars

        foreach var in prob_juntos_fam_cartilla prob_juntos_ind_cartilla prob_juntos_ma_fam_cartilla prob_juntos_ma_ind_cartilla {
            replace `var' = `var' * 100
        }

        gen     should = 0
        replace should = 1 if postulacion_familiar_28 == "Familiar (28 ago)" & prob_juntos_fam_cartilla < prob_juntos_ind_cartilla
        replace should = 1 if postulacion_familiar_28 == "Individual (28 ago)" & prob_juntos_fam_cartilla > prob_juntos_ind_cartilla
        replace should = 2 if prob_juntos_fam_cartilla == prob_juntos_ind_cartilla

        label def should_what 0 "Debe mantener" 1 "Debe cambiar" 2 "Indiferente"
        label values should should_what

        gen     should_ma = 0
        replace should_ma = 1 if postulacion_familiar_28 == "Familiar (28 ago)" & prob_juntos_ma_fam_cartilla > 25 & prob_juntos_ma_fam_cartilla != .

        gen     change = 0
        replace change = 100 if postulacion_familiar_28 == "Individual (28 ago)" & postulacion_familiar_post == 1
        replace change = 100 if postulacion_familiar_28 == "Familiar (28 ago)" & postulacion_familiar_post == 0

        encode sibl06_menos, gen(sibl06_encode)
        gen strong_for_joint = sibl06_encode == 2 if sibl06_encode != .

    // Regressions 

        reg post_prob_juntos i.change if should == 1 & abrio_cartilla == 100
        reg post_prob_juntos i.change pre_prob_juntos if should == 1 & abrio_cartilla == 100

        reg post_prob_menor_ma i.change if should == 1 & abrio_cartilla == 100
        reg post_prob_menor_ma i.change pre_prob_menor_ma if should == 1 & abrio_cartilla == 100
     
        reg post_prob_most_pref i.change if should == 1 & abrio_cartilla == 100
        reg post_prob_most_pref i.change pre_prob_most_pref if should == 1 & abrio_cartilla == 100

        reg post_prob_juntos_ma i.change if should_ma == 1 & abrio_cartilla == 100
        reg post_prob_juntos_ma i.change pre_prob_juntos_ma if should_ma == 1 & abrio_cartilla == 100
