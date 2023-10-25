// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Paths
	// Created: Oct 20, 2023
	// Last Modified: Oct 20, 2023
	// Author: Javi Gazmuri

// -----------------------------------------------------------------------------

// ----------------------------------------------------------------
// Paths
// ----------------------------------------------------------------

	if "`c(username)'"=="javieragazmuri" { // Javiera
		global main_silings =  "/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings"
		global main_sae =  "/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/ChileSAE/SAE 2023"
	    global pathGit = "/Users/javieragazmuri/Documents/GitHub/cb-siblings"

	}

	global pathData "$main_silings/data"
	global pathData_sae "$main_sae/encuesta"

// Set graph style

    grstyle init
    grstyle color background white
    grstyle set horizontal 
    grstyle set compact 
    grstyle set size small: subheading axis_title 
    grstyle set size vsmall: small_body 
    grstyle set legend 6, nobox 
    grstyle set linewidth thin: major_grid
    grstyle set linewidth thin: tick 
    grstyle set linewidth thin: axisline
    grstyle set linewidth vthin: xyline
