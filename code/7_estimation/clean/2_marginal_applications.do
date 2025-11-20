// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Put covariates in marginal applications 
	// Created: Nov 2025
	// Last Modified: Nov 2025
	// Author: Javi Gazmuri

// -----------------------------------------------------------------------------

// ----------------------------------------------------------------
// Paths
// ----------------------------------------------------------------

	if "`c(username)'"=="javieragazmuri" { // Javiera
		global main_silings =  "/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings"
		global main_sae =  "/Users/javieragazmuri/Library/CloudStorage/Dropbox-ConsiliumBots/ConsiliumBots/Projects/Chile/ChileSAE/SAE 2023"
	    global pathGit = "/Users/javieragazmuri/Documents/GitHub/cb-siblings"
		global pathData = "/Users/javieragazmuri/Library/CloudStorage/Dropbox-Personal/Siblings/data"

	}

// ----------------------------------------------------------------
// Marginal applications
// ----------------------------------------------------------------

    // Program characteristics

        import delimited "$main_sae/cartillas/cartillas_postulación/1_etapa_regular/4_research_tables/oferta/options_feedback_2023_08_28.csv", clear
        keep rbd cod_curso name sch_lon sch_lat quality_category quality_category_label
        rename name school_name
        replace school_name = lower(school_name)

        tempfile programs
        save `programs', replace

    // Applications data

        import delimited "$main_sae/cartillas/cartillas_postulación/1_etapa_regular/4_research_tables/applications/datos_jpal/datos_jpal_2023_09_20.csv", clear
        keep id_apoderado id_postulante rbd cod_curso latitud longitud orden
        merge m:1 rbd cod_curso using `programs', keep(1 3) nogen // All merge

        collapse (min) sch_lon_min = sch_lon sch_lat_min = sch_lat qual_min = quality_category rbd_min = rbd orden_min = orden (max) sch_lon_max = sch_lon sch_lat_max = sch_lat qual_max = quality_category rbd_max = rbd orden_max = orden latitud longitud, by(id_apoderado id_postulante school_name)
        count if sch_lat_max != sch_lat_min // 0.2%
        count if sch_lon_max != sch_lon_min // 0.2%
        count if qual_max != qual_min // 0.01%
        count if rbd_max != rbd_min // 0.01%
        
        count if orden_max != orden_min // 2.13% -> we will keep min orden
        rename orden_min orden
        drop orden_max 

        // For now, we will keep with max
        drop *_min 
        rename *_max *

    // Calculate distance

        geodist sch_lat sch_lon latitud longitud, gen(dist_km) 
        drop sch_lat sch_lon latitud longitud

    // Save in tempfile 

        tempfile applications_marginal
        save `applications_marginal', replace
// ----------------------------------------------------------------
// Database for older sibling
// ----------------------------------------------------------------

    preserve 
        import delimited "$pathData/survey_responses.csv", clear
        keep id_apoderado id_mayor id_menor
        tempfile survey_ids
        save `survey_ids', replace
    restore

    rename id_postulante id_mayor
    merge m:1 id_apoderado id_mayor using `survey_ids', keep(2 3) nogen // all merge
    drop id_menor 

    export delimited "$pathData/marginal_applications_older.csv", replace

    use `applications_marginal', clear
    rename id_postulante id_menor
    merge m:1 id_apoderado id_menor using `survey_ids', keep(2 3) nogen // all merge
    drop id_mayor

    export delimited "$pathData/marginal_applications_younger.csv", replace