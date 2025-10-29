// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Analysis of simulations made for Mineduc
	// Created: June 17, 2024
	// Last Modified: June 17, 2024
	// Author: Javi Gazmuri
// -----------------------------------------------------------------------------

// -------------------------------------------------
// Cheking 0 simulation (real) = admin. data 
// -------------------------------------------------

    import delimited "$pathData/intermediate/feedback/2023/mineduc_simulations/2_results/0_simulation.csv", clear 
    keep applicant_id institution_id
    tempfile 0_simulation
    save `0_simulation', replace

    import delimited "$pathData/inputs/SAE_2023/D1_Resultados_etapa_regular_2023_Admisión_2024_PUBL.csv", clear
    keep mrun rbd_admitido 
    destring mrun rbd_admitido, replace 

    rename mrun applicant_id
    merge 1:1 applicant_id using  `0_simulation', nogen // all obs in _merge == 3

    count
    count if rbd_admitido == institution_id // all obs! We are ok!

// -------------------------------------------------
// Data with all the simulations results - siblings
// -------------------------------------------------

    // Relations 

        import delimited "$pathData/inputs/SAE_2023/F1_Relaciones_entre_postulantes_etapa_regular_2023_Admisión_2024_PUBL.csv", clear

    // Paste: school of origin 

        preserve 
            import delimited "$pathData/inputs/SAE_2023/C1_Postulaciones_etapa_regular_2023_Admisión_2024_PUBL.csv", clear
            keep if agregada_por_continuidad == 1
            keep mrun rbd 
            rename rbd rbd_origen 

            rename * *_1 
            tempfile ma_1 
            save `ma_1', replace 

            rename *_1 *_2
            tempfile ma_2 
            save `ma_2', replace 
        restore 

        merge m:1 mrun_1 using `ma_1', keep(1 3) nogen
        merge m:1 mrun_2 using `ma_2', keep(1 3) nogen

    // Paste: level of each sibling 

        preserve 
            import delimited "$pathData/inputs/SAE_2023/B1_Postulantes_etapa_regular_2023_Admisión_2024_PUBL.csv", clear
            keep mrun cod_nivel

            rename * *_1 
            tempfile nivel_1 
            save `nivel_1', replace 

            rename *_1 *_2
            tempfile nivel_2 
            save `nivel_2', replace 
        restore 

        merge m:1 mrun_1 using `nivel_1', keep(1 3) nogen
        merge m:1 mrun_2 using `nivel_2', keep(1 3) nogen

    // Paste: simulation assignments

        forvalues x = 0/3 {
        
            preserve 

                import delimited "$pathData/intermediate/feedback/2023/mineduc_simulations/1_tables_simulation_format/`x'_simulation/applications.csv", clear 
                keep applicant_id institution_id program_id ranking_program
                duplicates drop 

                tempfile ranking_preferences
                save `ranking_preferences', replace

                import delimited "$pathData/intermediate/feedback/2023/mineduc_simulations/2_results/`x'_simulation.csv", clear 
                keep applicant_id institution_id program_id
                merge 1:1 applicant_id institution_id program_id using `ranking_preferences', keep(1 3) nogen // _merge = 1 are not assigned
                drop program_id
        
                rename applicant_id mrun
                rename institution_id rbd_sim`x'
                rename ranking_program ranking_sim`x'

                rename * *_1
                tempfile sim`x'_1 
                save `sim`x'_1', replace 

                rename *_1 *_2
                tempfile sim`x'_2 
                save `sim`x'_2', replace

            restore 

            merge m:1 mrun_1 using `sim`x'_1', keep(3) nogen // all _merge = 3
            merge m:1 mrun_2 using `sim`x'_2', keep(3) nogen // all _merge = 3
        }

    // Analysis 

        // Reshape to separate different simulations

            reshape long rbd_sim@_1 rbd_sim@_2 ranking_sim@_1 ranking_sim@_2, i(mrun_1 mrun_2) j(simulation)

        // Variables

            gen both_assigned = rbd_sim_1 != . & rbd_sim_2 != .
            gen assigned_together = rbd_sim_1 == rbd_sim_2 & rbd_sim_1 != . 
            gen same_ma = rbd_origen_1 == rbd_origen_2 & rbd_origen_1 != .
            gen assigned_together_ma = rbd_sim_1 == rbd_sim_2 & rbd_origen_1 == rbd_origen_2 & rbd_sim_1 == rbd_origen_1 & rbd_sim_1 != .
            gen assigned_together_first_pref = assigned_together == 1 & ranking_sim_1 == 1 & ranking_sim_2 == 1

            gen entry_level_old     = cod_nivel_1 == -1 | cod_nivel_1 == 1 | cod_nivel_1 == 7 | cod_nivel_1 == 9
            gen entry_level_young   = cod_nivel_2 == -1 | cod_nivel_2 == 1 | cod_nivel_2 == 7 | cod_nivel_2 == 9

        // Stats

            tabstat entry_level_young entry_level_old if simulation == 0

            tabstat both_assigned assigned_together assigned_together_ma assigned_together_first_pref ranking_sim_1 ranking_sim_2, stat(mean N) by(simulation)

            // Turn off fam. app. for the subgroup: checking the subgroup 

                tabstat both_assigned assigned_together assigned_together_ma ranking_sim_1 ranking_sim_2 if (simulation == 0 | simulation == 2) & same_ma == 1, stat(mean N) by(simulation)

            // Inverted order: checking those with fam. app. originally 

                tabstat both_assigned assigned_together assigned_together_ma assigned_together_first_pref ranking_sim_1 ranking_sim_2 if postula_en_bloque == 1 & (simulation == 0 | simulation == 3), stat(mean N) by(simulation)
    
// -------------------------------------------------------
// Data with all the simulations results - with no siblings
// -------------------------------------------------------

    // Applicants

        import delimited "$pathData/inputs/SAE_2023/B1_Postulantes_etapa_regular_2023_Admisión_2024_PUBL.csv", clear
        keep mrun 

    // Filter: those with no siblings 

        preserve 

            import delimited "$pathData/inputs/SAE_2023/F1_Relaciones_entre_postulantes_etapa_regular_2023_Admisión_2024_PUBL.csv", clear
            
            keep mrun_* 
            gen aux = _n 

            reshape long mrun_@, i(aux) j(hermanos)
            rename mrun_ mrun 
            keep mrun
            duplicates drop 

            tempfile siblings 
            save `siblings', replace 
        
        restore 

        merge 1:1 mrun using `siblings', keep(1) nogen

    // Paste: school of origin 

        preserve 
            import delimited "$pathData/inputs/SAE_2023/C1_Postulaciones_etapa_regular_2023_Admisión_2024_PUBL.csv", clear
            keep if agregada_por_continuidad == 1
            keep mrun rbd 
            rename rbd rbd_origen 

            tempfile ma 
            save `ma', replace
        restore 

        merge 1:1 mrun using `ma', keep(1 3) nogen

    // Paste: simulation assignments

        forvalues x = 0/3 {
        
            preserve 

                import delimited "$pathData/intermediate/feedback/2023/mineduc_simulations/1_tables_simulation_format/`x'_simulation/applications.csv", clear 
                keep applicant_id institution_id program_id ranking_program
                duplicates drop 

                tempfile ranking_preferences
                save `ranking_preferences', replace

                import delimited "$pathData/intermediate/feedback/2023/mineduc_simulations/2_results/`x'_simulation.csv", clear 
                keep applicant_id institution_id program_id
                merge 1:1 applicant_id institution_id program_id using `ranking_preferences', keep(1 3) nogen // _merge = 1 are not assigned
                drop program_id
        
                rename applicant_id mrun
                rename institution_id rbd_sim`x'
                rename ranking_program ranking_sim`x'

                tempfile sim`x'
                save `sim`x'', replace 

            restore 

            merge 1:1 mrun using `sim`x'', keep(3) nogen
        }

    // Analysis 

        // Reshape to separate different simulations

            reshape long rbd_sim@ ranking_sim@, i(mrun) j(simulation)

        // Variables

            gen assigned = rbd_sim != .
            gen assigned_ma = rbd_sim == rbd_origen & rbd_sim != . 

        // Stats

            tabstat assigned assigned_ma ranking_sim, stat(mean N) by(simulation)



