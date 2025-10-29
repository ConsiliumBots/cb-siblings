// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: 2023 Phone survey statistics
	// Created: Dec 28, 2023
	// Last Modified: Dec 28, 2023
	// Author: Javi Gazmuri

// -----------------------------------------------------------------------------

// ----------------------------------------------------------------
// Data 
// ----------------------------------------------------------------

    import delimited "$pathData/inputs/telephone_survey/answers/raw/Encuesta telefónica - SAE_December 28, 2023_09.32.csv", varnames(1) clear
    tempfile answers
    save `answers', replace

    import delimited "$pathData/outputs/telephone_survey/inputs_encuesta.csv", clear 
    rename externaldatareference externalreference

    keep id_mayor id_menor externalreference
    tempfile inputs 
    save `inputs', replace

    import delimited "$main_sae/datos_SAE/1_Source/1_Principal/postulaciones/datos_jpal_2023-09-20.csv", clear
    keep id_postulante prioritario
    duplicates drop id_postulante, force
    tempfile sep
    save `sep', replace

// ----------------------------------------------------------------
// Clean 
// ----------------------------------------------------------------

    use `answers', clear

    rename v19 q_1
    rename v20 q_2
    rename v21 q_4
    rename _4_text q_4_text
    rename v23 q_4_1
    rename v24 q_4_1_text
    rename v25 q_4_2
    rename v26 q_4_2_text
    rename v27 q_4_3
    rename v28 q_4_3_text
    rename v29 q_5_1
    rename v30 q_5_2
    rename v31 q_6_1
    rename v32 q_6_2
    rename v33 q_7_1
    rename v34 q_7_2
    rename v35 q_7_3
    rename v36 q_8
    rename v39 q_9
    rename v40 q_10
    rename v41 q_11
    rename _17_text q_11_text
    rename v43 q_12

    drop if _n <= 21 

    // Obtenemos la fecha de finalización (las respuestas del 19 de diciembre no sé si se usarán porque se cambiaron algunas preguntas)

        split enddate, gen(date_)
        drop date_2

        rename date_1 enddate_2
        split enddate_2, gen(date_) parse("-")

        rename date_3 end_survey_day
        destring end_survey_day, replace

    // Múltiples respuestas para un mismo apoderado

        bys externalreference: gen auxiliar = _N
        tab auxiliar // 6 obs 
        drop if auxiliar > 1 

    // Merge inputs 

        merge 1:1 externalreference using `inputs', keep(3) nogen // no _merge = 1

// ----------------------------------------------------------------
// Analysis 
// ----------------------------------------------------------------

    // Distance 

        encode q25, gen(q25_encode)

        tab q_9 if q25_encode == 2

    // Truth-telling or strategic 

        split q_4, parse(",") gen(q_4_r_)

        gen     truth_telling = (q_4_r_1 == "No le habría hecho cambios a su postulación") & (q_4_r_2 == "")
        replace truth_telling = . if q_4_r_1 == ""

        tab truth_telling

        // Merge data SEP

            preserve
                use `sep', clear
                rename (id_postulante prioritario)(id_mayor sep_mayor)
                tempfile sep_mayor
                save `sep_mayor', replace

                rename (id_mayor sep_mayor)(id_menor sep_menor)
                tempfile sep_menor
                save `sep_menor', replace 
            restore 

            merge 1:1 id_mayor using `sep_mayor', keep(3) nogen // 0 obs _merge = 1
            merge 1:1 id_menor using `sep_menor', keep(3) nogen // 0 obs _merge = 1

        gen nombre_menor = (nombre_post1 == nombre_post)

        gen     sep_final = sep_menor if nombre_menor == 1
        replace sep_final = sep_mayor if nombre_menor == 0

        reg truth_telling sep_final // signo negativo, raro

        gen     strategic = (q_5_1 == "Sí" | q_5_2 == "Sí" | q_6_1 == "Sí" | q_6_2 == "Sí")
        replace strategic = . if q_5_1 == "" & q_5_2 == "" & q_6_1 == "" & q_6_2 == ""
        
        reg strategic sep_final // signo negativo, no estadísticamente significativo

    // How to be strategic 

        split q_4, gen(strategic_) parse(",")

        gen strategic_order = strategic_1 == "Habría ordenado los colegios de manera distinta" | strategic_2 == "Habría ordenado los colegios de manera distinta" | strategic_3 == "Habría ordenado los colegios de manera distinta" if truth_telling == 0
        gen strategic_add   = strategic_1 == "Habría incluido más colegios en su postulación" | strategic_2 == "Habría incluido más colegios en su postulación" | strategic_3 == "Habría incluido más colegios en su postulación" if truth_telling == 0
        gen strategic_less   = strategic_1 == "Habría incluido menos colegios en su postulación" | strategic_2 == "Habría incluido menos colegios en su postulación" | strategic_3 == "Habría incluido menos colegios en su postulación" if truth_telling == 0

        tab strategic_add
        tab strategic_order

    // Reasons to be strategic

        split q_4_1, gen(reason_1_) parse(",")
        split q_4_2, gen(reason_2_) parse(",")
        split q_4_3, gen(reason_3_) parse(",")

        gen reason_3_5 = ""
        gen reason_3_6 = ""

        gen reason_placement = 0
        gen reason_economics = 0
        gen reason_probs = 0

        forvalues y = 1/3 {
            forvalues x = 1/6 {
                replace reason_placement = 1 if reason_placement == 0 & reason_`y'_`x' == "Por la ubicación en que se encuentran o la distancia entre los establecimientos y el hogar"
                replace reason_economics = 1 if reason_economics == 0 & reason_`y'_`x' == "Razones económicas"
                replace reason_probs = 1 if reason_probs == 0 & reason_`y'_`x' == "Por posibilidades de asignación"
        }
        }

        replace reason_placement = . if q_4_1 == "" & q_4_2 == "" & q_4_3 == ""
        replace reason_economics = . if q_4_1 == "" & q_4_2 == "" & q_4_3 == ""
        replace reason_probs = . if q_4_1 == "" & q_4_2 == "" & q_4_3 == ""

        tab reason_placement
        tab reason_economics
        tab reason_probs

        gen change_distance = q_5_1 == "Sí" |  q_5_2 == "Sí" if q_5_1 != "" |  q_5_2 != ""
        gen change_placement = q_6_1 == "Sí" |  q_6_2 == "Sí" if q_6_1 != "" |  q_6_2 != ""

        tab change_distance
        tab change_placement



