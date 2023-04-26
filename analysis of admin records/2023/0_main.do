// ---------------------------------------------- //
// ---------------------------------------------- //
// ---------------- MAIN DO FILE ---------------- //
// ---------------------------------------------- //
// ---------------------------------------------- //

// Paths

    if "`c(username)'"=="javieragazmuri" { // Javiera
	    global main =  "/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings"
	    global pathGit = "/Users/javieragazmuri/Documents/GitHub/cb-siblings"
    }

    global pathData "$main/data"

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
