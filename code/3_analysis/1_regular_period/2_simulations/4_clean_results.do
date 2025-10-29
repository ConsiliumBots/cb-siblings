// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Clean simulation results and consolidate the data 
	// Created: Nov 16, 2023
	// Last Modified: Feb 2, 2024
	// Author: Javi Gazmuri
// -----------------------------------------------------------------------------

// ---------------------------------------------- //
// --------------------- DATA ------------------- //
// ---------------------------------------------- //

    // Data pre-feedback

        import delimited "$pathData/intermediate/feedback/2023/jpal_to_public_data/pre_feedback/crosswalk_id_mrun.csv", clear
        rename mrun applicant_id
        tempfile pre_crosswalk
        save `pre_crosswalk', replace 

        import delimited "$pathData/intermediate/feedback/2023/jpal_to_public_data/pre_feedback/applicants.csv", clear 
        tempfile pre_postulantes
        save `pre_postulantes', replace 

        import delimited "$pathData/outputs/feedback_simulations/pre_feedback/results.csv", clear 
        tempfile pre_results
        save `pre_results', replace 

    // Data post-feedback

        import delimited "$pathData/intermediate/feedback/2023/jpal_to_public_data/post_feedback/crosswalk_id_mrun.csv", clear
        rename mrun applicant_id
        tempfile post_crosswalk
        save `post_crosswalk', replace 

        import delimited "$pathData/intermediate/feedback/2023/jpal_to_public_data/post_feedback/applicants.csv", clear 
        tempfile post_postulantes
        save `post_postulantes', replace 

        import delimited "$pathData/outputs/feedback_simulations/post_feedback/results.csv", clear 
        tempfile post_results
        save `post_results', replace 

    // Consolidated data

        import delimited "$pathData/intermediate/feedback/2023/clean_data/consolidated_data_reg.csv", clear
        tempfile data_consolidated
        save `data_consolidated', replace 

// ---------------------------------------------- //
// -------------------- CLEAN ------------------- //
// ---------------------------------------------- //

    // -------------------------
    // Pre-feedback
    // -------------------------

        use `pre_results', clear 

        drop quota_id

        gen pre_prob_assignment = n_assigned/100

        // Prob. non assignment 

            bys applicant_id: egen sum_prob = sum(pre_prob_assignment)
            gen pre_prob_non_assignment = 1 - sum_prob
            drop sum_prob

        // Secure enrollment 

            merge m:1 applicant_id using `pre_postulantes', nogen // all obs _merge = 3

            gen     mat_asegurada = 0
            replace mat_asegurada = 1 if program_id == secured_enrollment_program_id

            drop priority_profile_program priority_number_quota n_assigned applicant_characteristic_1 special_assignment secured_enrollment_program_id secured_enrollment_quota_id 
            rename ranking_program pre_ranking

        // Real applicant id 

            merge m:1 applicant_id using `pre_crosswalk', nogen // all obs _merge = 3
            drop applicant_id
            tempfile pre_simulation
            save `pre_simulation', replace

    // -------------------------
    // Post-feedback
    // -------------------------

        use `post_results', clear 

        drop quota_id

        gen post_prob_assignment = n_assigned/100

        // Prob. non assignment 

            bys applicant_id: egen sum_prob = sum(post_prob_assignment)
            gen post_prob_non_assignment = 1 - sum_prob
            drop sum_prob

        // Secure enrollment 

            merge m:1 applicant_id using `post_postulantes', nogen // all obs _merge = 3

            gen     mat_asegurada = 0
            replace mat_asegurada = 1 if program_id == secured_enrollment_program_id

            drop priority_profile_program priority_number_quota n_assigned applicant_characteristic_1 special_assignment secured_enrollment_program_id secured_enrollment_quota_id
            rename ranking_program post_ranking

        // Real applicant id 

            merge m:1 applicant_id using `post_crosswalk', nogen // all obs _merge = 3
            drop applicant_id
            tempfile post_simulation
            save `post_simulation', replace

    // -------------------------
    // Merge
    // -------------------------

        use `pre_simulation', clear 
        merge 1:1 id_postulante institution_id program_id using `post_simulation', nogen
        tempfile simulations
        save `simulations', replace

        use `data_consolidated', clear 

        // Checking if all obs have a simulation

            preserve 
                rename id_postulante_1 id_postulante
                merge 1:m id_postulante using `simulations', keep(1 3) // 0 obs in _merge = 1. We are ok!
            restore

            preserve
                rename id_postulante_2 id_postulante
                merge 1:m id_postulante using `simulations', keep(1 3) // 0 obs in _merge = 1. We are ok!
            restore

        // Merging with simulations

            rename id_postulante_1 id_postulante
            merge 1:m id_postulante using `simulations', keep(3) nogen

            foreach var in id_postulante grade_id institution_id program_id mat_asegurada pre_ranking post_ranking pre_prob_assignment post_prob_assignment pre_prob_non_assignment post_prob_non_assignment {
                rename `var' `var'_1
            }

            rename id_postulante_2 id_postulante

            joinby id_postulante using `simulations'

            foreach var in id_postulante grade_id institution_id program_id mat_asegurada pre_ranking post_ranking pre_prob_assignment post_prob_assignment pre_prob_non_assignment post_prob_non_assignment {
                rename `var' `var'_2
            }

            rename institution_id_1 rbd_1 
            rename institution_id_2 rbd_2

    // -------------------------
    // Export
    // -------------------------

        export delimited "$pathData/intermediate/feedback/2023/data_simulations_reg.csv", replace


