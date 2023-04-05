// ---------------------------------------------- //
// ---------------------------------------------- //
// --------- SIBLINGS JOINT APPLICATION --------- //
// ---------------------------------------------- //
// ---------------------------------------------- //

// -----------------------------------------------------------------------------
// File Description
// -----------------------------------------------------------------------------
	// Project: Siblings Chile
	// Objective: Analysis of assignments
	// Created: 2022
	// Last Modified: Mar 23, 2023
	// Author: Javi Gazmuri

// -----------------------------------------------------------------------------

if "`c(username)'"=="javieragazmuri" { // Javiera
	global main =  "/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings"
	global pathGit = "/Users/javieragazmuri/Documents/GitHub/cb-siblings"
  }

global pathData "$main/data"

// ---------------------------------------------- //
// --------------------- DATA ------------------- //
// ---------------------------------------------- //

// ------ MAIN STAGE ------ //

import delimited "$pathData/inputs/analysis-2021/SAE_2021/D1_Resultados_etapa_regular_2021_Admisión_2022_PUBL.csv", clear
tempfile asig_reg
save  `asig_reg', replace

import delimited "$pathData/inputs/analysis-2021/SAE_2021/C1_Postulaciones_etapa_regular_2021_Admisión_2022_PUBL.csv", clear 
tempfile postulaciones_reg
save  `postulaciones_reg', replace

import delimited "$pathData/inputs/analysis-2021/SAE_2021/F1_Relaciones_entre_postulantes_etapa_regular_2021_Admisión_2022_PUBL.csv", clear
duplicates report mrun_1 mrun_2
gen relacion = _n
tempfile relaciones_reg
save  `relaciones_reg', replace  // this data has no duplicate relationships. Eg: if mrun_1 = 1 & mrun_2 = 2, there is no observation with mrun_1 = 2 & mrun_2 = 1

import delimited "$pathData/inputs/analysis-2021/SAE_2021/B1_Postulantes_etapa_regular_2021_Admisión_2022_PUBL.csv", clear
keep mrun prioritario
tempfile prioritario
save  `prioritario', replace

// ------------------------------------------------------- //
// -------------- ASSIGNMENT AND RESPONSES --------------- //
// ------------------------------------------------------- //

* Analysis at student level: only one sibling. 

use `asig_reg', clear
destring rbd_admitido cod_curso_admitido rbd_admitido_post_resp cod_curso_admitido_post_resp respuesta_postulante_post_lista_, replace
gen rbd_final = rbd_admitido
replace rbd_final = rbd_admitido_post_resp if respuesta_postulante == 2 | respuesta_postulante == 6

gen double cod_curso_final = cod_curso_admitido
replace cod_curso_final = cod_curso_admitido_post_resp if respuesta_postulante == 2 | respuesta_postulante == 6

gen respuesta_final = respuesta_postulante_post_lista_
replace respuesta_final = respuesta_postulante if respuesta_postulante == 1 |  respuesta_postulante == 3  |  respuesta_postulante == 5

rename (rbd_final cod_curso_final) (rbd cod_curso)
merge 1:1 mrun rbd cod_curso using `postulaciones_reg'
tab respuesta_final if _merge == 1 // Los _merge == 1 son aquellos no asignados (respuesta_final = 6)
drop if _merge == 2
drop _merge
rename (rbd cod_curso)(rbd_final cod_curso_final)

tempfile asig_post_reg
save  `asig_post_reg', replace

import delimited "$pathData/inputs/analysis-2021/SAE_2021/B1_Postulantes_etapa_regular_2021_Admisión_2022_PUBL.csv", clear 
merge 1:1 mrun using  `hermanos_reg'
*No hay _merge == 2.
drop _merge
replace n_hermanos = 0 if n_hermanos == .

merge 1:1 mrun using  `asig_post_reg'
*Solo _merge == 3.
drop _merge
gen id_base = _n

preserve
keep if mrun_hermano!=.
keep mrun_hermano id_base
rename mrun_hermano mrun
merge m:1 mrun using  `asig_post_reg'
drop if _merge ==2 
drop _merge
keep mrun id_base rbd_final respuesta_final preferencia_postulante
foreach x in mrun rbd_final respuesta_final preferencia_postulante {
	rename `x' `x'_hermano
}
tempfile asig_hermano
save  `asig_hermano', replace
restore

merge 1:1 id_base mrun_hermano using  `asig_hermano'
drop _merge

count if n_hermanos == 0
count if n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0
count if n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0

count if n_hermanos == 0 & rbd_final != . 
count if n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0 & rbd_final != .
count if n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0 & rbd_final != .

count if n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0  & rbd_final!=. & rbd_final == rbd_final_hermano
count if n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0  & rbd_final!=. & rbd_final == rbd_final_hermano

tab respuesta_final if n_hermanos == 0 & rbd_final != . 
tab respuesta_final if n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0 & rbd_final != .
tab respuesta_final if n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0 & rbd_final != .

tab respuesta_final if n_hermanos == 0 & rbd_final != . & preferencia_postulante == 1
tab respuesta_final if n_hermanos == 1 & mismo_nivel == 0 & postula_en_bloque == 1 & rbd_final == rbd_final_hermano & preferencia_postulante == 1 & rbd_final != .
tab respuesta_final if n_hermanos == 1 & mismo_nivel == 0 & postula_en_bloque == 1 & rbd_final != rbd_final_hermano & preferencia_postulante == 1 & rbd_final != .
tab respuesta_final if n_hermanos == 1 & mismo_nivel == 0 & postula_en_bloque == 0 & rbd_final == rbd_final_hermano & preferencia_postulante == 1 & rbd_final != .
tab respuesta_final if n_hermanos == 1 & mismo_nivel == 0 & postula_en_bloque == 0 & rbd_final != rbd_final_hermano & preferencia_postulante == 1 & rbd_final != .

tempfile etapa_reg_estudiantes
save  `etapa_reg_estudiantes', replace

* Simulaciones: por python, análisis por acá

import delimited "$pathData/inputs/analysis-2021/SAE_2021/Simulaciones/results_true_true.csv", clear
keep applicant_id institution_id
rename applicant_id mrun 
tempfile simulacion_1
save  `simulacion_1', replace

use  `etapa_reg_estudiantes', replace
merge 1:1 mrun using `simulacion_1'
rename institution_id rbd_1
drop if _merge == 2
drop _merge
tempfile etapa_reg_estudiantes_1
save  `etapa_reg_estudiantes_1', replace

use  `simulacion_1', replace
rename mrun mrun_hermano
tempfile simulacion_2
save  `simulacion_2', replace

use  `etapa_reg_estudiantes_1', clear
merge m:1 mrun_hermano using `simulacion_2'
rename institution_id rbd_hermano
count if mrun_hermano!=. & _merge == 1 	// 0 obs.
drop if _merge == 2
drop _merge

count if rbd_1 != .
count if rbd_1 != . & n_hermanos == 1 & mismo_nivel == 0
count if rbd_1 != . & n_hermanos == 1 & mismo_nivel == 0 & rbd_1 == rbd_hermano

