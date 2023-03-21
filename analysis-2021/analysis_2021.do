// ---------------------------------------------- //
// ---------------------------------------------- //
// --------- SIBLINGS JOINT APPLICATION --------- //
// ---------------------------------------------- //
// ---------------------------------------------- //

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
save  `relaciones_reg', replace

import delimited "$pathData/inputs/analysis-2021/SAE_2021/B1_Postulantes_etapa_regular_2021_Admisión_2022_PUBL.csv", clear
keep mrun prioritario
tempfile prioritario
save  `prioritario', replace

// ---------------------------------------------- //
// ------------- 1. APPLICATIONS ---------------- //
// ---------------------------------------------- //

* Analysis at student level: only one sibling. 

use  `relaciones_reg', clear

reshape long mrun_@ , i(relacion) j(aux)

gen hermano_mayor = (aux == 1)
gen hermano_menor = (aux == 2)

bys relacion: egen double mrun_hermano_men = max(mrun_)
bys relacion: egen double mrun_hermano_may = min(mrun_)

gen double mrun_hermano = mrun_hermano_men if hermano_mayor ==1 
replace mrun_hermano = mrun_hermano_may if hermano_menor ==1
replace mrun_hermano = . if mrun_hermano == mrun_
replace mrun_hermano = mrun_hermano_men if hermano_menor ==1 & mrun_hermano == .
replace mrun_hermano = mrun_hermano_may if hermano_mayor ==1 & mrun_hermano == .

count if mrun_ == mrun_hermano // es 0
drop mrun_hermano_may mrun_hermano_men

* 506 relación
bys mrun_: egen n_relaciones = count(relacion)

rename mrun_ mrun
sort relacion mrun
order mrun

* Me quedo con el mrun_hermano solo para quienes tienen un hermano: análisis.
replace mrun_hermano = . if n_relaciones != 1

collapse (max) mismo_nivel postula_en_bloque hermano_* n_relaciones (firstnm) mrun_hermano, by (mrun)
* Ojo: hay estudiantes que son hermano_mayor == 1 & hermano_menor == 1
rename n_relaciones n_hermanos
order n_hermanos

count if mismo_nivel == 0 & postula_en_bloque == 1 & n_hermanos == 1

merge 1:1 mrun using `prioritario'
drop if _merge == 2
drop _merge

tempfile temp
save  `temp', replace

use `prioritario', clear
rename (mrun prioritario)(mrun_hermano prioritario_hermano)
merge 1:m mrun_hermano using `temp'
tab mrun_hermano if _merge == 2  // 0 obs. _merge == 2 are no-sibling students. 
drop if _merge == 1
drop _merge

* Priority students that used family application.
tab postula_en_bloque if prioritario == 1 & n_hermanos == 1 & mismo_nivel == 0
tab postula_en_bloque if prioritario == 0 & n_hermanos == 1 & mismo_nivel == 0

tempfile hermanos_reg
save  `hermanos_reg', replace

* ------------- Comparing applications between siblings --------------------- *

* 1. Number of schools applied in common
use `postulaciones_reg', clear
gen aux = 1
collapse (sum) aux, by(mrun rbd)
drop aux
tempfile postulaciones_ppal
save  `postulaciones_ppal', replace

rename mrun mrun_hermano
tempfile postulaciones_hermano
save  `postulaciones_hermano', replace

use  `hermanos_reg', clear
keep if n_hermanos == 1

merge 1:m mrun using `postulaciones_ppal'
drop if _merge == 2
drop _merge

merge m:1 mrun_hermano rbd using `postulaciones_hermano'
* merge == 3 : hermanos postularon al mismo colegio

bys mrun_hermano: 
bys mrun: gen aux = _n





bys mrun rbd: gen aux = _N
bys mrun: egen aux_2 = max(aux)

drop if aux_2 != 1
keep mrun rbd preferencia_postulante

tempfile postulaciones_ppal
save  `postulaciones_ppal', replace

rename mrun mrun_hermano
rename preferencia_postulante preferencia_hermano

tempfile postulaciones_hermano
save  `postulaciones_hermano', replace

use  `hermanos_reg', clear
keep if n_hermanos == 1
count  // 93,673

merge 1:m mrun using `postulaciones_ppal'
keep if _merge == 3  // nos quedamos con aquellos que no postularon más de una vez a un mismo rbd.
drop _merge

merge m:1 mrun_hermano rbd using `postulaciones_hermano'
bys mrun: 



merge 1:m mrun using  `postulaciones_reg'
drop if _merge == 2

bys mrun rbd: gen aux = _N


// ----------------------------------------------------------- //
// -------------- 2. ASSIGNMENT AND RESPONSES --------------- //
// --------------------------------------------------------- //

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


// ----------------------------------------------- //
// ----------------- ENROLLMENT  ----------------- //
// ----------------------------------------------- //

import delimited "$pathData/inputs/analysis-2021/Matrícula 2022/20220908_Matrícula_unica_2022_20220430_WEB.CSV", clear 
keep mrun rbd
preserve
rename rbd rbd_matriculado
tempfile matricula
save  `matricula', replace
restore

rename (mrun rbd) (mrun_hermano rbd_matriculado_hermano)
tempfile matricula_hermano
save  `matricula_hermano', replace

use `etapa_reg_estudiantes'
merge 1:1 mrun using `matricula'
drop if _merge == 2 

gen matriculado = 0 if _merge == 1
replace matriculado = 1 if _merge == 3
drop _merge

merge m:1 mrun_hermano using `matricula_hermano'
drop if _merge == 2
gen hermano_matriculado = 0 if _merge == 1
replace hermano_matriculado = 1 if _merge == 3
drop _merge

tempfile matricula_ambos
save  `matricula_ambos', replace

* Filter: Students that participated in the main stage only

import delimited "$pathData/inputs/analysis-2021/SAE_2021/B2_Postulantes_etapa_complementaria_2021_Admisión_2022_PUBL.csv", clear
keep mrun
merge 1:1 mrun using `matricula_ambos'
keep if _merge == 2 // I keep the students who only participated in the main stage. 
drop _merge

* Analysis

* 1. Enrolled in the assigned school
count if matriculado == 1 & n_hermanos == 0 & rbd_final != . & rbd_matriculado == rbd_final
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0 & rbd_final != . & rbd_final == rbd_final_hermano & rbd_matriculado == rbd_final
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0 & rbd_final != . & rbd_final != rbd_final_hermano & rbd_matriculado == rbd_final
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0 & rbd_final != . & rbd_final == rbd_final_hermano & rbd_matriculado == rbd_final
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0 & rbd_final != . & rbd_final != rbd_final_hermano & rbd_matriculado == rbd_final

* 2. Not enrolled in the assigned school, enrolled together
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0 & rbd_final != . & rbd_final == rbd_final_hermano & rbd_matriculado != rbd_final & rbd_matriculado == rbd_matriculado_hermano
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0 & rbd_final != . & rbd_final != rbd_final_hermano & rbd_matriculado != rbd_final & rbd_matriculado == rbd_matriculado_hermano
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0 & rbd_final != . & rbd_final == rbd_final_hermano & rbd_matriculado != rbd_final & rbd_matriculado == rbd_matriculado_hermano
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0 & rbd_final != . & rbd_final != rbd_final_hermano & rbd_matriculado != rbd_final & rbd_matriculado == rbd_matriculado_hermano

* 3. Not enrolled in the assigned school, not enrolled together
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0 & rbd_final != . & rbd_final == rbd_final_hermano & rbd_matriculado != rbd_final & rbd_matriculado != rbd_matriculado_hermano
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0 & rbd_final != . & rbd_final != rbd_final_hermano & rbd_matriculado != rbd_final & rbd_matriculado != rbd_matriculado_hermano
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0 & rbd_final != . & rbd_final == rbd_final_hermano & rbd_matriculado != rbd_final & rbd_matriculado != rbd_matriculado_hermano
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0 & rbd_final != . & rbd_final != rbd_final_hermano & rbd_matriculado != rbd_final & rbd_matriculado != rbd_matriculado_hermano

* Base (to obtain %):
count if n_hermanos == 0 & rbd_final != . 
count if n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0 & rbd_final == rbd_final_hermano & rbd_final != .
count if n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0 & rbd_final != rbd_final_hermano & rbd_final != .
count if n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0 & rbd_final == rbd_final_hermano & rbd_final != .
count if n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0 & rbd_final != rbd_final_hermano & rbd_final != .

* Priority students 

* 1. Enrolled in the assigned school, enrolled together
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0 & prioritario == 1 & rbd_final != . & rbd_matriculado == rbd_final & rbd_matriculado == rbd_matriculado_hermano 
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0 & prioritario == 1 & rbd_final != . & rbd_matriculado == rbd_final & rbd_matriculado == rbd_matriculado_hermano 
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0 & prioritario == 0 & rbd_final != . & rbd_matriculado == rbd_final & rbd_matriculado == rbd_matriculado_hermano 
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0 & prioritario == 0 & rbd_final != . & rbd_matriculado == rbd_final & rbd_matriculado == rbd_matriculado_hermano 

* 2. Enrolled in the assigned school, not enrolled together
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0 & prioritario == 1 & rbd_final != . & rbd_matriculado == rbd_final & rbd_matriculado != rbd_matriculado_hermano 
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0 & prioritario == 1 & rbd_final != . & rbd_matriculado == rbd_final & rbd_matriculado != rbd_matriculado_hermano 
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0 & prioritario == 0 & rbd_final != . & rbd_matriculado == rbd_final & rbd_matriculado != rbd_matriculado_hermano 
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0 & prioritario == 0 & rbd_final != . & rbd_matriculado == rbd_final & rbd_matriculado != rbd_matriculado_hermano 

* 3. Not enrolled in the assigned school, enrolled together
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0 & prioritario == 1 & rbd_final != . & rbd_matriculado != rbd_final & rbd_matriculado == rbd_matriculado_hermano 
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0 & prioritario == 1 & rbd_final != . & rbd_matriculado != rbd_final & rbd_matriculado == rbd_matriculado_hermano 
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0 & prioritario == 0 & rbd_final != . & rbd_matriculado != rbd_final & rbd_matriculado == rbd_matriculado_hermano 
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0 & prioritario == 0 & rbd_final != . & rbd_matriculado != rbd_final & rbd_matriculado == rbd_matriculado_hermano 

* 4. Not enrolled in the assigned school, not enrolled together
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0 & prioritario == 1 & rbd_final != . & rbd_matriculado != rbd_final & rbd_matriculado != rbd_matriculado_hermano 
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0 & prioritario == 1 & rbd_final != . & rbd_matriculado != rbd_final & rbd_matriculado != rbd_matriculado_hermano 
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0 & prioritario == 0 & rbd_final != . & rbd_matriculado != rbd_final & rbd_matriculado != rbd_matriculado_hermano 
count if matriculado == 1 & n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0 & prioritario == 0 & rbd_final != . & rbd_matriculado != rbd_final & rbd_matriculado != rbd_matriculado_hermano 

* Base (to obtain %):
count if n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0 & prioritario == 1 & rbd_final != .
count if n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0 & prioritario == 1 & rbd_final != .
count if n_hermanos == 1 & postula_en_bloque == 1 & mismo_nivel == 0 & prioritario == 0 & rbd_final != .
count if n_hermanos == 1 & postula_en_bloque == 0 & mismo_nivel == 0 & prioritario == 0 & rbd_final != .
