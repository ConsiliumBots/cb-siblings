// ------------------------------------------------------------ //
// ----------------------------------------------------------- //
// --------- SIBLINGS JOINT APPLICATION SURVEY 2022 --------- //
// --------------------------------------------------------- //
// -------------------------------------------------------- //

// ----------------------------------------------------------------
// Paths
// ----------------------------------------------------------------

if "`c(username)'"=="javieragazmuri" { // Javiera
	global main =  "/Users/javieragazmuri/ConsiliumBots Dropbox/ConsiliumBots/Projects/Chile/Siblings"
	global pathGit = "/Users/javieragazmuri/Documents/GitHub/cb-siblings"
  }

global pathData "$main/data"

// ----------------------------------------------------------------
// Data clean
// ----------------------------------------------------------------
import delimited "/Users/javieragazmuri/Downloads/datos_jpal_2022-10-05_enviar.csv", clear 
bysort id_postulante id_apoderado: generate n_postulante = _n == 1
bysort id_apoderado: replace n_postulante = sum(n_postulante)
bysort id_apoderado: replace n_postulante = n_postulante[_N]
keep if n_postulante == 2
keep id_apoderado postulacion_familiar         
collapse (firstnm) postulacion_familiar, by(id_apoderado)            // no hay variación a nivel de id_apoderado

tempfile datos_jpal
save `datos_jpal', replace

import delimited "$pathData/inputs/survey/2022/SAE_Encuesta_satisfaccion_2022.csv", clear
keep if qid1 == "3" // Consent
merge m:1 id_apoderado using `datos_jpal'
drop if _merge == 2
drop _merge

// ----------------------------------------------------------------
// Q213 ¿Qué asignación prefieres? Tu favorita si es que quedan en establecimientos diferentes, o la que menos te gusta si quedan en el mismo establecimiento.
// ----------------------------------------------------------------

tab q213 postulacion_familiar if q213!="NA"

// ----------------------------------------------------------------
// Q222 ¿Qué asignación prefieres? Tu favorita si es que quedan en establecimientos diferentes, o la favorita si quedan en el mismo establecimiento.
// ----------------------------------------------------------------

tab q222 postulacion_familiar if q222!="NA"

// ----------------------------------------------------------------
// Q180 Si ambos estudiantes no son admitidos en la misma escuela, ¿qué tan probable es que termines rechazando la vacante?
// ----------------------------------------------------------------

destring q180_1, replace ignore(NA)

gen intervalo = 0 if q180_1<=10 & q180_1!=.
replace intervalo = 1 if q180_1<=20 & q180_1>10 & q180_1!=.
replace intervalo = 2 if q180_1<=30 & q180_1>20 & q180_1!=.
replace intervalo = 3 if q180_1<=40 & q180_1>30 & q180_1!=.
replace intervalo = 4 if q180_1<=50 & q180_1>40 & q180_1!=.
replace intervalo = 5 if q180_1<=60 & q180_1>50 & q180_1!=.
replace intervalo = 6 if q180_1<=70 & q180_1>60 & q180_1!=.
replace intervalo = 7 if q180_1<=80 & q180_1>70 & q180_1!=.
replace intervalo = 8 if q180_1<=90 & q180_1>80 & q180_1!=.
replace intervalo = 9 if q180_1<=100 & q180_1>90 & q180_1!=.

tab intervalo postulacion_familiar

// ----------------------------------------------------------------
// Q225 Si los postulantes quedan asignados en tu opción más preferida, ¿Con qué probabilidad crees que intentarías de cambiar a algún postulante el próximo año? 
// ----------------------------------------------------------------

destring q225_1, replace ignore(NA)

gen intervalo_2 = 0 if q225_1<=10 & q225_1!=.
replace intervalo_2 = 1 if q225_1<=20 & q225_1>10 & q225_1!=.
replace intervalo_2 = 2 if q225_1<=30 & q225_1>20 & q225_1!=.
replace intervalo_2 = 3 if q225_1<=40 & q225_1>30 & q225_1!=.
replace intervalo_2 = 4 if q225_1<=50 & q225_1>40 & q225_1!=.
replace intervalo_2 = 5 if q225_1<=60 & q225_1>50 & q225_1!=.
replace intervalo_2 = 6 if q225_1<=70 & q225_1>60 & q225_1!=.
replace intervalo_2 = 7 if q225_1<=80 & q225_1>70 & q225_1!=.
replace intervalo_2 = 8 if q225_1<=90 & q225_1>80 & q225_1!=.
replace intervalo_2 = 9 if q225_1<=100 & q225_1>90 & q225_1!=.

tab intervalo_2 postulacion_familiar

// ----------------------------------------------------------------
// Q227 Si los postulantes no quedan asignados en el mismo establecimiento, ¿Con qué probabilidad crees que intentarías de cambiar a algún postulante el próximo año?
// ----------------------------------------------------------------

destring q227_1, replace ignore(NA)

gen intervalo_3 = 0 if q227_1<=10 & q227_1!=.
replace intervalo_3 = 1 if q227_1<=20 & q227_1>10 & q227_1!=.
replace intervalo_3 = 2 if q227_1<=30 & q227_1>20 & q227_1!=.
replace intervalo_3 = 3 if q227_1<=40 & q227_1>30 & q227_1!=.
replace intervalo_3 = 4 if q227_1<=50 & q227_1>40 & q227_1!=.
replace intervalo_3 = 5 if q227_1<=60 & q227_1>50 & q227_1!=.
replace intervalo_3 = 6 if q227_1<=70 & q227_1>60 & q227_1!=.
replace intervalo_3 = 7 if q227_1<=80 & q227_1>70 & q227_1!=.
replace intervalo_3 = 8 if q227_1<=90 & q227_1>80 & q227_1!=.
replace intervalo_3 = 9 if q227_1<=100 & q227_1>90 & q227_1!=.

tab intervalo_3 postulacion_familiar

// ----------------------------------------------------------------
// Q228 Si los postulantes no quedan asignados a tu opción más preferida y no quedan juntos, ¿Con qué probabilidad crees que intentarías de cambiar a algún postulante el próximo año?
// ----------------------------------------------------------------

destring q228_1, replace ignore(NA)

gen intervalo_4 = 0 if q228_1<=10 & q228_1!=.
replace intervalo_4 = 1 if q228_1<=20 & q228_1>10 & q228_1!=.
replace intervalo_4 = 2 if q228_1<=30 & q228_1>20 & q228_1!=.
replace intervalo_4 = 3 if q228_1<=40 & q228_1>30 & q228_1!=.
replace intervalo_4 = 4 if q228_1<=50 & q228_1>40 & q228_1!=.
replace intervalo_4 = 5 if q228_1<=60 & q228_1>50 & q228_1!=.
replace intervalo_4 = 6 if q228_1<=70 & q228_1>60 & q228_1!=.
replace intervalo_4 = 7 if q228_1<=80 & q228_1>70 & q228_1!=.
replace intervalo_4 = 8 if q228_1<=90 & q228_1>80 & q228_1!=.
replace intervalo_4 = 9 if q228_1<=100 & q228_1>90 & q228_1!=.

tab intervalo_4 postulacion_familiar

// ----------------------------------------------------------------
// Q181 Imagina el caso hipotético en que tu postulante menor queda asignado/a a la escuela de tu primera preferencia pero tu postulante mayor no queda asignado/a ahí.
// Imagina también que aceptas que esta asignación y matriculas a tus hijo/as en estas escuelas distintas. 
// ¿Con qué probabilidad crees que, si postulas a tu postulante mayor el siguiente año a la misma escuela que tu hijo/a menor, tu hijo/a mayor quedará asignado a la misma escuela que tu postulante menor?
// ----------------------------------------------------------------

destring q181_1, replace ignore(NA)

gen intervalo_5 = 0 if q181_1<=10 & q181_1!=.
replace intervalo_5 = 1 if q181_1<=20 & q181_1>10 & q181_1!=.
replace intervalo_5 = 2 if q181_1<=30 & q181_1>20 & q181_1!=.
replace intervalo_5 = 3 if q181_1<=40 & q181_1>30 & q181_1!=.
replace intervalo_5 = 4 if q181_1<=50 & q181_1>40 & q181_1!=.
replace intervalo_5 = 5 if q181_1<=60 & q181_1>50 & q181_1!=.
replace intervalo_5 = 6 if q181_1<=70 & q181_1>60 & q181_1!=.
replace intervalo_5 = 7 if q181_1<=80 & q181_1>70 & q181_1!=.
replace intervalo_5 = 8 if q181_1<=90 & q181_1>80 & q181_1!=.
replace intervalo_5 = 9 if q181_1<=100 & q181_1>90 & q181_1!=.

tab intervalo_5
// ----------------------------------------------------------------
// Q207 Si ambos postulantes quedaran en la misma escuela, ¿Cuál es el establecimiento en que más prefieres que queden asignados?
// ----------------------------------------------------------------

merge m:1 id_apoderado using "$pathData/inputs/survey/2022/MuestraEmails_SIBLINGS.dta"
drop if _merge == 2

tab q207 cant_common_rbd if q207!="NA" // mismo numero de obs si impongo _merge == 3

destring q207, replace ignore(NA)

foreach x in 1 2 3 4 5 {
gen cs_`x'_preferencia_menor = 99
replace cs_`x'_preferencia_menor = 1 if common_school_`x' == school_name1_1 
replace cs_`x'_preferencia_menor = 2 if common_school_`x' == school_name2_1
}

foreach x in 1 2 3 4 5 {
gen cs_`x'_preferencia_mayor = 99
replace cs_`x'_preferencia_mayor =1 if common_school_`x' == school_name1_2
replace cs_`x'_preferencia_mayor = 2 if common_school_`x' == school_name2_2
}

foreach x in 1 2 3 4 5 {
tab cs_`x'_preferencia_menor cs_`x'_preferencia_mayor if q207 == `x' & _merge == 3 & postulacion_familiar == 1
}
foreach x in 1 2 3 4 5 {
tab cs_`x'_preferencia_menor cs_`x'_preferencia_mayor if q207 == `x' & _merge == 3 & postulacion_familiar == 0
}
// ----------------------------------------------------------------
// Q216 Si ambos postulantes quedaran en la misma escuela, ¿Cuál es el establecimiento en que menos prefieres que queden asignados?
// ----------------------------------------------------------------

tab q216 cant_common_rbd if q216!="NA" // mismo numero de obs si impongo _merge == 3

destring q216, replace ignore(NA)

foreach x in 1 2 3 4 5 {
tab cs_`x'_preferencia_menor cs_`x'_preferencia_mayor if q216 == `x' & _merge == 3 & postulacion_familiar == 1
}

foreach x in 1 2 3 4 5 {
tab cs_`x'_preferencia_menor cs_`x'_preferencia_mayor if q216 == `x' & _merge == 3 & postulacion_familiar == 0
}

// ----------------------------------------------------------------
// Q212 Si los postulantes quedaran en escuelas distintas, ¿cuál es la asignación que más prefieres?
// ----------------------------------------------------------------

tab q212 cant_common_rbd if q212!="NA" 

destring q212, replace ignore(NA)

tab cs_1_preferencia_menor cs_2_preferencia_mayor if q212 == 1 & _merge == 3 & postulacion_familiar == 1
tab cs_1_preferencia_menor cs_3_preferencia_mayor if q212 == 2 & _merge == 3 & postulacion_familiar == 1
tab cs_2_preferencia_menor cs_1_preferencia_mayor if q212 == 3 & _merge == 3 & postulacion_familiar == 1
tab cs_2_preferencia_menor cs_3_preferencia_mayor if q212 == 4 & _merge == 3 & postulacion_familiar == 1
tab cs_3_preferencia_menor cs_1_preferencia_mayor if q212 == 5 & _merge == 3 & postulacion_familiar == 1
tab cs_3_preferencia_menor cs_2_preferencia_mayor if q212 == 6 & _merge == 3 & postulacion_familiar == 1

tab cs_1_preferencia_menor cs_2_preferencia_mayor if q212 == 1 & _merge == 3 & postulacion_familiar == 0
tab cs_1_preferencia_menor cs_3_preferencia_mayor if q212 == 2 & _merge == 3 & postulacion_familiar == 0
tab cs_2_preferencia_menor cs_1_preferencia_mayor if q212 == 3 & _merge == 3 & postulacion_familiar == 0
tab cs_2_preferencia_menor cs_3_preferencia_mayor if q212 == 4 & _merge == 3 & postulacion_familiar == 0
tab cs_3_preferencia_menor cs_1_preferencia_mayor if q212 == 5 & _merge == 3 & postulacion_familiar == 0
tab cs_3_preferencia_menor cs_2_preferencia_mayor if q212 == 6 & _merge == 3 & postulacion_familiar == 0


// ----------------------------------------------------------------
// Q184 Por favor, explica con tus propias palabras qué es lo que crees que pasa cuando marcas esta opción (postulación familiar)
// ----------------------------------------------------------------

gen categorias = .  
br q184 categorias if q184!=""       // Hacer el reemplazo a mano
// categorias == 1 : cambio en el ranking de preferencias
// categorias == 2 : preferencia a que hijos queden juntos
// categorias == 3 : prioridad hermano
// categorias == 4 : postular a más de un niño
// categorias == 5 : asegura igual matrícula
// categorias == 6 : todos o ninguno (si sólo uno de los hermanos es admitido pero no hay cupos para el otro, se desecha la asignación del primero y se deja a ambos hermanos sin matrícula)
// categorias == 7 : otro

tab categorias postulacion_familiar 

