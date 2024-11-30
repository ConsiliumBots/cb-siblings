        
// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Create a long-format database for a potential DID
	// Created: Jun 3, 2024
	// Last Modified: Jun 11, 2024
	// Author: Javi Gazmuri
// -----------------------------------------------------------------------------

    import delimited "$pathData/intermediate/feedback/2023/clean_data/consolidated_data_reg.csv", clear
    tempfile consolidated_data_reg
    save `consolidated_data_reg', replace

    keep id_postulante_1 id_postulante_2

    global dates "08-09 08-10 08-14 08-16 08-17 08-18 08-21 08-22 08-23 08-24 08-25 08-27 08-28 08-29 08-30 08-31 09-01 09-02 09-03 09-04 09-05 09-20"

// ----------------------------------------------------------------
// Daily relationships + applications data
// ----------------------------------------------------------------
    
    foreach date of global dates {

        preserve 
            import delimited "$main_sae/datos_SAE/1_Source/1_Principal/relaciones/F1_2023-`date'", clear

            local new_date `date'
            local new_date: subinstr local new_date "-" "_", all

            gen fam_app_`new_date' = postula_en_bloque 

            keep id_postulante_1 id_postulante_2 fam_app_`new_date'
            tempfile relations
            save `relations', replace

            import delimited "$main_sae/datos_SAE/1_Source/1_Principal/postulaciones/datos_jpal_2023-`date'", clear

            keep id_postulante rbd
            duplicates drop

            rename id_postulante id_postulante_1
            tempfile app_1 
            save `app_1', replace 

            rename id_postulante_1 id_postulante_2
            tempfile app_2 
            save `app_2', replace 
 
            use `relations', clear
            joinby id_postulante_1 using `app_1' 
            merge m:1 id_postulante_2 rbd using `app_2', keep(1 3)

            bys id_postulante_1 id_postulante_2: egen schools_comun_`new_date' = sum(_merge == 3)
            drop _merge rbd
            duplicates drop 
            unique id_postulante_1 

            tempfile daily_data
            save `daily_data', replace

        restore 

        merge 1:1 id_postulante_1 id_postulante_2 using `daily_data', keep(1 3) nogen
    }

    // Making the reshape 

        reshape long fam_app_ schools_comun_, i(id_postulante_1 id_postulante_2) j(app_date) string
        
        rename fam_app_ fam_app
        rename schools_comun_ schools_comun

        tempfile long_data 
        save `long_data', replace

// ----------------------------------------------------------------
// Simulations (assignments) data 
// ----------------------------------------------------------------

    foreach date of global dates {

        // Data 

            import delimited "$pathData/intermediate/feedback/2023/daily_simulations/2_tables_simulation_format/applicants_`date'", clear
            tempfile applicants
            save `applicants', replace

            import delimited "$pathData/intermediate/feedback/2023/daily_simulations/1_tables_public_format/crosswalk_id_mrun_`date'", clear
            rename mrun applicant_id
            tempfile crosswalk
            save `crosswalk', replace 

            import delimited "$pathData/intermediate/feedback/2023/daily_simulations/3_results/results_`date'", clear

        // Secure enrollment 

            merge m:1 applicant_id using `applicants', nogen // all obs _merge = 3

            gen     mat_asegurada = 0
            replace mat_asegurada = 1 if program_id == secured_enrollment_program_id

            keep applicant_id institution_id mat_asegurada

        // Indicator assigned

            rename institution_id rbd

            gen assigned = rbd != .

        // Real applicant id 

            merge m:1 applicant_id using `crosswalk', nogen // all obs _merge = 3
            drop applicant_id
        
        // Time var. 

            local new_date `date'
            local new_date: subinstr local new_date "-" "_", all

            gen app_date = "`new_date'"
        
        tempfile data_`new_date'
        save `data_`new_date'', replace 
    }

    use `data_08_09', clear 
    append using `data_08_10' `data_08_14' `data_08_16' `data_08_17' `data_08_18' `data_08_21' `data_08_22' `data_08_23' `data_08_24' `data_08_25' `data_08_27' `data_08_28' `data_08_29' `data_08_30' `data_08_31' `data_09_01' `data_09_02' `data_09_03' `data_09_04' `data_09_05' `data_09_20'               

    rename * *_1
    rename app_date_1 app_date

    tempfile assignments_1 
    save `assignments_1', replace 

    rename *_1 *_2 
    tempfile assignments_2 
    save `assignments_2', replace 

    // Merge with rest of the data 

        use `long_data', clear
        merge 1:1 id_postulante_1 app_date using `assignments_1', keep(1 3) nogen
        merge 1:1 id_postulante_2 app_date using `assignments_2', keep(1 3) nogen

// ----------------------------------------------------------------
// Other info and cleaning
// ----------------------------------------------------------------

    // Format date 

        replace app_date = app_date + "_2023"

        gen numdate = date(app_date, "MDY")
        format numdate %td
        drop app_date

    // Pasting consolidated data 

        merge m:1 id_postulante_1 id_postulante_2 using `consolidated_data_reg', nogen

    // Information to create treatment and control groups 

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

        merge m:1 id_apoderado using `probabilidades_cartilla', keep(3) nogen // a few where _merge = 2, 0 _merge = 1

        replace prob_juntos_fam_cartilla = prob_juntos_fam_cartilla * 100
        replace prob_juntos_ind_cartilla = prob_juntos_ind_cartilla * 100

        gen     should = 0
        replace should = 1 if postulacion_familiar_28 == "Familiar (28 ago)" & prob_juntos_fam_cartilla < prob_juntos_ind_cartilla
        replace should = 1 if postulacion_familiar_28 == "Individual (28 ago)" & prob_juntos_fam_cartilla > prob_juntos_ind_cartilla
        replace should = 2 if prob_juntos_fam_cartilla == prob_juntos_ind_cartilla

        label def should_what 0 "Debe mantener" 1 "Debe cambiar" 2 "Indiferente"
        label values should should_what

// Export 

    export delimited "$pathData/intermediate/feedback/2023/clean_data/long_data_reg.csv", replace
