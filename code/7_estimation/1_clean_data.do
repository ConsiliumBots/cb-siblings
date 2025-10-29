// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Paths
	// Created: Oct 2025
	// Last Modified: Oct 2025
	// Author: Javi Gazmuri

// -----------------------------------------------------------------------------

// ----------------------------------------------------------------
// Paths
// ----------------------------------------------------------------

	if "`c(username)'"=="javieragazmuri" { // Javiera
		global main_silings =  "/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings"
		global main_sae =  "/Users/javieragazmuri/Library/CloudStorage/Dropbox-ConsiliumBots/ConsiliumBots/Projects/Chile/ChileSAE/SAE 2023"
	    global pathGit = "/Users/javieragazmuri/Documents/GitHub/cb-siblings"

	}

// ----------------------------------------------------------------
// Cleaning of survey data 
// ----------------------------------------------------------------

    import delimited "$main_sae/encuesta/outputs/responses/SAE_survey_2023_responses_Full_sample.csv", clear 
    keep if ensibling == 1
    drop if id_apoderado == "" // 2 obs
    drop if sibl04_1 == "" // Didn't answered the questions. 3,716 obs.
    keep id_apoderado cant_common_rbd opcion_seleccionada sibl04_1 sibl04_2 sibl05_menor sibl05_mayor sibl06_menos sibl06_mas schjoint* schmenor* schmayor*
    tempfile survey_responses
    save `survey_responses', replace

// ----------------------------------------------------------------
// ID siblings + Full list of joint (and individual) schools from dropdown verification
// ----------------------------------------------------------------

    // Joint schools (dropdown has >= info)

        import delimited "$main_sae/encuesta/inputs/seccion_hermanos/dropdown_rbd_comun_encoded.csv", clear
        drop if orden > 10
        keep id_apoderado orden establecimiento
        rename establecimiento schjoint0

        reshape wide schjoint0, i(id_apoderado) j(orden)
        rename schjoint010 schjoint10
        tempfile common_schools
        save `common_schools', replace

    // Younger schools (dropdown has > info sometimes, other times survey has > info)

        import delimited "$main_sae/encuesta/inputs/seccion_hermanos/dropdown_menor_encoded.csv", clear
        drop if orden > 10
        keep id_apoderado orden establecimiento id_menor
        rename establecimiento schmenor0

        reshape wide schmenor0, i(id_apoderado) j(orden)
        rename schmenor010 schmenor10
        tempfile common_menor
        save `common_menor', replace

    // Older schools (dropdown has > info sometimes, other times survey has > info)

        import delimited "$main_sae/encuesta/inputs/seccion_hermanos/dropdown_mayor_encoded.csv", clear
        drop if orden > 10
        keep id_apoderado orden establecimiento id_mayor
        rename establecimiento schmayor0

        reshape wide schmayor0, i(id_apoderado) j(orden)
        rename schmayor010 schmayor10
        tempfile common_mayor
        save `common_mayor', replace

    // Merging data

        use `survey_responses', clear
        drop schjoint*

        merge 1:1 id_apoderado using `common_schools', keep(1 3) nogen // All obs matched.

        merge 1:1 id_apoderado using `common_menor', keep(1 3) nogen // All obs matched. 2 new variables created: schmenor09, schmenor10.

        merge 1:1 id_apoderado using `common_mayor', keep(1 3) nogen // All obs matched. 3 new variables created: schmayor08, schmayor09, schmayor10.

// ----------------------------------------------------------------
// Best-joint (BJ), worst-joint (WJ), best-older-solo (BOS), best-younger-solo (BYS)
// ----------------------------------------------------------------

    gen sibl04_1_name = ""
    forvalues i = 1/9 {
        replace sibl04_1_name = schjoint0`i' if strpos(sibl04_1, "schjoint0`i'") > 0
    }
    replace sibl04_1_name = schjoint10 if strpos(sibl04_1, "schjoint10") > 0

    gen sibl04_2_name = ""
    forvalues i = 1/9 {
        replace sibl04_2_name = schjoint0`i' if strpos(sibl04_2, "schjoint0`i'") > 0 
    }
    replace sibl04_2_name = schjoint10 if strpos(sibl04_2, "schjoint10") > 0

    gen sibl05_menor_name = ""
    forvalues i = 1/9 {
        replace sibl05_menor_name = schmenor0`i' if strpos(sibl05_menor, "schmenor0`i'") > 0 
    }
    replace sibl05_menor_name = schmenor10 if strpos(sibl05_menor, "schmenor10") > 0

    gen sibl05_mayor_name = ""
    forvalues i = 1/9 {
        replace sibl05_mayor_name = schmayor0`i' if strpos(sibl05_mayor, "schmayor0`i'") > 0 
    }
    replace sibl05_mayor_name = schmayor10 if strpos(sibl05_mayor, "schmayor10") > 0

// ----------------------------------------------------------------
// Adding covariates for BJ, WJ, BOS, BYS
// ----------------------------------------------------------------

    preserve
        // Program characteristics
        import delimited "$main_sae/cartillas/cartillas_postulación/1_etapa_regular/4_research_tables/oferta/options_feedback_2023_08_28.csv", clear
        keep rbd cod_curso name sch_lon sch_lat quality_category quality_category_label
        rename name school_name
        replace school_name = lower(school_name)

        tempfile programs
        save `programs', replace

        // Applications data
        import delimited "$main_sae/cartillas/cartillas_postulación/1_etapa_regular/4_research_tables/applications/datos_jpal/datos_jpal_2023_09_20.csv", clear
        keep id_apoderado id_postulante rbd cod_curso latitud longitud
        merge m:1 rbd cod_curso using `programs', keep(1 3) nogen // All merge

        collapse (min) sch_lon_min = sch_lon sch_lat_min = sch_lat qual_min = quality_category (max) sch_lon_max = sch_lon sch_lat_max = sch_lat qual_max = quality_category latitud longitud, by(id_apoderado id_postulante school_name)
        count if sch_lat_max != sch_lat_min // 0.2%
        count if sch_lon_max != sch_lon_min // 0.2%
        count if qual_max != qual_min // 0.01%

        // For now, we will keep with max
        drop *_min 
        rename *_max *

        // Calculate distance
        geodist sch_lat sch_lon latitud longitud, gen(dist_km) 
        drop sch_lat sch_lon latitud longitud

        rename id_postulante id_menor 
        tempfile applications_menor
        save `applications_menor', replace

        rename id_menor id_mayor
        tempfile applications_mayor
        save `applications_mayor', replace
    restore

    // BJ

        rename sibl04_1_name school_name 
        replace school_name = lower(school_name)
        replace school_name = subinstr(school_name, "_", " ", .)

        merge 1:1 id_apoderado id_mayor school_name using `applications_mayor', keep(1 3) nogen // all merge
        rename (qual dist_km)(qual_bj_old dist_km_bj_old)

        merge 1:1 id_apoderado id_menor school_name using `applications_menor', keep(1 3) nogen // all merge
        rename (qual dist_km)(qual_bj_young dist_km_bj_young)
        rename school_name sibl04_1_name

    // WJ

        rename sibl04_2_name school_name 
        replace school_name = lower(school_name)
        replace school_name = subinstr(school_name, "_", " ", .)

        merge 1:1 id_apoderado id_mayor school_name using `applications_mayor', keep(1 3)  
        tab _merge if sibl04_2 != "" // all matched 
        drop _merge 
        rename (qual dist_km)(qual_wj_old dist_km_wj_old)

        merge 1:1 id_apoderado id_menor school_name using `applications_menor', keep(1 3)  
        tab _merge if sibl04_2 != "" // all matched 
        drop _merge 
        rename (qual dist_km)(qual_wj_young dist_km_wj_young)
        rename school_name sibl04_2_name

    // BOS

        rename sibl05_mayor_name school_name
        replace school_name = lower(school_name)
        replace school_name = subinstr(school_name, "_", " ", .)

        merge 1:1 id_apoderado id_mayor school_name using `applications_mayor', keep(1 3) 
        tab _merge if sibl05_mayor != "" // 6% not matched
        drop _merge
        rename (qual dist_km)(qual_bos_old dist_km_bos_old)
        rename school_name sibl05_mayor_name

    // BYS

        rename sibl05_menor_name school_name
        replace school_name = lower(school_name)
        replace school_name = subinstr(school_name, "_", " ", .)

        merge 1:1 id_apoderado id_menor school_name using `applications_menor', keep(1 3) // all merge
        tab _merge if sibl05_menor != "" // 6% not matched
        drop _merge 
        rename (qual dist_km)(qual_bos_young dist_km_bos_young)
        rename school_name sibl05_menor_name

    export delimited "$pathGit/7_estimation/data/survey_responses.csv", replace

