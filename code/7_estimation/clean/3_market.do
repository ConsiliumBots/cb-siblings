// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: All programs in the market with covariates.
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
// All programs for younger and older siblings
// ----------------------------------------------------------------

    // Load program characteristics
    import delimited "$main_sae/cartillas/cartillas_postulación/1_etapa_regular/4_research_tables/oferta/options_feedback_2023_08_28.csv", clear stringcols(_all)
    keep rbd cod_curso name sch_lon sch_lat quality_category
    rename name school_name
    replace school_name = lower(school_name)
    
    // Convert numeric variables back to numeric
    destring rbd sch_lon sch_lat quality_category, replace

    // Obtain cod_ense (now cod_curso is a string)
    gen cod_ense = substr(cod_curso, 2, 3)
    destring cod_ense, replace  

    // Collapse by rbd (keep first entrance)
    bysort rbd cod_ense (cod_curso): gen first = _n == 1
    keep if first
    drop first cod_curso
    
    tempfile all_programs
    save `all_programs', replace
    
    // Load sibling IDs and locations
    import delimited "$pathData/survey_responses.csv", clear
    keep id_apoderado id_mayor id_menor
    
    tempfile sibling_ids
    save `sibling_ids', replace
    
    // Get younger sibling locations
    import delimited "$main_sae/cartillas/cartillas_postulación/1_etapa_regular/4_research_tables/applications/datos_jpal/datos_jpal_2023_09_20.csv", clear stringcols(_all)
    keep id_postulante latitud longitud cod_curso

    // Convert numeric variables back to numeric
    destring id_postulante latitud longitud, replace

    // Obtain cod_ense (now cod_curso is a string)
    gen cod_ense = substr(cod_curso, 2, 3)
    destring cod_ense, replace

    duplicates drop

    bys id_postulante: egen sd_cod_ense = sd(cod_ense) // 94% have sd = 0. Warning for that 6%. 
    bys id_postulante: gen first = _n == 1
    keep if first
    drop first cod_curso sd_cod_ense

    rename id_postulante id_menor
    rename latitud lat_younger
    rename longitud lon_younger
    
    tempfile younger_locations
    save `younger_locations', replace
    
    // Get older sibling locations
    rename *_younger *_older
    rename id_menor id_mayor

    tempfile older_locations
    save `older_locations', replace
    
    // ----------------------------------------------------------------
    // All programs for YOUNGER sibling
    // ----------------------------------------------------------------
    
    use `sibling_ids', clear
    merge m:1 id_menor using `younger_locations', keep(3) nogen
    
    // Join with all programs matching the same cod_ense
    joinby cod_ense using `all_programs', unmatched(master)
    drop _merge
    
    // Calculate distance from younger sibling location to each school
    geodist lat_younger lon_younger sch_lat sch_lon, gen(dist_km)
    
    // Clean up
    drop lat_younger lon_younger sch_lat sch_lon id_mayor
    rename quality_category qual
    
    // Export
    export delimited "$pathData/all_programs_younger.csv", replace
    
    // ----------------------------------------------------------------
    // All programs for OLDER sibling
    // ----------------------------------------------------------------
    
    use `sibling_ids', clear
    merge m:1 id_mayor using `older_locations', keep(3) nogen
    
    // Join with all programs matching the same cod_ense
    joinby cod_ense using `all_programs', unmatched(master)
    drop _merge
    
    // Calculate distance from older sibling location to each school
    geodist lat_older lon_older sch_lat sch_lon, gen(dist_km)
    
    // Clean up
    drop lat_older lon_older sch_lat sch_lon id_menor
    rename quality_category qual
    
    // Export
    export delimited "$pathData/all_programs_older.csv", replace

