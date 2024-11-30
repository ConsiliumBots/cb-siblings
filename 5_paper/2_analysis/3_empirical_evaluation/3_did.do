// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Analyze change in family app.
	// Created: May 14, 2024
	// Last Modified: Jun 6, 2024
	// Author: Javi Gazmuri
// -----------------------------------------------------------------------------

    import delimited "$pathData/intermediate/feedback/2023/clean_data/long_data_reg.csv", clear

// -------------------------------------------------------------------------
// Cleaning
// -------------------------------------------------------------------------

    // Replace Sept. 5 applications (last day) with Sept. 20 (official last day)

        drop if numdate == "05sep2023" 
        replace numdate = "05sep2023" if numdate == "20sep2023"

// -------------------------------------------------------------------------
// Relevant variables
// -------------------------------------------------------------------------

    // Fixing date 

        gen date_full = date(numdate, "DMY")

        * Extraer mes y día de la fecha completa
        gen month = month(date_full)
        gen day = day(date_full)

        * Crear nueva variable de fecha solo con mes y día 
        gen date = mdy(month, day, 2023)
        format date %tdMon_DD

        drop date_full numdate

    // First date applied

        bys id_postulante_1 id_postulante_2: egen app_first_date = min(date) if fam_app != .
        bys id_postulante_1 id_postulante_2: ereplace app_first_date = min(app_first_date)

        format app_first_date %td

    // Treatment groups

        gen treatment_1 = apertura_post_fam == 1 

        gen treatment_2 = should == "Debe cambiar" if apertura_post_fam == 1 & should != "Indiferente"

        // MA analysis
            
            * Treatment: uno de los 4 eventos principales era ambos en MA.
            * Control: ninguno de los 4 eventos principales era ambos en MA.

            * only the second event could be assigned together in ma. 

            gen is_ma_2 = regexm(e2_explicacion, "ambos") & regexm(e2_explicacion, "origen") if e2_explicacion != ""
            
            gen treatment_ma = is_ma_2 == 1 if apertura_post_fam == 1

    // Strong preference for joint assignment

        encode sibl06_menos, gen(sibl06_encode)
        gen strong_for_joint = sibl06_encode == 2 if sibl06_encode != .

    // Outcomes 

        // Change fam. app.
            
            sort id_postulante_1 id_postulante_2 date

            bys id_postulante_1 id_postulante_2: gen change_fam_app = fam_app != fam_app[_n-1] 
            
            replace change_fam_app = . if fam_app == .
            replace change_fam_app = . if date == app_first_date

        // Assigned together 

            gen assigned_together = rbd_1 == rbd_2 & rbd_1 != .
        
        // Assigned together: MA

            gen assigned_together_ma = assigned_together == 1 & rbd_1 == rbd_origen_1 if rbd_origen_1 == rbd_origen_2 & rbd_origen_1 != .

// -------------------------------------------------------------------------
// Paralel trends
// -------------------------------------------------------------------------

    gen change_fam_app_t1 = change_fam_app if treatment_1 == 1
    gen change_fam_app_c1 = change_fam_app if treatment_1 == 0

    gen change_fam_app_t2 = change_fam_app if treatment_2 == 1
    gen change_fam_app_c2 = change_fam_app if treatment_2 == 0
   
    gen assigned_together_t1 = assigned_together if treatment_1 == 1
    gen assigned_together_c1 = assigned_together if treatment_1 == 0

    gen assigned_together_t2 = assigned_together if treatment_2 == 1
    gen assigned_together_c2 = assigned_together if treatment_2 == 0
   
   // Reshaping the data 
        
        preserve 

            collapse (mean) change_fam_app_t1 change_fam_app_c1 change_fam_app_t2 change_fam_app_c2 assigned_together_t1 assigned_together_c1 assigned_together_t2 assigned_together_c2, by(date)
            reshape long change_fam_app_ assigned_together_, i(date) j(group) string 

            rename *_ *

            gen     treatment = 0
            replace treatment = 1 if group == "t1" | group == "t2"
            label define group 1 "Tratamiento" 0 "Control", replace
            label values treatment group

            replace group = "1" if group == "t1" | group == "c1"
            replace group = "2" if group == "t2" | group == "c2"

            destring group, replace

        // Graphs

            // Change fam. app. 

                local aug30 = date("30 Aug 2023", "DMY")
                levelsof date, local(date_labels)

                twoway (scatter change_fam_app date if treatment == 1 & group == 1, msymbol(O) mcolor(red%50)) ///
                    (scatter change_fam_app date if treatment == 0 & group == 1, msymbol(O) mcolor(blue%50)), ///
                    xline(`aug30', lcolor(black) lpattern(dash)) xlabel(`date_labels', angle(45)) ///
                    title("Abre cartilla (T) vs no (C)") legend(order(1 "Tratamiento" 2 "Control")) xsize(7) ///
                    xtitle("") ytitle("Proporción cambia post. fam.")

                local aug30 = date("30 Aug 2023", "DMY")
                levelsof date, local(date_labels)

                twoway (scatter change_fam_app date if treatment == 1 & group == 2, msymbol(O) mcolor(red%50)) ///
                    (scatter change_fam_app date if treatment == 0 & group == 2, msymbol(O) mcolor(blue%50)), ///
                    xline(`aug30', lcolor(black) lpattern(dash)) xlabel(`date_labels', angle(45)) ///
                    title("Debe cambiar (T) vs debe mantener (C)") subtitle("Entre los que abrieron la cartilla") ///
                    legend(order(1 "Tratamiento" 2 "Control")) xsize(7) ///
                    xtitle("") ytitle("Proporción cambia post. fam.")

            // Assigned together

                local aug30 = date("30 Aug 2023", "DMY")
                levelsof date, local(date_labels)

                twoway (scatter assigned_together date if treatment == 1 & group == 1, msymbol(O) mcolor(red%50)) ///
                    (scatter assigned_together date if treatment == 0 & group == 1, msymbol(O) mcolor(blue%50)), ///
                    xline(`aug30', lcolor(black) lpattern(dash)) xlabel(`date_labels', angle(45)) ///
                    title("Abre cartilla (T) vs no (C)") legend(order(1 "Tratamiento" 2 "Control")) xsize(7) ///
                    xtitle("") ytitle("Proporción asignados juntos")

                local aug30 = date("30 Aug 2023", "DMY")
                levelsof date, local(date_labels)

                twoway (scatter assigned_together date if treatment == 1 & group == 2, msymbol(O) mcolor(red%50)) ///
                    (scatter assigned_together date if treatment == 0 & group == 2, msymbol(O) mcolor(blue%50)), ///
                    xline(`aug30', lcolor(black) lpattern(dash)) xlabel(`date_labels', angle(45)) ///
                    title("Debe cambiar (T) vs debe mantener (C)") subtitle("Entre los que abrieron la cartilla") ///
                    legend(order(1 "Tratamiento" 2 "Control")) xsize(7) ///
                    xtitle("") ytitle("Proporción asignados juntos")

        restore

// -------------------------------------------------------------------------
// DID Estimations
// -------------------------------------------------------------------------

    // Centered in the day we sent the feedback

        gen send_date = mdy(08, 30, 2023)
        format send_date %tdMon_DD

        gen     dif = date - send_date
        replace dif = dif + 21 //21 is zero, we need to do this because the regression does not allow for negative values of FE

        label define dif ///
        0 "-21" ///	
        1 "-20" ///	
        2 "-19" ///	
        3 "-18" ///	
        4 "-17" ///
        5 "-16"	 ///
        6 "-15"	 ///
        7 "-14"	 ///
        8 "-13"	 ///
        9 "-12" ///	
        10 "-11" ///	
        11 "-10" ///	
        12 "-9" ///
        13 "-8"	 ///
        14 "-7"	 ///
        15 "-6"	 ///
        16 "-5"	 ///
        17 "-4"	 ///
        18 "-3"	 ///
        19 "-2"	 ///
        20 "-1"	 ///
        21 "0"	 ///
        22 "1"	 ///
        23 "2"	 ///
        24 "3"	 ///
        25 "4"	 ///
        26 "5"	 ///
        27 "6"	 ///
        , replace

        label values dif dif

    // Graphs

        // Treatment: useful for assigned together

            // Use fam. app. 

                reg fam_app ib21.dif##i.treatment_2 if strong_for_joint == 1 & dif >= 14, cluster(id_apoderado) omitted baselevel
                coefplot (,keep(*dif#1.treatment_2) omitted baselevels recast(connected) label("Cambio en diferencia Tratados - Controles (respecto a t = 0)")) ///
                , mcolor(red%50) lcolor(red%50) ciopts(lcolor(red%50)) yline(0,lcolor(gs10)) xline(7, lcolor(black) lpattern(dash)) ///
                vertical xtitle("Días para el envío de la cartilla") rename(#1.treatment_2$ = \1 #0.treatment_2$ = \1, regex) ///
                legend(region(lstyle(none)) pos(6)) ytitle("Uso post. fam.") coeflabels(, labsize(vsmall))

            // Schools applied in common

                reg schools_comun ib21.dif##i.treatment_2 if strong_for_joint == 1 & dif >= 14, cluster(id_apoderado) omitted baselevel
                coefplot (,keep(*dif#1.treatment_2) omitted baselevels recast(connected) label("Cambio en diferencia Tratados - Controles (respecto a t = 0)")) ///
                , mcolor(red%50) lcolor(red%50) ciopts(lcolor(red%50)) yline(0,lcolor(gs10)) xline(7, lcolor(black) lpattern(dash)) ///
                vertical xtitle("Días para el envío de la cartilla") rename(#1.treatment_2$ = \1 #0.treatment_2$ = \1, regex) ///
                legend(region(lstyle(none)) pos(6)) ytitle("Escuelas postuladas en común") coeflabels(, labsize(vsmall))

            // Assigned together

                reg assigned_together ib21.dif##i.treatment_2 if strong_for_joint == 1 & dif >= 14, cluster(id_apoderado) omitted baselevel
                coefplot (,keep(*dif#1.treatment_2) omitted baselevels recast(connected) label("Cambio en diferencia Tratados - Controles (respecto a t = 0)")) ///
                , mcolor(red%50) lcolor(red%50) ciopts(lcolor(red%50)) yline(0,lcolor(gs10)) xline(7, lcolor(black) lpattern(dash)) ///
                vertical xtitle("Días para el envío de la cartilla") rename(#1.treatment_2$ = \1 #0.treatment_2$ = \1, regex) ///
                legend(region(lstyle(none)) pos(6)) ytitle("Prop. asignados juntos") coeflabels(, labsize(vsmall))

        // Treatment: useful for MA

            // Use fam. app.

                reg fam_app ib21.dif##i.treatment_ma if strong_for_joint == 1 & dif >= 14, cluster(id_apoderado) omitted baselevel
                coefplot (,keep(*dif#1.treatment_ma) omitted baselevels recast(connected) label("Cambio en diferencia Tratados - Controles (respecto a t = 0)")) ///
                , mcolor(red%50) lcolor(red%50) ciopts(lcolor(red%50)) yline(0,lcolor(gs10)) xline(7, lcolor(black) lpattern(dash)) ///
                vertical xtitle("Días para el envío de la cartilla") rename(#1.treatment_ma$ = \1 #0.treatment_ma$ = \1, regex) ///
                legend(region(lstyle(none)) pos(6)) ytitle("Uso post. fam.") coeflabels(, labsize(vsmall))

            // Schools in common

                reg schools_comun ib21.dif##i.treatment_ma if strong_for_joint == 1 & dif >= 14, cluster(id_apoderado) omitted baselevel
                coefplot (,keep(*dif#1.treatment_ma) omitted baselevels recast(connected) label("Cambio en diferencia Tratados - Controles (respecto a t = 0)")) ///
                , mcolor(red%50) lcolor(red%50) ciopts(lcolor(red%50)) yline(0,lcolor(gs10)) xline(7, lcolor(black) lpattern(dash)) ///
                vertical xtitle("Días para el envío de la cartilla") rename(#1.treatment_ma$ = \1 #0.treatment_ma$ = \1, regex) ///
                legend(region(lstyle(none)) pos(6)) ytitle("Escuelas postuladas en común") coeflabels(, labsize(vsmall))

            // Assigned together MA 

                reg assigned_together_ma ib21.dif##i.treatment_ma if dif >= 14, cluster(id_apoderado) omitted baselevel
                coefplot (,keep(*dif#1.treatment_ma) omitted baselevels recast(connected) label("Cambio en diferencia Tratados - Controles (respecto a t = 0)")) ///
                , mcolor(red%50) lcolor(red%50) ciopts(lcolor(red%50)) yline(0,lcolor(gs10)) xline(7, lcolor(black) lpattern(dash)) ///
                vertical xtitle("Días para el envío de la cartilla") rename(#1.treatment_ma$ = \1 #0.treatment_ma$ = \1, regex) ///
                legend(region(lstyle(none)) pos(6)) ytitle("Prop. asignados juntos en MA") coeflabels(, labsize(vsmall))

    // Regressions (pre-post)

        gen     post_cartilla = 0 if date == mdy(08, 30, 2023)
        replace post_cartilla = 1 if date == mdy(09, 05, 2023)

        reg fam_app post_cartilla##treatment_2 if strong_for_joint == 1, vce(cluster id_apoderado)

        reg assigned_together post_cartilla##treatment_2 if strong_for_joint == 1, vce(cluster id_apoderado)

        reg assigned_together_ma post_cartilla##treatment_ma, vce(cluster id_apoderado)

// -------------------------------------------------------------------------
// DID-IV
// -------------------------------------------------------------------------

    // Outcome: assigned together

        // First stage

            reg fam_app post_cartilla##i.treatment_2 if strong_for_joint == 1, vce(cluster id_apoderado)
            predict p_fam_app if e(sample)

        // Second stage 

            reg assigned_together p_fam_app post_cartilla treatment_2 if strong_for_joint == 1, vce(cluster id_apoderado)

    // Outcome: assigned together in MA

        // First stage

            reg fam_app post_cartilla##i.treatment_ma if rbd_origen_1 == rbd_origen_2 & rbd_origen_1 != ., vce(cluster id_apoderado)
            predict p_fam_app_2 if e(sample)
        
        // Second stage

            reg assigned_together_ma p_fam_app_2 post_cartilla treatment_ma, vce(cluster id_apoderado)






